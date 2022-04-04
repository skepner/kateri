import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'draw_on.dart';

class DrawOnCanvas extends DrawOn {
  Canvas canvas;
  Size size;

  DrawOnCanvas(this.canvas, this.size);

  // ----------------------------------------------------------------------
  // 2D
  // ----------------------------------------------------------------------

  @override
  void point(Offset center, double size,
      {PointShape shape = PointShape.circle,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidth = 1.0,
      double rotation = NoRotation,
      double aspect = 1.0}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.scale(aspect, 1.0);

    var paint = Paint()
      ..style = PaintingStyle.fill
      ..color = fill
      ..strokeWidth = outlineWidth
      ..isAntiAlias = true;
    _drawShape(paint, shape, size);

    paint
      ..color = outline
      ..strokeWidth = outlineWidth
      ..style = PaintingStyle.stroke;
    _drawShape(paint, shape, size);

    canvas.restore();
  }

  void _drawShape(Paint paint, PointShape shape, double size) {
    final radius = size / 2;
    switch (shape) {
      case PointShape.circle:
        canvas.drawCircle(Offset.zero, radius, paint);
        break;

      case PointShape.egg:
        // https://books.google.de/books?id=StdwgT34RCwC&pg=PA107
        canvas.drawPath(
            Path()
              ..moveTo(0.0, radius)
              ..cubicTo(radius * 1.4, radius * 0.95, radius * 0.8, -radius * 0.98, 0.0, -radius)
              ..cubicTo(-radius * 0.8, -radius * 0.98, -radius * 1.4, radius * 0.95, 0.0, radius)
              ..close(),
            paint);
        break;

      case PointShape.box:
        canvas.drawRect(Rect.fromCircle(center: Offset.zero, radius: radius), paint);
        break;

      case PointShape.uglyegg:
        final c1x = radius * 1.0, c1y = radius * 0.6, c2x = radius * 0.8, c2y = -radius * 0.6;
        canvas.drawPath(
            Path()
              ..moveTo(0.0, radius)
              ..lineTo(c1x, c1y)
              ..lineTo(c2x, c2y)
              ..lineTo(0.0, -radius)
              ..lineTo(-c2x, c2y)
              ..lineTo(-c1x, c1y)
              ..close(),
            paint);
        break;

      case PointShape.triangle:
        final cosPi6 = math.cos(math.pi / 6);
        canvas.drawPath(
            Path()
              ..moveTo(0.0, -radius)
              ..lineTo(-radius * cosPi6, size / 4)
              ..lineTo(radius * cosPi6, size / 4)
              ..close(),
            paint);
        break;
    }
  }

  // ----------------------------------------------------------------------
  // 3D
  // ----------------------------------------------------------------------

  @override
  void point3d(Offset center, double size,
      {PointShape shape = PointShape.circle,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidth = 1.0,
      double rotation = NoRotation,
      double aspect = 1.0}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // canvas.rotate(rotation);
    // canvas.scale(aspect, 1.0);

    final rect = Offset(-size * 0.7, -size * 0.7) & Size.square(size * 1.1);
    final shader = RadialGradient(
      // colors: [
      //   const Color(0xFFC0C0FF),
      //   const Color(0xFF0000FF),
      // ],
      colors: [
        Colors.white,
        fill,
        // Colors.blue,
        // Colors.black,
      ],
      // stops: [
      //   0.0, 0.9, 1.0
      // ],
    ).createShader(rect);

    var paint = Paint()
      ..style = PaintingStyle.fill
      ..color = fill
      ..strokeWidth = outlineWidth
      ..shader = shader
      ..isAntiAlias = true;
    _drawShape(paint, shape, size);

    paint
      ..color = outline
      ..strokeWidth = outlineWidth
      ..shader = null
      ..style = PaintingStyle.stroke;
    _drawShape(paint, shape, size);

    canvas.restore();
  }
}
