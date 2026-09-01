import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AmplitudeBars extends StatefulWidget {
  final bool isRecording;
  final double amplitude; // 0-1

  const AmplitudeBars({
    super.key,
    required this.isRecording,
    this.amplitude = 0,
  });

  @override
  State<AmplitudeBars> createState() => _AmplitudeBarsState();
}

class _AmplitudeBarsState extends State<AmplitudeBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int barCount = 20;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isRecording) _controller.repeat();
  }

  @override
  void didUpdateWidget(AmplitudeBars old) {
    super.didUpdateWidget(old);
    if (widget.isRecording && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isRecording) {
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
    return Semantics(
      label: widget.isRecording ? 'Recording audio — microphone active' : 'Microphone inactive',
      child: SizedBox(
        height: 48,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(barCount, (i) {
                final phase = _controller.value * 2 * 3.14159;
                final wave = (i / barCount * 2 * 3.14159 + phase);
                final sinVal = (1 + _sinApprox(wave)) / 2;
                final base = widget.isRecording ? 0.15 + widget.amplitude * 0.6 : 0.05;
                final height = widget.isRecording
                    ? (base + sinVal * 0.3 * widget.amplitude).clamp(0.05, 1.0)
                    : 0.05;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 50),
                    width: 3,
                    height: 48 * height,
                    decoration: BoxDecoration(
                      color: widget.isRecording ? AppColors.antiqueGold : AppColors.divider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  double _sinApprox(double x) {
    // Simple sine approximation
    final xx = x % (2 * 3.14159);
    return xx < 3.14159 ? (xx / 1.5708 - 1).abs() * 2 - 1 : -(((xx - 3.14159) / 1.5708 - 1).abs() * 2 - 1);
  }
}
