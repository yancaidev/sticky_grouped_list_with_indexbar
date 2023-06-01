import 'package:flutter/material.dart';

enum ArrowPosition { top, right, bottom, left }

class RoundedRectangleWithArrow extends StatelessWidget {
  const RoundedRectangleWithArrow({
    Key? key,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.arrowPosition,
    this.color = Colors.black,
    this.arrowWidth = 10,
    this.arrowHeight = 10,
    this.child,
  }) : super(key: key);

  final double arrowHeight;
  final ArrowPosition arrowPosition;
  final double arrowWidth;
  final double borderRadius;
  final Widget? child;
  final Color color;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height, child: Stack(
      children: [
        CustomPaint(
          size: Size(width - arrowWidth, height),
          painter: _RoundedRectangleWithArrowPainter(
            borderRadius: borderRadius,
            arrowPosition: arrowPosition,
            color: color,
            arrowWidth: arrowWidth,
            arrowHeight: arrowHeight,
          ),
        ),
        Offstage(
          offstage: child == null,
          child: ColoredBox(
            color: Colors.transparent,
            child: SizedBox(
              width: width - arrowWidth,
              height: height,
              child: child,
            ),
          ),
        ),
      ],
    ),) ;
  }
}

class _RoundedRectangleWithArrowPainter extends CustomPainter {
  _RoundedRectangleWithArrowPainter({
    required this.borderRadius,
    required this.arrowPosition,
    required this.color,
    required this.arrowWidth,
    required this.arrowHeight,
  });

  final double arrowHeight;
  final ArrowPosition arrowPosition;
  final double arrowWidth;
  final double borderRadius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(rect, paint);

    // final arrowWidth = size.width / 5;
    // final arrowHeight = size.height / 5;

    Path arrowPath;
    switch (arrowPosition) {
      case ArrowPosition.top:
        arrowPath = Path()
          ..moveTo(size.width / 2 - arrowWidth / 2, 0)
          ..lineTo(size.width / 2 + arrowWidth / 2, 0)
          ..lineTo(size.width / 2, -arrowHeight)
          ..close();
        break;
      case ArrowPosition.right:
        arrowPath = Path()
          ..moveTo(size.width, size.height / 2 - arrowHeight / 2)
          ..lineTo(size.width, size.height / 2 + arrowHeight / 2)
          ..lineTo(size.width + arrowHeight, size.height / 2)
          ..close();
        break;
      case ArrowPosition.bottom:
        arrowPath = Path()
          ..moveTo(size.width / 2 - arrowWidth / 2, size.height)
          ..lineTo(size.width / 2 + arrowWidth / 2, size.height)
          ..lineTo(size.width / 2, size.height + arrowHeight)
          ..close();
        break;
      case ArrowPosition.left:
        arrowPath = Path()
          ..moveTo(0, size.height / 2 - arrowWidth / 2)
          ..lineTo(0, size.height / 2 + arrowWidth / 2)
          ..lineTo(-arrowHeight, size.height / 2)
          ..close();
        break;
    }
    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
