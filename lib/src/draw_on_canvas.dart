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
    canvas.translate(-viewport.left, -viewport.top);
  }

  // ----------------------------------------------------------------------
  // 2D
  // ----------------------------------------------------------------------

  @override
  void path(List<Offset> vertices, {Color outline = const Color(0xFF000000), Color fill = const Color(0x00000000), double lineWidthPixels = 1.0, bool close = true}) {
    var path = Path()..moveTo(vertices[0].dx, vertices[0].dy);
    for (var vertix in vertices.getRange(1, vertices.length)) {
      path.lineTo(vertix.dx, vertix.dy);
    }
    if (close) {
      path.close();
    }

    canvas
      ..save()
      ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.fill
            ..color = fill
            ..isAntiAlias = true);
    if (lineWidthPixels > 0) {
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = outline
            ..strokeWidth = lineWidthPixels * pixelSize
            ..isAntiAlias = true);
    }
    canvas.restore();
  }

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
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(rotation)
      ..scale(aspect, 1.0);

    var paint = Paint()
      ..style = PaintingStyle.fill
      ..color = fill
      ..isAntiAlias = true;
    _drawShape(paint, shape, sizePixels * pixelSize);

    if (outlineWidthPixels > 0) {
      paint
        ..color = outline
        ..strokeWidth = outlineWidthPixels * pixelSize
        ..style = PaintingStyle.stroke;
      _drawShape(paint, shape, sizePixels * pixelSize);
    }

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

  @override
  void grid({double step = 1.0, Color color = const Color(0xFFCCCCCC), double lineWidthPixels = 1.0}) {
    var path = Path();
    for (var x = viewport.left.ceilToDouble(); x < viewport.right; x += step) {
      path
        ..moveTo(x, viewport.top)
        ..lineTo(x, viewport.bottom);
    }
    for (var y = viewport.top.ceilToDouble(); y < viewport.bottom; y += step) {
      path
        ..moveTo(viewport.left, y)
        ..lineTo(viewport.right, y);
    }
    canvas
      ..save()
      ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = color
            ..strokeWidth = lineWidthPixels * pixelSize
            ..isAntiAlias = true)
      ..restore();
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

    final size = sizePixels * pixelSize;
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
      ..strokeWidth = outlineWidthPixels * pixelSize
      ..shader = shader
      ..isAntiAlias = true;
    _drawShape(paint, shape, size);

    paint
      ..color = outline
      ..strokeWidth = outlineWidthPixels * pixelSize
      ..shader = null
      ..style = PaintingStyle.stroke;
    _drawShape(paint, shape, size);

    canvas.restore();
  }
}
