import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../draw_on.dart';

// ----------------------------------------------------------------------

void draw(DrawOn drawOn) {
  drawOn.grid();

  drawOn.point(center: const Offset(-4.0, -4.0), sizePixels:   20, label: const PointLabel("Albertine AK/1/21-cell"), shape: PointShape.circle,   fill: Colors.red, outlineWidthPixels: 1);
    drawOn.point(center: const Offset(-3.0, -3.0), sizePixels: 20, label: const PointLabel("Odette"), shape: PointShape.box,      fill: Colors.green, outlineWidthPixels: 1);
    drawOn.point(center: const Offset(-2.0, -2.0), sizePixels: 20, label: const PointLabel("Oriane"), shape: PointShape.triangle, fill: Colors.blue, outlineWidthPixels: 1);
    drawOn.point(center: const Offset( 0.0, -1.0), sizePixels: 100, label: const PointLabel("Gilberte", color: Colors.red), shape: PointShape.egg,      fill: Colors.yellow, outline: Colors.orange, outlineWidthPixels: 20);
    drawOn.point(center: const Offset( 1.0, -1.0), sizePixels: 100, label: const PointLabel("Gilberte", offset: Offset( 0.0, -1.0)), shape: PointShape.egg,      fill: Colors.yellow, outline: Colors.orange, outlineWidthPixels: 20);
    drawOn.point(center: const Offset( 2.0,  0.0), sizePixels: 100, label: const PointLabel("Gilberte", offset: Offset(-1.0,  0.0)), shape: PointShape.egg,      fill: Colors.yellow, outline: Colors.orange, outlineWidthPixels: 20);
    drawOn.point(center: const Offset( 3.0,  1.0), sizePixels: 100, label: const PointLabel("Gilberte", offset: Offset( 1.0,  0.0)), shape: PointShape.egg,      fill: Colors.yellow, outline: Colors.orange, outlineWidthPixels: 20);
    drawOn.point(center: const Offset( 0.0,  2.0), sizePixels: 100, label: const PointLabel("KS/17-cell", color: Colors.blue), shape: PointShape.egg,      fill: Colors.yellow, outline: Colors.orange, outlineWidthPixels: 1);
    drawOn.point(center: const Offset( 2.0,  3.0), sizePixels: 40, label: const PointLabel("Bjork", rotation: RotationLeft45), shape: PointShape.uglyegg,  fill: Colors.cyan, outlineWidthPixels: 1, rotation: RotationRight30);
}

// ----------------------------------------------------------------------
