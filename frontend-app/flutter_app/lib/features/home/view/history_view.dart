import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../viewmodel/history_viewmodel.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryViewModel>(
      builder: (context, vm, _) {
        if (vm.state == HistoryState.loading && vm.items.isEmpty) {
          return _buildLoadingState(context);
        }
        if (vm.state == HistoryState.unauthenticated) {
          return _buildEmptyState(
            context,
            icon: Icons.lock_outline_rounded,
            title: 'Sign in required',
            message: 'Sign in to see your transcripts.',
          );
        }
        if (vm.state == HistoryState.error && vm.items.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.error_outline_rounded,
            title: 'Oops!',
            message: vm.error ?? 'Failed to load history',
            isError: true,
          );
        }
        if (vm.items.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.mic_none_rounded,
            title: 'No transcripts yet',
            message: 'Your transcripts will appear here.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => vm.refresh(),
          child: Column(
            children: [
              // Cache indicator banner
              if (vm.isFromCache)
                _CacheBanner(
                  onRefresh: () => vm.refresh(),
                  isRefreshing: vm.state == HistoryState.refreshing,
                ),
              // Refreshing indicator
              if (vm.state == HistoryState.refreshing)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: vm.items.length,
                  itemBuilder: (context, index) {
                    final item = vm.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TranscriptCard(
                        text: item.text,
                        createdAt: item.createdAt,
                        confidence: item.confidence,
                        durationSeconds: item.durationSeconds,
                      )
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: index * 50),
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
      },
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
            ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
          ],
        ),
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({
    required this.text,
    required this.createdAt,
    this.confidence,
    this.durationSeconds,
  });

  final String text;
  final DateTime createdAt;
  final double? confidence;
  final double? durationSeconds;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final timestamp = DateFormat.yMMMd().add_jm().format(createdAt.toLocal());

    return GlassCard(
      borderRadius: 18,
      blur: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      timestamp,
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
              if (confidence != null)
                _MetadataChip(
                  icon: Icons.verified_rounded,
                  label: '${(confidence! * 100).toStringAsFixed(0)}%',
                  color: AppColors.success,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          if (durationSeconds != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _MetadataChip(
                  icon: Icons.timer_outlined,
                  label: '${durationSeconds!.toStringAsFixed(1)}s',
                  color: colors.primary,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.copy_rounded, size: 20, color: colors.onSurface.withOpacity(0.5)),
                  onPressed: () {
                    // TODO: copy to clipboard
                  },
                  tooltip: 'Copy',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
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

class _CacheBanner extends StatelessWidget {
  const _CacheBanner({
    required this.onRefresh,
    required this.isRefreshing,
  });

  final VoidCallback onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: colors.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.offline_bolt_rounded,
            size: 16,
            color: colors.primary.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing cached data',
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          if (!isRefreshing)
            GestureDetector(
              onTap: onRefresh,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 14,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Refresh',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
