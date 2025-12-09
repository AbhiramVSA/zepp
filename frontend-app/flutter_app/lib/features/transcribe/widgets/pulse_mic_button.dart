import 'package:flutter/material.dart';

class PulseMicButton extends StatefulWidget {
  const PulseMicButton({
    super.key,
    required this.isRecording,
    required this.onTap,
  });

  final bool isRecording;
  final VoidCallback onTap;

  @override
  State<PulseMicButton> createState() => _PulseMicButtonState();
}

class _PulseMicButtonState extends State<PulseMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isRecording) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulseMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isRecording && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: _scale,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: widget.isRecording
                  ? [colors.primary, colors.primaryContainer]
                  : [colors.secondaryContainer, colors.surfaceContainerHighest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: widget.isRecording
                ? [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            widget.isRecording ? Icons.stop : Icons.mic,
            size: 40,
            color: widget.isRecording ? colors.onPrimaryContainer : colors.primary,
          ),
        ),
      ),
    );
  }
}
