import 'package:flutter/material.dart';

/// Two cowrie dice (2d6) with pip faces. Taps to roll when enabled.
class DiceWidget extends StatelessWidget {
  final int d1;
  final int d2;
  final bool canRoll;
  final bool rolling;
  final VoidCallback onRoll;
  final Color diceColor;
  final Color pipColor;

  const DiceWidget({
    super.key,
    required this.d1,
    required this.d2,
    required this.canRoll,
    required this.onRoll,
    this.rolling = false,
    this.diceColor = Colors.white,
    this.pipColor = const Color(0xFF1A1A1A),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canRoll && !rolling ? onRoll : null,
      child: Opacity(
        opacity: canRoll ? 1.0 : 0.55,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Die(value: d1, rolling: rolling, diceColor: diceColor, pipColor: pipColor),
            const SizedBox(width: 10),
            _Die(value: d2, rolling: rolling, diceColor: diceColor, pipColor: pipColor),
          ],
        ),
      ),
    );
  }
}

class _Die extends StatelessWidget {
  final int value;
  final bool rolling;
  final Color diceColor;
  final Color pipColor;

  const _Die({
    required this.value,
    required this.rolling,
    required this.diceColor,
    required this.pipColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: rolling ? 1 : 0,
      duration: const Duration(milliseconds: 450),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: diceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black26, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: CustomPaint(painter: _PipPainter(value, pipColor)),
      ),
    );
  }
}

class _PipPainter extends CustomPainter {
  final int value;
  final Color pipColor;
  _PipPainter(this.value, this.pipColor);

  static const _pos = {
    1: [[0.5, 0.5]],
    2: [[0.28, 0.28], [0.72, 0.72]],
    3: [[0.26, 0.26], [0.5, 0.5], [0.74, 0.74]],
    4: [[0.3, 0.3], [0.7, 0.3], [0.3, 0.7], [0.7, 0.7]],
    5: [[0.28, 0.28], [0.72, 0.28], [0.5, 0.5], [0.28, 0.72], [0.72, 0.72]],
    6: [[0.3, 0.28], [0.7, 0.28], [0.3, 0.5], [0.7, 0.5], [0.3, 0.72], [0.7, 0.72]],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = pipColor;
    for (final p in _pos[value] ?? _pos[1]!) {
      canvas.drawCircle(
        Offset(p[0] * size.width, p[1] * size.height),
        size.width * 0.075,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PipPainter old) =>
      old.value != value || old.pipColor != pipColor;
}
