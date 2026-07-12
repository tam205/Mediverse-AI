import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class MediverseGradient extends StatelessWidget {
  const MediverseGradient({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.deepNavy, AppColors.deepTeal, Color(0xFF041116)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

class ShieldLogo extends StatelessWidget {
  const ShieldLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ShieldPainter(),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Icon(Icons.add, color: Colors.white, size: size * .42),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.aqua, AppColors.ocean],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .065
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * .5, size.height * .08)
      ..lineTo(size.width * .85, size.height * .2)
      ..lineTo(size.width * .82, size.height * .55)
      ..quadraticBezierTo(
        size.width * .75,
        size.height * .82,
        size.width * .5,
        size.height * .93,
      )
      ..quadraticBezierTo(
        size.width * .25,
        size.height * .82,
        size.width * .18,
        size.height * .55,
      )
      ..lineTo(size.width * .15, size.height * .2)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
