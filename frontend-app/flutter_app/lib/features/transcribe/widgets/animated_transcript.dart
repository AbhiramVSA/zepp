import 'package:flutter/material.dart';

class AnimatedTranscript extends StatelessWidget {
  const AnimatedTranscript({
    super.key,
    required this.text,
    required this.visible,
  });

  final String text;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: visible ? 1 : 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.4),
        ),
      ),
    );
  }
}
