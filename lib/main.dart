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
      appBar: AppBar(
        title: Text('Kateri ${DateTime.now()}'),
        backgroundColor: Colors.pink,
      ),
      body: ListView(children: <Widget>[
        Container(
          width: 500,
          height: 500,
          child: CustomPaint(
            painter: OpenPainter(),
          ),
        ),
      ]),
    );
  }
}

// ----------------------------------------------------------------------

// const BLUE_NORMAL = Color(0xff54c5f8);
// const GREEN_NORMAL = Color(0xff6bde54);
// const BLUE_DARK2 = Color(0xff01579b);
// const BLUE_DARK1 = Color(0xff29b6f6);
// const RED_DARK1 = Color(0xfff26388);
// const RED_DARK2 = Color(0xfff782a0);
// const RED_DARK3 = Color(0xfffb8ba8);
// const RED_DARK4 = Color(0xfffb89a6);
// const RED_DARK5 = Color(0xfffd86a5);
// const YELLOW_NORMAL = Color(0xfffcce89);
// const List<Point> POINT = [Point(100, 100)];

class OpenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _draw_points(DrawOnCanvas(canvas, size));

    DrawOnPdf.file(size)
      ..draw(_draw_points)
      ..write("/r/a.pdf", open: true);
  }

  void _draw_points(DrawOn drawOn) {
    drawOn.point(const Offset(150, 150), 200, fill: Color(0xFFFFA500), outlineWidth: 10, rotation: math.pi / 4, aspect: 0.7);
    drawOn.point(const Offset(75, 220), 70, fill: Color(0x80FFA500), outlineWidth: 10);
    drawOn.point(const Offset(220, 75), 70, fill: Color(0x80FF0000), outlineWidth: 5);
    drawOn.point(const Offset(220, 75), 70, shape: PointShape.box, fill: Color(0x80FF0000), outlineWidth: 5);

    drawOn.point3d(const Offset(400, 200), 150, fill: Colors.green, outline: Colors.red, outlineWidth: 1);
    drawOn.point3d(const Offset(400, 350), 50, fill: Colors.blue, outline: Colors.red, outlineWidth: 1);
    drawOn.point3d(const Offset(400, 400), 10, fill: Colors.blue, outline: Colors.red, outlineWidth: 1);
  }

  // make_pdf().then((success) => print("pdf saved"));
  // print("draw");

  // draw_point(canvas, Offset(size.width / 2, size.height / 2), 200, 1.0, 0.0);
  // draw_point(canvas, Offset(size.width / 2, size.height / 4), 200, 0.5, 0.0);
  // draw_point(
  //     canvas, Offset(size.width / 2, size.height / 4 * 3), 200, 0.7, 1.0);

  // if (size.width > 1.0 && size.height > 1.0) {
  //   print(">1.9");
  //   _sizeUtil.logicSize = size;
  // }
  // var paint = Paint()
  //   ..style = PaintingStyle.fill
  //   ..color = Colors.blue
  //   ..strokeWidth = 2.0
  //   ..isAntiAlias = true;
  // // paint.color = Colors.grey[900];
  // canvas.drawCircle(Offset(size.width / 2, 250.0), 200.0, paint);

  // paint.color = const Color(0x60f26388);
  // paint.strokeWidth = 20;
  // paint.style = PaintingStyle.stroke;
  // // canvas.drawCircle(const Offset(250, 250.0), 200.0, paint);
  // canvas.drawOval(
  //     Rect.fromCenter(
  //         center: const Offset(250, 250.0), width: 400, height: 600),
  //     paint);

  // var center = Offset(
  //   _sizeUtil.getAxisX(250.0),
  //   _sizeUtil.getAxisY(250.0),
  // );
  // var radius = _sizeUtil.getAxisBoth(200);
  // _drawArcGroup(
  //   canvas,
  //   center: center,
  //   radius: radius,
  //   sources: [
  //     1,
  //     1,
  //     1,
  //     1,
  //     1,
  //     1,
  //     1,
  //     1,
  //     1,
  //   ],
  //   colors: [BLUE_DARK1, RED_DARK1, BLUE_DARK2, GREEN_NORMAL, YELLOW_NORMAL],
  //   paintWidth: 80.0,
  //   startAngle: 1.3 * startAngle / radius,
  //   hasEnd: true,
  //   hasCurrent: false,
  //   curPaintWidth: 45.0,
  //   curIndex: 1,
  // );
  // canvas.save();
  // canvas.restore();
  // }

  // Future<bool> make_pdf() async {
  //   final pdf = pw.Document();
  //   // pw.Page page = pw.Page(
  //   //   pageFormat: PdfPageFormat(300, 300), // PdfPageFormat.a4,
  //   //   margin: pw.EdgeInsets.all(32),
  //   //   build: (context) => pw.Column(children: [pw.Text("voice"), pw.PdfLogo(), pw.FlutterLogo(), pw.CustomPaint(foregroundPainter: pdf_paint, size: PdfPoint(500, 500))])
  //   // );
  //   // pdf.addPage(page);

  //   pdf.addPage(pw.Page(
  //       pageFormat: PdfPageFormat(300, 300), // PdfPageFormat.a4,
  //       build: (context) => pw.CustomPaint(
  //             size: PdfPoint(200, 200),
  //             painter: (PdfGraphics canvas, PdfPoint size) {
  //               canvas
  //                 ..drawEllipse(size.x / 2, size.y / 2, size.x / 2, size.y / 2)
  //                 ..setFillColor(PdfColors.pink)
  //                 ..fillPath();
  //             },
  //           )));

  //   final output = await getDownloadsDirectory();
  //   final file = File("${output?.path}/a.pdf");
  //   await file.writeAsBytes(await pdf.save());
  //   print("pdf: ${file.path}");
  //   await Process.run("open-and-back-to-emacs", [file.path]);
  //   return true;
  // }

  // void pdf_paint(PdfGraphics canvas, PdfPoint size) {
  //   print("pdf ${size}");
  //   canvas.setColor(PdfColor.fromHex("#FFa500"));
  //   canvas.setLineWidth(10);
  //   canvas.moveTo(100, 100);
  //   canvas.lineTo(200, 200);
  //   canvas.drawEllipse(size.x / 2, size.y / 2, size.x / 8, size.y / 7);
  //   canvas.drawRect(100, 100, 200, 300);
  // }

  // void draw_point(Canvas canvas, Offset center, double size, double aspect,
  //     double rotation) {
  //   canvas.save();
  //   canvas.translate(center.dx, center.dy);
  //   canvas.rotate(rotation);
  //   canvas.scale(aspect, 1.0);

  //   var paint = Paint()
  //     ..style = PaintingStyle.fill
  //     ..color = Colors.blue
  //     // ..strokeWidth = 2.0
  //     ..isAntiAlias = true;
  //   // paint.color = Colors.grey[900];
  //   canvas.drawCircle(const Offset(0, 0), size / 2, paint);

  //   paint.color = const Color(0x60ffa500);
  //   paint.strokeWidth = 20;
  //   paint.style = PaintingStyle.stroke;
  //   canvas.drawCircle(const Offset(0, 0), size / 2, paint);

  //   canvas.restore();
  // }

  // // @override
  // void xpaint(Canvas canvas, Size size) {
  //   var paint1 = Paint()
  //     ..color = Color(0xff63aa65)
  //     ..strokeCap = StrokeCap.round
  //     ..strokeWidth = 50;
  //   //list of points
  //   var points = [
  //     Offset(0, 0),
  //     Offset(size.width, 50),
  //     Offset(size.width, size.height),
  //     Offset(size.width / 2, size.height / 2),
  //     // Offset(80, 70),
  //     // Offset(380, 175),
  //     // Offset(200, 175),
  //     // Offset(150, 105),
  //     // Offset(300, 75),
  //     // Offset(320, 200),
  //     // Offset(89, 125)
  //   ];
  //   //draw points on canvas
  //   canvas.drawPoints(PointMode.points, points, paint1);
  //   // print(size);
  // }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
