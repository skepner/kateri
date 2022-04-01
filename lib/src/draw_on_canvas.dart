import 'dart:ui';
import 'package:flutter/material.dart';

import 'draw_on.dart';

class DrawOnCanvas extends DrawOn {
  Canvas canvas;
  Size size;

  DrawOnCanvas(this.canvas, this.size);

  @override
  void point(Offset center, double size,
      {PointShape shape = PointShape.circle,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidth = 1.0,
      double rotation = 0.0,
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
    _draw(paint, shape, size);

    paint
    ..color = outline
    ..strokeWidth = outlineWidth
    ..style = PaintingStyle.stroke;
    _draw(paint, shape, size);

    canvas.restore();
  }

  void _draw(Paint paint, PointShape shape, double size) {
    switch (shape) {
      case PointShape.circle:
      case PointShape.egg:
        canvas.drawCircle(const Offset(0, 0), size / 2, paint);
        break;
      case PointShape.box:
      case PointShape.uglyegg:
        canvas.drawRect(
            Rect.fromCircle(center: Offset(0, 0), radius: size / 2),
            paint);
        break;
    }
  }
}
