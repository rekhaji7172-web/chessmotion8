import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _rippleCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _ripple;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
    _textCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
    _rippleCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));

    _logoScale   = Tween(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.4)));
    _textOpacity = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textSlide   = Tween(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _ripple      = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut));

    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();
    _rippleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => const HomeScreen(),
          transitionsBuilder: (_, a1, a2, child) => FadeTransition(
            opacity: a1, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
        child: Stack(
          children: [
            // Chess board grid background
            Positioned.fill(child: _ChessGridBackground()),
            // Ripple
            Center(child: AnimatedBuilder(
              animation: _ripple,
              builder: (_, __) => Container(
                width: 240 * _ripple.value,
                height: 240 * _ripple.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.3 * (1 - _ripple.value)),
                    width: 2,
                  ),
                ),
              ),
            )),
            // Logo + text
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: _LogoWidget(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(
                        children: [
                          const Text(
                            'ChessMotion',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Professional Chess Video Editor',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom bar
            Positioned(
              bottom: 40,
              left: 0, right: 0,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Column(children: [
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      color: AppTheme.accent,
                      backgroundColor: AppTheme.bgSurface,
                      minHeight: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('v1.0.0', style: TextStyle(
                    color: AppTheme.textHint, fontSize: 12)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.4),
            blurRadius: 32,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.grid_4x4, color: AppTheme.bgHover, size: 80),
          Icon(Icons.extension, color: AppTheme.accent, size: 52),
          Positioned(
            right: 14, bottom: 14,
            child: Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: AppTheme.accentRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChessGridBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A2744).withOpacity(0.3)
      ..strokeWidth = 0.5;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
