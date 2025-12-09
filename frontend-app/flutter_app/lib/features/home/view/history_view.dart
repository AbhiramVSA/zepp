import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme_notifier.dart';
import '../../authentication/viewmodel/auth_viewmodel.dart';
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
    final colors = Theme.of(context).colorScheme;
    final theme = context.read<ThemeNotifier>();
    final mode = context.watch<ThemeNotifier>().mode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: theme.toggle,
          ),
          Consumer<AuthViewModel>(
            builder: (context, auth, _) => IconButton(
              tooltip: 'Log out',
              icon: const Icon(Icons.logout),
              onPressed: auth.isAuthenticated ? auth.logout : null,
            ),
          ),
        ],
      ),
      body: Consumer<HistoryViewModel>(
        builder: (context, vm, _) {
          if (vm.state == HistoryState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.state == HistoryState.unauthenticated) {
            return _CenteredMessage(
              icon: Icons.lock_outline,
              message: 'Sign in to see your transcripts.',
              colors: colors,
            );
          }
          if (vm.state == HistoryState.error) {
            return _CenteredMessage(
              icon: Icons.error_outline,
              message: vm.error ?? 'Failed to load history',
              colors: colors,
            );
          }
          if (vm.items.isEmpty) {
            return _CenteredMessage(
              icon: Icons.mic_none,
              message: 'No transcripts yet.',
              colors: colors,
            );
          }

          return RefreshIndicator(
            onRefresh: () => vm.load(refresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemBuilder: (context, index) {
                final item = vm.items[index];
                final timestamp = DateFormat.yMMMd().add_jm().format(item.createdAt.toLocal());
                final subtitle = [
                  if (item.confidence != null) 'Confidence ${(item.confidence! * 100).toStringAsFixed(1)}%',
                  if (item.durationSeconds != null) 'Duration ${item.durationSeconds!.toStringAsFixed(1)}s',
                ].join(' · ');

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        colors.surfaceVariant.withOpacity(0.7),
                        colors.surfaceVariant.withOpacity(0.45),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: colors.outline.withOpacity(0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timestamp,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.text,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.35),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        )
                      ],
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: vm.items.length,
            ),
          );
        },
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.message, required this.colors});

  final IconData icon;
  final String message;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
