import 'dart:ui';
import 'dart:io';
import 'dart:math' as math;

// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

import 'src/draw_on.dart';
import 'src/draw_on_canvas.dart';
import 'src/draw_on_pdf.dart';

// ----------------------------------------------------------------------

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Kateri ${DateTime.now()}'),
      //   backgroundColor: Colors.pink,
      // ),
      body: ListView(children: <Widget>[
        Container(
          width: 1000,
          height: 1000,
          child: CustomPaint(
            painter: OpenPainter(),
          ),
        ),
      ]),
    );
  }
}

// ----------------------------------------------------------------------

class OpenPainter extends CustomPainter {
  late Size size;

  @override
  void paint(Canvas canvas, Size size) {
    this.size = size;
    print("paint ${size}");

    _draw_points(DrawOnCanvas(canvas, size));

    DrawOnPdf(size)
      ..draw(_draw_points)
      ..write("/r/a.pdf", open: true);
  }

  void _draw_points(DrawOn drawOn) {
    drawOn.point(const Offset(0, 0), 10, fill: Colors.pink, outlineWidth: 0);
    drawOn.point(Offset(size.width, 0), 10, fill: Colors.pink, outlineWidth: 0);
    drawOn.point(Offset(size.width, size.height), 10, fill: Colors.pink, outlineWidth: 0);
    drawOn.point(Offset(0, size.height), 10, fill: Colors.pink, outlineWidth: 0);

    drawOn.point(const Offset(150, 150), 200, fill: Color(0xFFFFA500), outlineWidth: 10, rotation: math.pi / 4, aspect: 0.7);
    drawOn.point(const Offset(75, 220), 70, fill: Color(0x80FFA500), outlineWidth: 10);
    drawOn.point(const Offset(220, 75), 70, fill: Color(0x80FF0000), outlineWidth: 5);
    drawOn.point(const Offset(220, 75), 70, shape: PointShape.box, fill: Color(0x80FF0000), outlineWidth: 5);

    drawOn.point(const Offset(400,  75), 70, shape: PointShape.triangle, fill: Colors.red, outlineWidth: 2);
    drawOn.point(const Offset(400, 175), 70, shape: PointShape.triangle, rotation: RotationRight30, fill: Colors.green, outlineWidth: 2);
    drawOn.point(const Offset(400, 275), 70, shape: PointShape.triangle, rotation: RotationLeft30, fill: Colors.blue, outlineWidth: 2);
    drawOn.point(const Offset(400, 375), 70, shape: PointShape.triangle, rotation: RotationRight45, fill: Colors.orange, outlineWidth: 2);
    drawOn.point(const Offset(400, 475), 70, shape: PointShape.triangle, rotation: RotationLeft45, fill: Colors.yellow, outlineWidth: 2);

    drawOn.point(const Offset(520,  75), 70, shape: PointShape.egg, fill: Colors.red, outlineWidth: 2);
    drawOn.point(const Offset(520, 175), 70, shape: PointShape.egg, rotation: RotationRight30, fill: Colors.green, outlineWidth: 2);
    drawOn.point(const Offset(520, 275), 70, shape: PointShape.egg, rotation: RotationLeft30, fill: Colors.blue, outlineWidth: 2);
    drawOn.point(const Offset(520, 375), 70, shape: PointShape.egg, rotation: RotationRight45, fill: Colors.orange, outlineWidth: 2);
    drawOn.point(const Offset(520, 475), 70, shape: PointShape.egg, rotation: RotationLeft45, fill: Colors.yellow, outlineWidth: 2);

    // drawOn.point3d(const Offset(400, 200), 150, fill: Colors.green, outline: Colors.red, outlineWidth: 1);
    // drawOn.point3d(const Offset(400, 350), 50, fill: Colors.blue, outline: Colors.red, outlineWidth: 1);
    // drawOn.point3d(const Offset(400, 400), 10, fill: Colors.blue, outline: Colors.red, outlineWidth: 1);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
