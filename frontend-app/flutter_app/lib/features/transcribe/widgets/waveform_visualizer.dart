import 'dart:math';

import 'package:flutter/material.dart';

class WaveformVisualizer extends StatelessWidget {
  const WaveformVisualizer({
    super.key,
    required this.isActive,
  });

  final bool isActive;

  List<double> _sampleLevels() {
    final Random rng = Random();
    return List<double>.generate(18, (_) => rng.nextDouble());
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<double> levels = _sampleLevels();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isActive ? 1 : 0.25,
      child: SizedBox(
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: levels.map((level) {
            final double barHeight = 12 + (level * 64);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              width: 6,
              height: barHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: colors.primary.withOpacity(0.75),
                gradient: LinearGradient(
                  colors: [colors.primary, colors.primaryContainer],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
