import 'dart:ui';
import 'dart:io';
import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;

import 'draw_on.dart';

class DrawOnPdf extends DrawOn {
  final PdfDocument doc;
  // PdfGraphics canvas;
  Size size;

  DrawOnPdf(this.doc, this.size);

  factory DrawOnPdf.file(Size size) {
    final doc = PdfDocument();
    PdfPage(doc, pageFormat: PdfPageFormat(size.width, size.height));
    return DrawOnPdf(doc, size);
  }

  void draw(Function painter) {
    painter(this);
  }

  void write(String filename, {bool open = true}) async {
    final file = File(filename);
    await file.writeAsBytes(await doc.save());
    if (open) {
      await Process.run("open-and-back-to-emacs", [filename]);
    }
  }

  PdfGraphics get _canvas {
    return doc.pdfPageList.pages[0].getGraphics();
  }

  // ----------------------------------------------------------------------
  // 2D
  // ----------------------------------------------------------------------

  @override
  void point(Offset center, double size,
      {PointShape shape = PointShape.circle, Color fill = const Color(0x00000000), Color outline = const Color(0xFF000000), double outlineWidth = 1.0, double rotation = 0.0, double aspect = 1.0}) {
    _canvas
      ..drawEllipse(0, 0, 100, 200)
      ..setFillColor(PdfColors.pink)
      ..fillPath();
  }

  // ----------------------------------------------------------------------
  // 3D
  // ----------------------------------------------------------------------

  @override
  void point3d(Offset center, double size,
      {PointShape shape = PointShape.circle, Color fill = const Color(0x00000000), Color outline = const Color(0xFF000000), double outlineWidth = 1.0, double rotation = 0.0, double aspect = 1.0}) {
    point(center, size);
  }
}
