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
  // canvas
  //   ..drawEllipse(size.x / 2, size.y / 2, size.x / 2, size.y / 3)
  //   ..setFillColor(PdfColors.green)
  //   ..fillPath();
  final transform = Matrix4.translationValues(100, 100, 100)
    ..rotateZ(- math.pi / 4)
    ..scale(0.5, 1.0)
    ;
  canvas
    ..saveContext()
    ..setTransform(transform)
    ..drawEllipse(0, 0, 50, 50)
    ..drawRect(50, 50, 20, 50)
    ..setFillColor(PdfColors.orange)
    ..setStrokeColor(PdfColor.fromHex("#00FF00FF"))
    ..setLineWidth(1)
    ..fillAndStrokePath()
    ..restoreContext();
}

// ----------------------------------------------------------------------
