import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../draw_on.dart';

// ----------------------------------------------------------------------

void draw(DrawOn drawOn) {
  drawOn.grid();

    drawOn.point(center: const Offset(-4.0, -4.0), sizePixels: 20, shape: PointShape.circle,   fill: Colors.red, outlineWidthPixels: 1);
    drawOn.point(center: const Offset(-3.0, -3.0), sizePixels: 20, shape: PointShape.box,      fill: Colors.green, outlineWidthPixels: 1);
    drawOn.point(center: const Offset(-2.0, -2.0), sizePixels: 20, shape: PointShape.triangle, fill: Colors.blue, outlineWidthPixels: 1);
    drawOn.point(center: const Offset( 0.0, -1.0), sizePixels: 40, shape: PointShape.egg,      fill: Colors.yellow, outlineWidthPixels: 1);
    drawOn.point(center: const Offset( 2.0,  2.0), sizePixels: 40, shape: PointShape.uglyegg,  fill: Colors.cyan, outlineWidthPixels: 1);
}

// ----------------------------------------------------------------------
