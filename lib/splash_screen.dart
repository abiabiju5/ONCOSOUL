import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'login.dart';

class SplashScreen extends StatefulWidget {
   const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  int dotCount = 0;

  final Color deepBlue = const Color(0xFF0D47A1);

  @override
  void initState() {
    super.initState();

    // Entry animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    // Heart pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Sync dots with pulse
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          dotCount = (dotCount + 1) % 4;
        });
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseController.forward();
      }
    });

    _entryController.forward();
    _pulseController.forward();

    // Splash duration
   Timer(const Duration(seconds: 5), () {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => LoginPage()),
  );
});


  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String get dots => '.' * dotCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🖼️ Static background image (NO ZOOM)
          Image.asset(
            'assets/images/healthcare_bg.jpg',
            fit: BoxFit.cover,
          ),

          // Soft blue blur overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: deepBlue.withValues(alpha:0.12),
            ),
          ),

          // Foreground content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulsing hand-holding-love icon
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha:0.9),
                        ),
                        child: Icon(
                          Icons.volunteer_activism,
                          size: 70,
                          color: deepBlue,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'OncoSoul',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: deepBlue,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Supporting you through every step of care',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: deepBlue,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      'Loading$dots',
                      style: TextStyle(
                        fontSize: 16,
                        color: deepBlue,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}