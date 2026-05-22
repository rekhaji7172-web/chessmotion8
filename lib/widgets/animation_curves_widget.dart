import 'dart:math';
import 'package:flutter/material.dart';
import '../models/keyframe_model.dart';
import '../theme/app_theme.dart';

class EasingCurveWidget extends StatelessWidget {
  final EasingType easing;
  final Color color;
  final double size;

  const EasingCurveWidget({
    super.key,
    required this.easing,
    this.color = AppTheme.accent,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _CurvePainter(easing: easing, color: color),
  );
}

class _CurvePainter extends CustomPainter {
  final EasingType easing;
  final Color color;
  const _CurvePainter({required this.easing, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(6)),
      Paint()..color = AppTheme.bgSurface,
    );

    final gridPaint = Paint()
      ..color = AppTheme.border
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height), gridPaint);
    canvas.drawLine(Offset(0, size.height / 2),
        Offset(size.width, size.height / 2), gridPaint);

    final path = Path();
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pad = size.width * 0.1;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    for (int i = 0; i <= 50; i++) {
      final t = i / 50.0;
      final et = _applyEasing(t);
      final x = pad + t * w;
      final y = pad + (1 - et.clamp(0, 1)) * h;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    // Dots
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(pad, pad + h), 3, dotPaint);
    canvas.drawCircle(Offset(pad + w, pad), 3, dotPaint);
  }

  double _applyEasing(double t) {
    switch (easing) {
      case EasingType.linear: return t;
      case EasingType.easeIn: return t * t;
      case EasingType.easeOut: return t * (2 - t);
      case EasingType.easeInOut: return t < 0.5 ? 2*t*t : -1+(4-2*t)*t;
      case EasingType.bounce:
        if (t < 1/2.75) return 7.5625*t*t;
        if (t < 2/2.75) { final nt = t - 1.5/2.75; return 7.5625*nt*nt+0.75; }
        if (t < 2.5/2.75) { final nt = t - 2.25/2.75; return 7.5625*nt*nt+0.9375; }
        final nt = t - 2.625/2.75; return 7.5625*nt*nt+0.984375;
      case EasingType.elastic:
        if (t == 0 || t == 1) return t;
        return pow(2, -10*t).toDouble() * sin((t-0.1) * 5 * pi) + 1;
      case EasingType.cubic: return t*t*t;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ── Full Easing Panel ──────────────────────────────────────────────────────
class EasingPanel extends StatelessWidget {
  final EasingType selected;
  final Function(EasingType) onSelect;

  const EasingPanel({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  static const _labels = {
    EasingType.linear: 'Linear',
    EasingType.easeIn: 'Ease In',
    EasingType.easeOut: 'Ease Out',
    EasingType.easeInOut: 'Ease In/Out',
    EasingType.bounce: 'Bounce',
    EasingType.elastic: 'Elastic',
    EasingType.cubic: 'Cubic',
  };

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: EasingType.values.map((e) {
        final isSelected = e == selected;
        return GestureDetector(
          onTap: () => onSelect(e),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppTheme.accent : AppTheme.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EasingCurveWidget(
                  easing: e,
                  color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                  size: 40,
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[e] ?? '',
                  style: TextStyle(
                    color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
