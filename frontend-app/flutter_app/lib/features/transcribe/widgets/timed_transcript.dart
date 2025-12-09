import 'package:flutter/material.dart';

/// Displays transcript text with a typewriter-style reveal and a running timestamp.
class TimedTranscript extends StatefulWidget {
  const TimedTranscript({
    super.key,
    required this.text,
    required this.visible,
    this.step = const Duration(milliseconds: 18),
  });

  final String text;
  final bool visible;
  final Duration step;

  @override
  State<TimedTranscript> createState() => _TimedTranscriptState();
}

class _TimedTranscriptState extends State<TimedTranscript>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _restartAnimation();
  }

  @override
  void didUpdateWidget(TimedTranscript oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _restartAnimation();
    }
  }

  void _restartAnimation() {
    final int len = widget.text.length;
    final int totalMs = len > 0
        ? (widget.step.inMilliseconds * len).clamp(250, 2000)
        : 1;
    final Duration total = Duration(milliseconds: totalMs);
    _controller.stop();
    _controller.duration = total;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final int ms = d.inMilliseconds;
    final int seconds = ms ~/ 1000;
    final int minutes = seconds ~/ 60;
    final int remSeconds = seconds % 60;
    final int remMs = ms % 1000;
    return '${minutes.toString().padLeft(2, '0')}:${remSeconds.toString().padLeft(2, '0')}.${(remMs ~/ 10).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: widget.visible ? 1 : 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final int len = widget.text.length;
          if (len == 0) {
            return _Shell(colors: colors, child: const Text('Transcript will appear here.'));
          }
          final double progress = Curves.easeOutCubic.transform(_controller.value.clamp(0.0, 1.0));
          final int visibleCount = (len * progress).clamp(0, len).toInt();
          final String shown = widget.text.substring(0, visibleCount);
          final Duration elapsed = widget.step * visibleCount;

          return _Shell(
            colors: colors,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Text(
                    shown.isEmpty ? '...' : shown,
                    key: ValueKey<String>(shown),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.35),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.schedule, size: 14, color: colors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      _format(elapsed),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.colors, required this.child});

  final ColorScheme colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
