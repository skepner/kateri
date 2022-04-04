import 'dart:ui';
import 'dart:io';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:vector_math/vector_math_64.dart';

import 'draw_on.dart';

class DrawOnPdf extends DrawOn {
  final PdfDocument doc;
  final Size canvasSize;
  late final PdfGraphics _canvas;

  // aspect: width / height
  DrawOnPdf({double width = 1000.0, double aspect = 1.0}) : doc = PdfDocument(), canvasSize = Size(width, width / aspect) {
    PdfPage(doc, pageFormat: PdfPageFormat(canvasSize.width, canvasSize.height));
    _canvas = doc.pdfPageList.pages[0].getGraphics();
    // coordinate system of Pdf has origin in the bottom left, change it ours with origin at the top left
    _canvas.setTransform(Matrix4.translationValues(0.0, canvasSize.height, 0.0)..scale(1.0, -1.0));
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
  void point(
      {required Offset center,
      required double sizePixels,
      PointShape shape = PointShape.circle,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidthPixels = 1.0,
      double rotation = NoRotation,
      double aspect = 1.0}) {
    final fillc = PdfColor.fromInt(fill.value), outlinec = PdfColor.fromInt(outline.value);
    _canvas
      ..saveContext()
      ..setTransform(Matrix4.translationValues(center.dx, center.dy, 0)
        ..rotateZ(rotation)
        ..scale(aspect, 1.0))
      ..setGraphicState(PdfGraphicState(fillOpacity: fillc.alpha, strokeOpacity: outlinec.alpha))
      ..setFillColor(fillc)
      ..setStrokeColor(outlinec)
      ..setLineWidth(outlineWidthPixels);
    _drawShape(shape, sizePixels);
    _canvas
      ..fillAndStrokePath()
      ..restoreContext();
  }

  void _drawShape(PointShape shape, double sizePixels) {
    final radius = sizePixels / 2;
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
        _canvas.drawRect(-radius, -radius, sizePixels, sizePixels);
        break;

      case PointShape.uglyegg:
        final c1x = radius * 1.0, c1y = radius * 0.6, c2x = radius * 0.8, c2y = -radius * 0.6;
        _canvas
          ..moveTo(0.0, radius)
          ..lineTo(c1x, c1y)
          ..lineTo(c2x, c2y)
          ..lineTo(0.0, -radius)
          ..lineTo(-c2x, c2y)
          ..lineTo(-c1x, c1y)
          ..closePath();
        break;

      case PointShape.triangle:
        final cosPi6 = math.cos(math.pi / 6);
        _canvas
          ..moveTo(0.0, -radius)
          ..lineTo(-radius * cosPi6, sizePixels / 4)
          ..lineTo(radius * cosPi6, sizePixels / 4)
          ..closePath();
        break;
    }
  }

  // ----------------------------------------------------------------------
  // 3D
  // ----------------------------------------------------------------------

  @override
  void point3d(
      {required Offset center,
      required double sizePixels,
      PointShape shape = PointShape.circle,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidthPixels = 1.0,
      double rotation = NoRotation,
      double aspect = 1.0}) {
    point(center: center, sizePixels: sizePixels, shape: shape, fill: fill, outline: outline, outlineWidthPixels: outlineWidthPixels, rotation: rotation, aspect: aspect);
  }
}
