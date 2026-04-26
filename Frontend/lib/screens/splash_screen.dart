import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_font.dart';
import 'chat_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _gold   = Color(0xFFC4A882);
  static const _dark   = Color(0xFF1A1108);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ChatScreen(),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: Stack(
        children: [
          // خلفية بنمط دقيق
          Positioned.fill(
            child: CustomPaint(painter: _PatternPainter()),
          ),

          // المحتوى الرئيسي
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // اللوقو
                Image.asset('assets/logo.png', height: 140, fit: BoxFit.contain)
                    .animate()
                    .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                    .scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1),
                           duration: 900.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 16),

                // الخط الذهبي
                Container(width: 0, height: 1, color: _gold)
                    .animate()
                    .custom(
                      duration: 700.ms,
                      delay: 800.ms,
                      curve: Curves.easeOut,
                      builder: (context, value, child) => Container(
                        width: value * 100,
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _gold.withValues(alpha: 0),
                              _gold,
                              _gold.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),

                const SizedBox(height: 14),

                // اسم التطبيق
                Text(
                  'مساعد الحديث النبوي',
                  style: appFont(
                    color: _gold.withValues(alpha: 0.8),
                    fontSize: 15,
                    letterSpacing: 1.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 900.ms, duration: 700.ms)
                    .slideY(begin: 0.3, end: 0, delay: 900.ms, duration: 700.ms,
                            curve: Curves.easeOut),
              ],
            ),
          ),

          // مؤشر التحميل في الأسفل
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _gold.withValues(alpha: 0.6),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1400.ms, duration: 500.ms),

                const SizedBox(height: 16),

                Text(
                  'هداي',
                  style: appFont(
                    color: _gold.withValues(alpha: 0.3),
                    fontSize: 13,
                    letterSpacing: 4,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1600.ms, duration: 500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC4A882).withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 60.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), spacing / 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
