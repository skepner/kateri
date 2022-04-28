import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../draw_on.dart';

// ----------------------------------------------------------------------

void draw(DrawOn drawOn) {
    drawOn.grid();

    // drawOn.point(center: drawOn.viewport.topLeft, sizePixels: 10, fill: Colors.red, outlineWidthPixels: 0);
    // drawOn.point(center: drawOn.viewport.topRight, sizePixels: 10, fill: Colors.green, outlineWidthPixels: 0);
    // drawOn.point(center: drawOn.viewport.bottomLeft, sizePixels: 10, fill: Colors.blue, outlineWidthPixels: 0);
    // drawOn.point(center: drawOn.viewport.bottomRight, sizePixels: 10, fill: Colors.yellow, outlineWidthPixels: 0);
    // drawOn.point(center: Offset.zero, sizePixels: 20, outline: const Color(0xFFFF0000), outlineWidthPixels: 5);

    // drawOn.point(center: const Offset(-3.5, -3.5), sizePixels: 200, fill: const Color(0xFFFFA500), outlineWidthPixels: 10, rotation: math.pi / 4, aspect: 0.7);
    // drawOn.point(center: const Offset(-4.1, -2.9), sizePixels: 70, fill: const Color(0x80FFA500), outlineWidthPixels: 10);
    // drawOn.point(center: const Offset(-2.9, -4.1), sizePixels: 70, fill: const Color(0x80FF0000), outlineWidthPixels: 5);
    // drawOn.point(center: const Offset(-2.9, -4.1), sizePixels: 70, shape: PointShape.box, fill: const Color(0x80FF0000), outlineWidthPixels: 5);

    // drawOn.point(center: const Offset(-2, -4.0), sizePixels: 70, shape: PointShape.triangle, fill: Colors.red, outlineWidthPixels: 2);
    // drawOn.point(center: const Offset(-2, -3.2), sizePixels: 70, shape: PointShape.triangle, rotation: RotationRight30, fill: Colors.green, outlineWidthPixels: 2);
    // drawOn.point(center: const Offset(-2, -2.4), sizePixels: 70, shape: PointShape.triangle, rotation: RotationLeft30, fill: Colors.blue, outlineWidthPixels: 2);
    // drawOn.point(center: const Offset(-2, -1.6), sizePixels: 70, shape: PointShape.triangle, rotation: RotationRight45, fill: Colors.orange, outlineWidthPixels: 2);
    // drawOn.point(center: const Offset(-2, -0.8), sizePixels: 70, shape: PointShape.triangle, rotation: RotationLeft45, fill: Colors.yellow, outlineWidthPixels: 2);

    // drawOn.point(center: const Offset(-1, -4.0), sizePixels: 70, shape: PointShape.egg, fill: Colors.red, outlineWidthPixels: 2);
    // drawOn.point(center: const Offset(-1, -3.2), sizePixels: 70, shape: PointShape.egg, rotation: RotationRight30, fill: Colors.green, outlineWidthPixels: 2);
    // drawOn.point(center: const Offset(-1, -2.4), sizePixels: 70, shape: PointShape.egg, rotation: RotationLeft30, fill: Colors.blue, outlineWidthPixels: 2);
    // drawOn.point(center: const Offset(-1, -1.6), sizePixels: 70, shape: PointShape.egg, rotation: RotationRight45, fill: Colors.orange, outlineWidthPixels: 2);
    // drawOn.point(center: const Offset(-1, -0.8), sizePixels: 70, shape: PointShape.egg, rotation: RotationLeft45, fill: Colors.yellow, outlineWidthPixels: 2);

    // drawOn.point(center: const Offset(0.0, -4.0), sizePixels: 70, shape: PointShape.uglyegg, fill: Colors.red, outlineWidthPixels: 2);
    // drawOn.point(center: const Offset(0.0, -3.2), sizePixels: 70, shape: PointShape.uglyegg, rotation: RotationRight30, fill: Colors.green, outlineWidthPixels: 2);
    // drawOn.point(center: const Offset(0.0, -2.4), sizePixels: 70, shape: PointShape.uglyegg, rotation: RotationLeft30, fill: Colors.blue, outlineWidthPixels: 2);
    // drawOn.point(center: const Offset(0.0, -1.6), sizePixels: 70, shape: PointShape.uglyegg, rotation: RotationRight45, fill: Colors.orange, outlineWidthPixels: 2);
    // drawOn.point(center: const Offset(0.0, -0.8), sizePixels: 70, shape: PointShape.uglyegg, rotation: RotationLeft45, fill: Colors.yellow, outlineWidthPixels: 2);

    // drawOn.point(center: const Offset(1.0, -4.0), sizePixels: 70, shape: PointShape.box, fill: Colors.red, outlineWidthPixels: 2);
    // drawOn.point(center: const Offset(1.0, -3.2), sizePixels: 70, shape: PointShape.box, rotation: RotationRight30, fill: Colors.green, outlineWidthPixels: 2);
    // drawOn.point(center: const Offset(1.0, -2.4), sizePixels: 70, shape: PointShape.box, rotation: RotationLeft30, fill: Colors.blue, outlineWidthPixels: 2);
    // drawOn.point(center: const Offset(1.0, -1.6), sizePixels: 70, shape: PointShape.box, rotation: RotationRight45, fill: Colors.orange, outlineWidthPixels: 2);
    // drawOn.point(center: const Offset(1.0, -0.8), sizePixels: 70, shape: PointShape.box, rotation: RotationLeft45, fill: Colors.yellow, outlineWidthPixels: 2);

    // drawOn.point(center: const Offset(-1.0, -2.0), sizePixels: 170, shape: PointShape.circle, fill: const Color(0x80FFA500), outlineWidthPixels: -1);

    // drawOn.point3d(center: const Offset(-1, 1), sizePixels: 150, fill: Colors.green, outline: Colors.red, outlineWidthPixels: 1);
    // drawOn.point3d(center: const Offset(-1, 2.5), sizePixels: 50, fill: Colors.blue, outline: Colors.red, outlineWidthPixels: 1);
    // drawOn.point3d(center: const Offset(-1, 3.5), sizePixels: 10, fill: Colors.blue, outline: Colors.red, outlineWidthPixels: 1);

    // drawOn.line(const Offset(-3.1, -0.2), const Offset(3.1, 2.1));
    // drawOn.path([const Offset(-4.1, -1.2), const Offset(3.2, 1.1), const Offset(-4.5, 2.5)], outline: Colors.cyan, fill: const Color(0x1000FF00), lineWidthPixels: 0.0);
    // drawOn.path([const Offset(-4.6, -2.2), const Offset(3.2, -2.2), const Offset(-4.5, 2.5)], outline: Colors.pink, fill: const Color(0x10000040), lineWidthPixels: 2.0);
    // drawOn.path([const Offset(-4.8, -3.2), const Offset(3.2, -3.2), const Offset(-4.8, 3.5)], outline: Colors.blue, lineWidthPixels: 1.0);

    // drawOn.arrow(const Offset(0.1, 2.1), const Offset(0.1, 4.3));
    // drawOn.arrow(const Offset(0.3, 4.3), const Offset(0.3, 2.1));
    // drawOn.arrow(const Offset(-0.5, 3.1), const Offset(3.5, 3.1));
    // drawOn.arrow(const Offset(3.5, 3.3), const Offset(-0.5, 3.3));
    // drawOn.arrow(const Offset(0.7, 2.2), const Offset(2.5, 4.1));
    // drawOn.arrow(const Offset(2.9, 4.1), const Offset(1.1, 2.2));
    // drawOn.arrow(const Offset(3.2, 2.2), const Offset(0.5, 4.1));
    // drawOn.arrow(const Offset(0.9, 4.1), const Offset(3.7, 2.2));

    // drawOn.circle(center: const Offset(-3.1, 3.1), size: 3.2, fill: const Color(0x200080FF), outline: Colors.orange);
    // drawOn.rectangle(rect: const Offset(-1.2, 4.1) & const Size(3.2, 0.5), fill: const Color(0x2000FF80), outline: Colors.red);
    // drawOn.point(center: const Offset(2.0, 0.0), sizePixels: 5);
    // drawOn.sector(
    //     center: const Offset(2.0, 0.0),
    //     radius: 1.0,
    //     fill: const Color(0x200080FF),
    //     outlineCircle: Colors.orange,
    //     outlineCircleWidthPixels: 5.0,
    //     angle: math.pi * 1.2,
    //     rotation: RotationRight30,
    //     outlineRadiusWidthPixels: 5.0);
    // drawOn.sector(
    //     center: const Offset(2.0, 0.0),
    //     radius: 0.5,
    //     fill: const Color(0x200080FF),
    //     outlineCircle: Colors.orange,
    //     outlineCircleWidthPixels: 5.0,
    //     angle: math.pi / 6,
    //     rotation: RotationLeft30,
    //     outlineRadius: Colors.green,
    //     outlineRadiusWidthPixels: 5.0);

    // drawOn.text("Later ones", Offset.zero);
    // drawOn.text("Later ones", const Offset(-4, 3.5), sizePixels: 50, textStyle: const LabelStyle(fontFamily: LabelFontFamily.monospace, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold));
    // drawOn.text("Later ones", const Offset(-4, 4), sizePixels: 50, textStyle: const LabelStyle(fontFamily: LabelFontFamily.sansSerif, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold));
    // drawOn.text("Later ones", const Offset(-4, 4), sizePixels: 50, rotation: RotationRight30, textStyle: const LabelStyle(fontFamily: LabelFontFamily.serif, color: Colors.red));

    // drawOn.text("CDC A(H3N2) HINT by clade Öl", const Offset(-5.8, -4.5), sizePixels: 30, textStyle: const LabelStyle(fontWeight: FontWeight.bold));
}

// ----------------------------------------------------------------------
