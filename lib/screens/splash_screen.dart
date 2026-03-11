import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _iconsController;
  late final AnimationController _fadeOutController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _fadeOut;

  // Floating fitness icons data
  final List<_FloatingIcon> _floatingIcons = [];
  final _random = Random();

  static const _fitnessIcons = [
    Icons.fitness_center,
    Icons.sports_gymnastics,
    Icons.directions_run,
    Icons.sports_martial_arts,
    Icons.self_improvement,
    Icons.monitor_heart,
    Icons.timer,
    Icons.bolt,
    Icons.local_fire_department,
    Icons.favorite,
    Icons.emoji_events,
    Icons.trending_up,
  ];

  @override
  void initState() {
    super.initState();

    // Generate floating icons
    for (int i = 0; i < 14; i++) {
      _floatingIcons.add(_FloatingIcon(
        icon: _fitnessIcons[_random.nextInt(_fitnessIcons.length)],
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 18 + _random.nextDouble() * 22,
        speed: 0.3 + _random.nextDouble() * 0.7,
        delay: _random.nextDouble() * 0.5,
        opacity: 0.06 + _random.nextDouble() * 0.12,
      ));
    }

    // Logo animation: scale in + fade in (0 → 600ms)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    // Icons floating animation (continuous)
    _iconsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // Fade out animation
    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeInQuad),
    );

    // Start sequence
    _logoController.forward();

    // After 2s total, fade out and navigate
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _fadeOutController.forward().then((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => widget.nextScreen,
            transitionDuration: Duration.zero,
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _iconsController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeOut,
      builder: (context, child) => Opacity(
        opacity: _fadeOut.value,
        child: child,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: Stack(
          children: [
            // Gradient glow circles in the background
            Positioned(
              top: -120,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE94560).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6A4DFF).withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),



            // Floating icon widgets
            ..._floatingIcons.map((fi) {
              return AnimatedBuilder(
                animation: _iconsController,
                builder: (context, _) {
                  final size = MediaQuery.of(context).size;
                  final progress = _iconsController.value;
                  final phase = (progress + fi.delay) % 1.0;

                  // Gentle floating movement
                  final yOffset = sin(phase * 2 * pi * fi.speed) * 20;
                  final xOffset = cos(phase * 2 * pi * fi.speed * 0.7) * 10;

                  // Pulse opacity
                  final pulseOpacity =
                      fi.opacity * (0.7 + 0.3 * sin(phase * 2 * pi));

                  return Positioned(
                    left: fi.x * size.width + xOffset,
                    top: fi.y * size.height + yOffset,
                    child: Opacity(
                      opacity: pulseOpacity.clamp(0.0, 1.0),
                      child: Icon(
                        fi.icon,
                        size: fi.size,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              );
            }),

            // Central logo + text
            Center(
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo icon with glow
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFFE94560),
                                  Color(0xFFB8284A),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE94560)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/icon/app_icon.png',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.fitness_center,
                                  size: 56,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // App name
                      Opacity(
                        opacity: _textOpacity.value,
                        child: const Text(
                          'GymLoom',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: _textOpacity.value * 0.7,
                        child: const Text(
                          'Twój trening. Twój progres.',
                          style: TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingIcon {
  final IconData icon;
  final double x, y, size, speed, delay, opacity;

  _FloatingIcon({
    required this.icon,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.delay,
    required this.opacity,
  });
}
