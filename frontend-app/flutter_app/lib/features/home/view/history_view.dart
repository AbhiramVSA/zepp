import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../../core/cache/cached_transcript.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../viewmodel/history_viewmodel.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load data on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryViewModel>().load();
    });
    // Setup pagination listener
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when near bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<HistoryViewModel>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryViewModel>(
      builder: (context, vm, _) {
        return _buildContent(context, vm);
      },
    );
  }

  Widget _buildContent(BuildContext context, HistoryViewModel vm) {
    // Loading state (only show if no cached data)
    if (vm.state == HistoryState.loading && vm.items.isEmpty) {
      return _buildLoadingState(context);
    }

    // Unauthenticated state
    if (vm.state == HistoryState.unauthenticated) {
      return _buildEmptyState(
        context,
        icon: Icons.lock_outline_rounded,
        title: 'Sign in required',
        message: 'Sign in to see your transcripts.',
      );
    }

    // Error state (only show if no cached data)
    if (vm.state == HistoryState.error && vm.items.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.error_outline_rounded,
        title: 'Oops!',
        message: vm.error ?? 'Failed to load history',
        isError: true,
      );
    }

    // Empty state
    if (vm.items.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.mic_none_rounded,
        title: 'No transcripts yet',
        message: 'Your transcripts will appear here.',
      );
    }

    // Main content with data
    return RefreshIndicator(
      onRefresh: () => vm.refresh(),
      child: Column(
        children: [
          // Status bar section
          _StatusBar(
            isFromCache: vm.isFromCache,
            isRefreshing: vm.state == HistoryState.refreshing || vm.isBackgroundRefreshing,
            pendingSyncCount: vm.pendingSyncCount,
            hasFailedItems: vm.hasFailedItems,
            onRefresh: () => vm.refresh(),
            onSyncPending: () => vm.syncPending(),
          ),
          
          // Main list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: vm.items.length + (vm.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Loading indicator for pagination
                if (index >= vm.items.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final item = vm.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TranscriptCard(
                    transcript: item,
                    onRetry: item.isSynced ? null : () => vm.retryFailedTranscript(item.id),
                    onDelete: item.isSynced ? null : () => vm.deleteFailedTranscript(item.id),
                  )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: (index * 50).clamp(0, 500)),
                        duration: 400.ms,
                      )
                      .slideY(begin: 0.1, end: 0),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ).animate().scale(duration: 300.ms),
          const SizedBox(height: 20),
          Text(
            'Loading your transcripts...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    bool isError = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final vm = context.read<HistoryViewModel>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: isError
                    ? LinearGradient(
                        colors: [AppColors.error, AppColors.error.withOpacity(0.7)],
                      )
                    : AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: Colors.white),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            GradientText(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
            GradientButton(
              onPressed: () => vm.load(refresh: true),
              height: 48,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Refresh'),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                ),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.isFromCache,
    required this.isRefreshing,
    required this.pendingSyncCount,
    required this.hasFailedItems,
    required this.onRefresh,
    required this.onSyncPending,
  });

  final bool isFromCache;
  final bool isRefreshing;
  final int pendingSyncCount;
  final bool hasFailedItems;
  final VoidCallback onRefresh;
  final VoidCallback onSyncPending;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final showBar = isFromCache || isRefreshing || pendingSyncCount > 0 || hasFailedItems;

    if (!showBar) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress indicator for refreshing
        if (isRefreshing)
          LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: colors.surfaceContainerHighest,
          ),
        
        // Status content
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _getBackgroundColor(context),
            border: Border(
              bottom: BorderSide(
                color: colors.outline.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              // Status icon and text
              Icon(
                _getStatusIcon(),
                size: 16,
                color: _getStatusColor(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              
              // Action button
              if (!isRefreshing) ...[
                if (pendingSyncCount > 0)
                  _ActionButton(
                    icon: Icons.sync_rounded,
                    label: 'Sync ($pendingSyncCount)',
                    onTap: onSyncPending,
                    color: colors.primary,
                  )
                else if (isFromCache)
                  _ActionButton(
                    icon: Icons.refresh_rounded,
                    label: 'Refresh',
                    onTap: onRefresh,
                    color: colors.primary,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon() {
    if (hasFailedItems) return Icons.error_outline_rounded;
    if (pendingSyncCount > 0) return Icons.sync_problem_rounded;
    if (isRefreshing) return Icons.sync_rounded;
    return Icons.offline_bolt_rounded;
  }

  String _getStatusText() {
    if (hasFailedItems) return 'Some items failed to sync';
    if (pendingSyncCount > 0) return '$pendingSyncCount item${pendingSyncCount > 1 ? 's' : ''} pending sync';
    if (isRefreshing) return 'Refreshing...';
    return 'Showing cached data';
  }

  Color _getBackgroundColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (hasFailedItems) return AppColors.error.withOpacity(0.1);
    if (pendingSyncCount > 0) return colors.tertiary.withOpacity(0.1);
    return colors.surfaceContainerHighest.withOpacity(0.5);
  }

  Color _getStatusColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (hasFailedItems) return AppColors.error;
    if (pendingSyncCount > 0) return colors.tertiary;
    return colors.primary.withOpacity(0.7);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({
    required this.transcript,
    this.onRetry,
    this.onDelete,
  });

  final CachedTranscript transcript;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final timestamp = DateFormat.yMMMd().add_jm().format(transcript.createdAt.toLocal());

    return GlassCard(
      borderRadius: 18,
      blur: 10,
      // Reduce opacity for optimistic/unsynced items
      opacity: transcript.isSynced ? 0.15 : 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Timestamp badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: transcript.isSynced
                      ? AppColors.primaryGradient
                      : LinearGradient(
                          colors: [
                            colors.tertiary,
                            colors.tertiary.withOpacity(0.7),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      transcript.isSynced
                          ? Icons.access_time_rounded
                          : (transcript.isOptimistic
                              ? Icons.cloud_upload_rounded
                              : Icons.cloud_off_rounded),
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      transcript.isSynced
                          ? timestamp
                          : (transcript.isOptimistic ? 'Syncing...' : 'Failed'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Confidence badge
              if (transcript.confidence != null && transcript.isSynced)
                _MetadataChip(
                  icon: Icons.verified_rounded,
                  label: '${(transcript.confidence! * 100).toStringAsFixed(0)}%',
                  color: AppColors.success,
                ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Transcript text
          Text(
            transcript.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  // Italic for unsynced items
                  fontStyle: transcript.isSynced ? null : FontStyle.italic,
                ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Footer row
          const SizedBox(height: 12),
          Row(
            children: [
              // Duration chip
              if (transcript.durationSeconds != null)
                _MetadataChip(
                  icon: Icons.timer_outlined,
                  label: '${transcript.durationSeconds!.toStringAsFixed(1)}s',
                  color: colors.primary,
                ),
              const Spacer(),
              
              // Actions for failed items
              if (!transcript.isSynced && !transcript.isOptimistic) ...[
                if (onRetry != null)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: onRetry,
                    tooltip: 'Retry sync',
                    visualDensity: VisualDensity.compact,
                    color: colors.primary,
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    onPressed: () => _confirmDelete(context),
                    tooltip: 'Delete',
                    visualDensity: VisualDensity.compact,
                    color: AppColors.error,
                  ),
              ] else if (transcript.isSynced) ...[
                // Copy button for synced items
                IconButton(
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 20,
                    color: colors.onSurface.withOpacity(0.5),
                  ),
                  onPressed: () => _copyToClipboard(context),
                  tooltip: 'Copy',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: transcript.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transcript?'),
        content: const Text(
          'This transcript failed to sync and will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
