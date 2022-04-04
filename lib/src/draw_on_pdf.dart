import 'dart:ui';
import 'dart:io';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:vector_math/vector_math_64.dart';

import 'draw_on.dart';

class DrawOnPdf extends DrawOn {
  final PdfDocument doc;
  Size size;
  late final _canvas;

  DrawOnPdf(this.size) : doc = PdfDocument() {
    PdfPage(doc, pageFormat: PdfPageFormat(size.width, size.height));
    _canvas = doc.pdfPageList.pages[0].getGraphics();
    // coordinate system of Pdf has origin in the bottom left, change it ours with origin at the top left
    _canvas.setTransform(Matrix4.translationValues(0.0, size.height, 0.0)..scale(1.0, -1.0));
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

  // ----------------------------------------------------------------------
  // 2D
  // ----------------------------------------------------------------------

  @override
  void point(Offset center, double size,
      {PointShape shape = PointShape.circle, Color fill = const Color(0x00000000), Color outline = const Color(0xFF000000), double outlineWidth = 1.0, double rotation = NoRotation, double aspect = 1.0}) {
    final fillc = PdfColor.fromInt(fill.value), outlinec = PdfColor.fromInt(outline.value);
    _canvas
      ..saveContext()
      ..setTransform(Matrix4.translationValues(center.dx, center.dy, 0)
        ..rotateZ(rotation)
        ..scale(aspect, 1.0))
      ..setGraphicState(PdfGraphicState(fillOpacity: fillc.alpha, strokeOpacity: outlinec.alpha))
      ..setFillColor(fillc)
      ..setStrokeColor(outlinec)
      ..setLineWidth(outlineWidth);
    _drawShape(shape, size);
    _canvas
      ..fillAndStrokePath()
      ..restoreContext();
  }

  void _drawShape(PointShape shape, double size) {
    final radius = size / 2;
    switch (shape) {
      case PointShape.circle:
        _canvas.drawEllipse(0.0, 0.0, radius, radius);
        break;
      case PointShape.egg:
        // https://books.google.de/books?id=StdwgT34RCwC&pg=PA107
        _canvas
          ..moveTo(0.0, radius)
          ..curveTo(radius * 1.4, radius * 0.95, radius * 0.8, -radius * 0.98, 0.0, -radius)
          ..curveTo(-radius * 0.8, -radius * 0.98, -radius * 1.4, radius * 0.95, 0.0, radius)
          ..closePath();
        break;
      case PointShape.box:
      case PointShape.uglyegg:
        _canvas.drawRect(-radius, -radius, size, size);
        break;
      case PointShape.triangle:
        final cosPi6 = math.cos(math.pi / 6);
        _canvas
          ..moveTo(0.0, -radius)
          ..lineTo(-radius * cosPi6, size / 4)
          ..lineTo(radius * cosPi6, size / 4)
          ..closePath();
        break;
    }
  }

  // ----------------------------------------------------------------------
  // 3D
  // ----------------------------------------------------------------------

  @override
  void point3d(Offset center, double size,
      {PointShape shape = PointShape.circle, Color fill = const Color(0x00000000), Color outline = const Color(0xFF000000), double outlineWidth = 1.0, double rotation = NoRotation, double aspect = 1.0}) {
    point(center, size, shape: shape, fill: fill, outline: outline, outlineWidth: outlineWidth, rotation: rotation, aspect: aspect);
  }
}
