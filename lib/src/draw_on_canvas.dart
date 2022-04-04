import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'draw_on.dart';

class DrawOnCanvas extends DrawOn {
  final Canvas canvas;
  final Size canvasSize;
  final Rect viewport;
  final double pixelSize;

  DrawOnCanvas(this.canvas, {required this.canvasSize, required this.viewport}) : pixelSize = viewport.width / canvasSize.width {
    canvas.scale(canvasSize.width / viewport.width);
    canvas.translate(-viewport.top, -viewport.left);
  }

  // ----------------------------------------------------------------------
  // 2D
  // ----------------------------------------------------------------------

  @override
  void point(
      {required Offset center,
      required double sizePixels,
      PointShape shape = PointShape.circle,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidthPixels = 1.0,
      double rotation = NoRotation,
      double aspect = 1.0}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.scale(aspect, 1.0);

    var paint = Paint()
      ..style = PaintingStyle.fill
      ..color = fill
      ..strokeWidth = outlineWidthPixels * pixelSize
      ..isAntiAlias = true;
    _drawShape(paint, shape, sizePixels * pixelSize);

    paint
      ..color = outline
      ..strokeWidth = outlineWidthPixels * pixelSize
      ..style = PaintingStyle.stroke;
    _drawShape(paint, shape, sizePixels * pixelSize);

    canvas.restore();
  }

  void _drawShape(Paint paint, PointShape shape, double sizePixels) {
    final radius = sizePixels / 2;
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
              ..lineTo(-radius * cosPi6, sizePixels / 4)
              ..lineTo(radius * cosPi6, sizePixels / 4)
              ..close(),
            paint);
        break;
    }
  }

  // ----------------------------------------------------------------------
  // 3D
  // ----------------------------------------------------------------------

  @override
  void point3d(
      {required Offset center,
      required double sizePixels,
      PointShape shape = PointShape.circle,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidthPixels = 1.0,
      double rotation = NoRotation,
      double aspect = 1.0}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // canvas.rotate(rotation);
    // canvas.scale(aspect, 1.0);

    final rect = Offset(-sizePixels * 0.7, -sizePixels * 0.7) & Size.square(sizePixels * 1.1);
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
      ..strokeWidth = outlineWidthPixels
      ..shader = shader
      ..isAntiAlias = true;
    _drawShape(paint, shape, sizePixels);

    paint
      ..color = outline
      ..strokeWidth = outlineWidthPixels
      ..shader = null
      ..style = PaintingStyle.stroke;
    _drawShape(paint, shape, sizePixels);

    canvas.restore();
  }
}
