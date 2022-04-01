import 'dart:io';
import 'dart:math' as math;
// import "package:kateri/a.dart";
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:vector_math/vector_math_64.dart';

const image_size = PdfPoint(300, 300);

void main(List<String> arguments) async {
  final pdf = pw.Document();
  pdf.addPage(pw.Page(
      pageFormat:
          PdfPageFormat(image_size.x, image_size.y), // PdfPageFormat.a4,
      build: (context) => pw.CustomPaint(
            size: image_size,
            painter: draw,
          )));

  final output = File("/r/a.pdf");
  // print("output ${output}");
  // final file = File("${output?.path}/a.pdf");
  await output.writeAsBytes(await pdf.save());
  await Process.run("open-and-back-to-emacs", ["/r/a.pdf"]);
}

// ----------------------------------------------------------------------

void draw(PdfGraphics canvas, PdfPoint size) {
  draw_circle(canvas, PdfPoint(150, 150), 100,
      fill: PdfColor.fromHex("#FFA500"),
      outline: PdfColors.green,
      outline_width: 10,
      rotation: math.pi / 4,
      aspect: 0.5);
  draw_circle(canvas, PdfPoint(75, 75), 50,
      fill: PdfColor.fromHex("#FFA50040"),
      outline: PdfColor.fromHex("00FF0080"),
      outline_width: 10);
  // canvas
  //   ..drawEllipse(size.x / 2, size.y / 2, size.x / 2, size.y / 3)
  //   ..setFillColor(PdfColors.green)
  //   ..fillPath();
  // final transform = Matrix4.translationValues(100, 100, 100)
  //   ..rotateZ(- math.pi / 4)
  //   ..scale(0.5, 1.0)
  //   ;
  // canvas
  //   ..saveContext()
  //   ..setTransform(transform)
  //   ..drawEllipse(0, 0, 50, 50)
  //   ..drawRect(50, 50, 20, 50)
  //   ..setFillColor(PdfColors.orange)
  //   ..setStrokeColor(PdfColor.fromHex("#00FF00FF"))
  //   ..setLineWidth(1)
  //   ..fillAndStrokePath()
  //   ..restoreContext();
}

// ----------------------------------------------------------------------

void draw_circle(PdfGraphics canvas, PdfPoint center, double diameter,
    {PdfColor fill = const PdfColor.fromInt(0x0),
    PdfColor outline = PdfColors.black,
    double outline_width = 1.0,
    double rotation = 0.0,
    double aspect = 1.0}) {
  canvas
    ..saveContext()
    ..setGraphicState(PdfGraphicState(fillOpacity: fill.alpha, strokeOpacity: outline.alpha))
    ..setTransform(Matrix4.translationValues(center.x, center.y, 0)
      ..rotateZ(-rotation)
      ..scale(aspect, 1.0))
    ..drawEllipse(0, 0, diameter, diameter)
    ..setFillColor(fill)
    ..setStrokeColor(outline)
    ..setLineWidth(outline_width)
    ..fillAndStrokePath()
    ..restoreContext();
}

// ----------------------------------------------------------------------
