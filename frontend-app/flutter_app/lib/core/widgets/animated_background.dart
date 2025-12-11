import 'dart:math' as math;
import 'package:flutter/material.dart';

class _Particle {
  double x;
  double y;
  final double size;
  final double speedX;
  final double speedY;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.color,
  });
}

/// Animated background with floating orbs
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({
    super.key,
    required this.child,
    this.particleCount = 5,
    this.animate = true,
  });

  final Widget child;
  final int particleCount;
  final bool animate;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late List<_Particle> _particles;
  late AnimationController _controller;

  Color _getColor(int index) {
    const colors = [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
    ];
    return colors[index % colors.length].withOpacity(0.3);
  }

  void _updateParticles() {
    setState(() {
      for (var p in _particles) {
        p.x += p.speedX;
        p.y += p.speedY;
        
        // Wrap around edges
        if (p.x < -0.3) p.x = 1.3;
        if (p.x > 1.3) p.x = -0.3;
        if (p.y < -0.3) p.y = 1.3;
        if (p.y > 1.3) p.y = -0.3;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    
    final random = math.Random();
    _particles = List.generate(widget.particleCount, (i) {
      return _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 150 + random.nextDouble() * 200,
        speedX: (random.nextDouble() - 0.5) * 0.02,
        speedY: (random.nextDouble() - 0.5) * 0.02,
        color: _getColor(i),
      );
    });

    if (widget.animate) {
      _controller.repeat();
      _controller.addListener(_updateParticles);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F0F23), const Color(0xFF1A1A2E)]
                  : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Floating orbs
        ...List.generate(_particles.length, (i) {
          final p = _particles[i];
          return Positioned(
            left: p.x * MediaQuery.of(context).size.width - p.size / 2,
            top: p.y * MediaQuery.of(context).size.height - p.size / 2,
            child: Container(
              width: p.size,
              height: p.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    p.color,
                    p.color.withOpacity(0),
                  ],
                ),
              ),
            ),
          );
        }),
        // Content
        widget.child,
      ],
    );
  }
}

/// Pulse ring animation
class PulseRings extends StatefulWidget {
  const PulseRings({
    super.key,
    required this.isActive,
    this.size = 200,
    this.ringCount = 3,
    this.color,
  });

  final bool isActive;
  final double size;
  final int ringCount;
  final Color? color;

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scales;
  late List<Animation<double>> _opacities;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.ringCount, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      );
    });

    _scales = _controllers.map((c) {
      return Tween<double>(begin: 0.5, end: 1.5).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOut),
      );
    }).toList();

    _opacities = _controllers.map((c) {
      return Tween<double>(begin: 0.6, end: 0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOut),
      );
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    if (!widget.isActive) return;
    
    for (int i = 0; i < widget.ringCount; i++) {
      Future.delayed(Duration(milliseconds: i * 600), () {
        if (mounted && widget.isActive) {
          _controllers[i].repeat();
        }
      });
    }
  }

  @override
  void didUpdateWidget(PulseRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startAnimations();
      } else {
        for (var c in _controllers) {
          c.stop();
          c.reset();
        }
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(widget.ringCount, (i) {
          return AnimatedBuilder(
            animation: _controllers[i],
            builder: (context, _) {
              return Transform.scale(
                scale: _scales[i].value,
                child: Container(
                  width: widget.size * 0.6,
                  height: widget.size * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(_opacities[i].value),
                      width: 3,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// Sound wave bars animation
class SoundWaveBars extends StatefulWidget {
  const SoundWaveBars({
    super.key,
    required this.isActive,
    this.barCount = 5,
    this.height = 60,
    this.color,
  });

  final bool isActive;
  final int barCount;
  final double height;
  final Color? color;

  @override
  State<SoundWaveBars> createState() => _SoundWaveBarsState();
}

class _SoundWaveBarsState extends State<SoundWaveBars>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _heights;

  @override
  void initState() {
    super.initState();
    final random = math.Random(42);
    
    _controllers = List.generate(widget.barCount, (i) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + random.nextInt(400)),
      );
      return controller;
    });

    _heights = List.generate(widget.barCount, (i) {
      final minHeight = 0.2 + math.Random(i).nextDouble() * 0.2;
      return Tween<double>(begin: minHeight, end: 1.0).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOut),
      );
    });

    _startAnimations();
  }

  void _startAnimations() {
    if (!widget.isActive) return;
    
    for (int i = 0; i < widget.barCount; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted && widget.isActive) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void didUpdateWidget(SoundWaveBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startAnimations();
      } else {
        for (var c in _controllers) {
          c.stop();
          c.animateTo(0.3, duration: const Duration(milliseconds: 300));
        }
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedBuilder(
              animation: _controllers[i],
              builder: (context, _) {
                return Container(
                  width: 6,
                  height: widget.height * _heights[i].value,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.5)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
