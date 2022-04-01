import 'dart:io';
// import "package:kateri/a.dart";
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main(List<String> arguments) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat(300, 300), // PdfPageFormat.a4,
        build: (context) => pw.CustomPaint(
          size: PdfPoint(200, 200),
          painter: (PdfGraphics canvas, PdfPoint size) {
            canvas
            ..drawEllipse(size.x / 2, size.y / 2, size.x / 2, size.y / 2)
            ..setFillColor(PdfColors.blue)
            ..fillPath();
          },
    )));

    final output = File("/r/a.pdf");
    // print("output ${output}");
    // final file = File("${output?.path}/a.pdf");
    await output.writeAsBytes(await pdf.save());
}
