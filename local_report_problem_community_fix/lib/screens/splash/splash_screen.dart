import 'dart:async';
import 'package:flutter/material.dart';
import '../../main.dart'; // Corrected import to find AuthWrapper

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Navigate after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background subtle glows
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6).withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withOpacity(0.05),
                ),
              ),
            ),
            
            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with scale pulse
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 0.95 + (0.05 * _animation.value),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.location_city_rounded,
                          size: 80,
                          color: Color(0xFF60A5FA),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                // Text with shimmering effect (simulated)
                const Text(
                  "LPRCF",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "CIVIC REPORTER",
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
            
            // Bottom Loading Indicator (Stable)
            Positioned(
              bottom: 60,
              child: SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    minHeight: 3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
