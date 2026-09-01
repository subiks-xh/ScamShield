import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Heraldic shield CustomPainter — the visual identity of ScamShield.
/// On Home: subtle outline behind mic button.
/// On Results: animates filling with verdict color when analysis completes.
class ShieldEmblем extends StatefulWidget {
  final String? verdict; // null = outline only
  final double size;
  final bool animate;
  final ShieldVariant variant;

  const ShieldEmblем({
    super.key,
    this.verdict,
    this.size = 120,
    this.animate = true,
    this.variant = ShieldVariant.home,
  });

  @override
  State<ShieldEmblем> createState() => _ShieldEmblemState();
}

enum ShieldVariant { home, result, history, empty }

class _ShieldEmblemState extends State<ShieldEmblем>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fillAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.verdict != null && widget.animate) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _controller.forward();
      });
    } else if (widget.verdict != null) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ShieldEmblем old) {
    super.didUpdateWidget(old);
    if (widget.verdict != null && old.verdict == null) {
      _controller.forward();
    } else if (widget.verdict == null) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get fillColor {
    if (widget.verdict == null) return Colors.transparent;
    return AppColors.verdictColor(widget.verdict!).withOpacity(0.35);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fillAnimation,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size * 1.2),
          painter: _ShieldPainter(
            fillProgress: _fillAnimation.value,
            fillColor: fillColor,
            strokeColor: AppColors.antiqueGold,
            verdict: widget.verdict,
            variant: widget.variant,
          ),
        );
      },
    );
  }
}

class _ShieldPainter extends CustomPainter {
  final double fillProgress;
  final Color fillColor;
  final Color strokeColor;
  final String? verdict;
  final ShieldVariant variant;

  _ShieldPainter({
    required this.fillProgress,
    required this.fillColor,
    required this.strokeColor,
    required this.verdict,
    required this.variant,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shield path (heraldic shape, pointed bottom)
    final shieldPath = Path()
      ..moveTo(w * 0.5, h * 0.067)
      ..cubicTo(w * 0.5, h * 0.067, w * 0.85, h * 0.117, w * 0.9, h * 0.15)
      ..lineTo(w * 0.9, h * 0.458)
      ..cubicTo(w * 0.9, h * 0.683, w * 0.7, h * 0.833, w * 0.5, h * 0.933)
      ..cubicTo(w * 0.3, h * 0.833, w * 0.1, h * 0.683, w * 0.1, h * 0.458)
      ..lineTo(w * 0.1, h * 0.15)
      ..cubicTo(w * 0.15, h * 0.117, w * 0.5, h * 0.067, w * 0.5, h * 0.067)
      ..close();

    // Clip to animate fill from bottom up
    if (fillProgress > 0) {
      final fillTop = h * (1 - fillProgress);
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, fillTop, w, h - fillTop));
      canvas.drawPath(shieldPath, Paint()..color = fillColor);
      canvas.restore();
    }

    // Outer shield outline
    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w / 40
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Inner decorative border
    final innerPath = _scaledPath(shieldPath, 0.8, w, h);
    canvas.drawPath(
      innerPath,
      Paint()
        ..color = strokeColor.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w / 80,
    );

    // Gold dot at top
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.067),
      w * 0.03,
      Paint()..color = strokeColor,
    );

    // Center symbol
    _drawCenterSymbol(canvas, size);
  }

  Path _scaledPath(Path original, double scale, double w, double h) {
    final matrix = Matrix4.identity()
      ..translate(w * (1 - scale) / 2, h * (1 - scale) / 2)
      ..scale(scale);
    return original.transform(matrix.storage);
  }

  void _drawCenterSymbol(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.48;
    final paint = Paint()
      ..color = verdict != null && fillProgress > 0.4
          ? Colors.white.withOpacity(0.9)
          : strokeColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width / 48
      ..strokeCap = StrokeCap.round;

    switch (variant) {
      case ShieldVariant.home:
        // Microphone icon
        final r = size.width * 0.1;
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - r * 0.3), width: r * 1.2, height: r * 2), paint);
        canvas.drawLine(Offset(cx, cy + r * 0.7), Offset(cx, cy + r * 1.3), paint);
        canvas.drawLine(Offset(cx - r * 0.8, cy + r * 1.3), Offset(cx + r * 0.8, cy + r * 1.3), paint);
        // Arc
        final arcPath = Path()
          ..moveTo(cx - r, cy - r * 0.3)
          ..arcToPoint(Offset(cx + r, cy - r * 0.3), radius: Radius.circular(r * 1.4), clockwise: false);
        canvas.drawPath(arcPath, paint);
        break;

      case ShieldVariant.result:
        if (verdict == 'high_risk' && fillProgress > 0.4) {
          // Exclamation mark
          canvas.drawLine(Offset(cx, cy - size.height * 0.12), Offset(cx, cy + size.height * 0.04), paint);
          canvas.drawCircle(Offset(cx, cy + size.height * 0.1), size.width * 0.03,
              Paint()..color = Colors.white.withOpacity(0.9));
        } else if (verdict == 'medium_risk' && fillProgress > 0.4) {
          // Warning triangle
          final triPath = Path()
            ..moveTo(cx, cy - size.height * 0.12)
            ..lineTo(cx + size.width * 0.15, cy + size.height * 0.08)
            ..lineTo(cx - size.width * 0.15, cy + size.height * 0.08)
            ..close();
          canvas.drawPath(triPath, paint);
        } else if (verdict == 'low_risk' && fillProgress > 0.4) {
          // Checkmark
          final checkPath = Path()
            ..moveTo(cx - size.width * 0.15, cy)
            ..lineTo(cx - size.width * 0.04, cy + size.height * 0.1)
            ..lineTo(cx + size.width * 0.18, cy - size.height * 0.1);
          canvas.drawPath(checkPath, paint);
        } else {
          // Default: shield center dot
          canvas.drawCircle(Offset(cx, cy), size.width * 0.06, Paint()..color = strokeColor.withOpacity(0.4));
        }
        break;

      case ShieldVariant.history:
        // Clock
        canvas.drawCircle(Offset(cx, cy), size.width * 0.13, paint);
        canvas.drawLine(Offset(cx, cy), Offset(cx, cy - size.height * 0.08), paint);
        canvas.drawLine(Offset(cx, cy), Offset(cx + size.width * 0.08, cy + size.height * 0.04), paint);
        break;

      case ShieldVariant.empty:
        // Question mark — drawn with text painter
        final tp = TextPainter(
          text: TextSpan(
            text: '?',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: size.width * 0.3,
              fontWeight: FontWeight.bold,
              color: strokeColor.withOpacity(0.5),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
        break;
    }
  }

  @override
  bool shouldRepaint(_ShieldPainter old) =>
      old.fillProgress != fillProgress ||
      old.verdict != verdict ||
      old.variant != variant;
}

// Public alias (avoids Cyrillic "м" in the internal name)
class ShieldEmblem extends ShieldEmblем {
  const ShieldEmblem({
    super.key,
    super.verdict,
    super.size,
    super.animate,
    super.variant,
  });
}
