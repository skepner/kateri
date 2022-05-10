import 'dart:ui';
import 'dart:io';
import 'dart:typed_data'; // Uint8List
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
// import 'package:pdf/src/pdf/obj/type1_font.dart';
import 'package:vector_math/vector_math_64.dart';

import 'color.dart';
import 'draw_on.dart';
import 'viewport.dart';

// ----------------------------------------------------------------------

String fontKey(LabelStyle style) => "${style.fontFamily} ${style.fontWeight} ${style.fontStyle}";

class CanvasPdf extends CanvasRoot {
  CanvasPdf(Size canvasSize)
      : doc = PdfDocument(),
        _fonts = <String, PdfFont>{},
        super(canvasSize) {
    PdfPage(doc, pageFormat: PdfPageFormat(canvasSize.width, canvasSize.height));
    canvas = doc.pdfPageList.pages[0].getGraphics();

    // coordinate system of Pdf has origin in the bottom left, change it ours with origin at the top left
    canvas.setTransform(Matrix4.identity()
      ..scale(1.0, -1.0)
      ..translate(0.0, -canvasSize.height, 0.0));
  }

  void paintBy(Function painter) {
    painter(this);
  }

  @override
  void draw(Rect drawingArea, Viewport viewport, Function doDraw, {Color? debuggingOutline, bool clip = false}) {
    canvas
      ..saveContext()
      ..setTransform(Matrix4.translationValues(drawingArea.left, drawingArea.top, 0.0));
    if (clip) {
      canvas
        ..drawRect(0.0, 0.0, drawingArea.width, drawingArea.height)
        ..clipPath();
    }
    canvas.saveContext();
    doDraw(_DrawOnPdf(this, drawingArea.size, viewport));
    canvas.restoreContext();
    if (debuggingOutline != null) {
      canvas
        ..drawRect(0.0, 0.0, drawingArea.width, drawingArea.height)
        ..setStrokeColor(PdfColor.fromInt(debuggingOutline.value))
        ..setLineWidth(3.0)
        ..strokePath();
    }
    canvas.restoreContext();
  }

  Future<Uint8List> bytes() async {
    return doc.save();
  }

  void write(String filename, {bool open = true}) async {
    final file = File(filename);
    await file.writeAsBytes(await doc.save());
    if (open) {
      await Process.run("open-and-back-to-emacs", [filename]);
    }
  }

  PdfFont getFont(String key) {
    var font = _fonts[key];
    if (font == null) {
      switch (key) {
        case "LabelFontFamily.monospace FontWeight.w400 FontStyle.normal":
        case "LabelFontFamily.courier FontWeight.w400 FontStyle.normal":
          font = PdfFont.courier(doc);
          break;
        case "LabelFontFamily.monospace FontWeight.w700 FontStyle.normal":
        case "LabelFontFamily.courier FontWeight.w700 FontStyle.normal":
          font = PdfFont.courierBold(doc);
          break;
        case "LabelFontFamily.monospace FontWeight.w400 FontStyle.italic":
        case "LabelFontFamily.courier FontWeight.w400 FontStyle.italic":
          font = PdfFont.courierOblique(doc);
          break;
        case "LabelFontFamily.monospace FontWeight.w700 FontStyle.italic":
        case "LabelFontFamily.courier FontWeight.w700 FontStyle.italic":
          font = PdfFont.courierBoldOblique(doc);
          break;

        case "LabelFontFamily.sansSerif FontWeight.w400 FontStyle.normal":
        case "LabelFontFamily.helvetica FontWeight.w400 FontStyle.normal":
          font = PdfFont.helvetica(doc);
          break;
        case "LabelFontFamily.sansSerif FontWeight.w700 FontStyle.normal":
        case "LabelFontFamily.helvetica FontWeight.w700 FontStyle.normal":
          font = PdfFont.helveticaBold(doc);
          break;
        case "LabelFontFamily.sansSerif FontWeight.w400 FontStyle.italic":
        case "LabelFontFamily.helvetica FontWeight.w400 FontStyle.italic":
          font = PdfFont.helveticaOblique(doc);
          break;
        case "LabelFontFamily.sansSerif FontWeight.w700 FontStyle.italic":
        case "LabelFontFamily.helvetica FontWeight.w700 FontStyle.italic":
          font = PdfFont.helveticaBoldOblique(doc);
          break;

        case "LabelFontFamily.serif FontWeight.w400 FontStyle.normal":
        case "LabelFontFamily.times FontWeight.w400 FontStyle.normal":
          font = PdfFont.times(doc);
          break;
        case "LabelFontFamily.serif FontWeight.w700 FontStyle.normal":
        case "LabelFontFamily.times FontWeight.w700 FontStyle.normal":
          font = PdfFont.timesBold(doc);
          break;
        case "LabelFontFamily.serif FontWeight.w400 FontStyle.italic":
        case "LabelFontFamily.times FontWeight.w400 FontStyle.italic":
          font = PdfFont.timesItalic(doc);
          break;
        case "LabelFontFamily.serif FontWeight.w700 FontStyle.italic":
        case "LabelFontFamily.times FontWeight.w700 FontStyle.italic":
          font = PdfFont.timesBoldItalic(doc);
          break;
      }
      font ??= PdfFont.helvetica(doc);
      _fonts[key] = font;
    }
    return font;
  }

  final PdfDocument doc;
  final Map<String, PdfFont> _fonts;
  late final PdfGraphics canvas;
}

// ----------------------------------------------------------------------

class _DrawOnPdf extends DrawOn {
  final CanvasPdf _canvasPdf;
  final PdfGraphics _canvas;
  final Size canvasSize;
  final double _pixelSize;

  // aspect: width / height
  _DrawOnPdf(this._canvasPdf, this.canvasSize, Viewport viewport)
      : _canvas = _canvasPdf.canvas,
        _pixelSize = viewport.width / canvasSize.width,
        super(viewport) {
    _canvas.setTransform(Matrix4.identity()
      ..scale(canvasSize.width / viewport.width)
      ..translate(-viewport.left, -viewport.top, 0.0));
  }

  @override
  double get pixelSize => _pixelSize;

  @override
  void transform(Matrix4 transformation) {}

  // ----------------------------------------------------------------------
  // 2D
  // ----------------------------------------------------------------------

  @override
  void point(
      {required Vector3 center,
      required double sizePixels,
      PointShape shape = PointShape.circle,
      Color fill = transparent,
      Color outline = black,
      double outlineWidthPixels = 1.0,
      double rotation = noRotation,
      double aspect = 1.0,
      PointLabel? label}) {
    _canvas
      ..saveContext()
      ..setTransform(Matrix4.translation(center)
        ..rotateZ(rotation)
        ..scale(aspect, 1.0));
    _setColorsLineWidth(fill: fill, outline: outline, lineWidthPixels: outlineWidthPixels);
    _drawShape(shape, sizePixels * pixelSize);
    _fillAndStroke(outlineWidthPixels);
    _canvas.restoreContext();

    if (label != null && label.text.isNotEmpty && label.sizePixels > 0.0) {
      addPointLabel(center: center, sizePixels: sizePixels, outlineWidthPixels: outlineWidthPixels, label: label, delayed: true);
    }
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
        _canvas.drawRect(-radius, -radius, size, size);
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
          ..lineTo(-radius * cosPi6, size / 4)
          ..lineTo(radius * cosPi6, size / 4)
          ..closePath();
        break;
    }
  }

  @override
  void path(List<Offset> vertices, {Color outline = black, Color fill = transparent, double lineWidthPixels = 1.0, bool close = true}) {
    _canvas.saveContext();
    _setColorsLineWidth(fill: fill, outline: outline, lineWidthPixels: lineWidthPixels);
    _canvas.moveTo(vertices[0].dx, vertices[0].dy);
    for (var vertix in vertices.getRange(1, vertices.length)) {
      _canvas.lineTo(vertix.dx, vertix.dy);
    }
    _canvas.closePath();
    _fillAndStroke(lineWidthPixels);
    _canvas.restoreContext();
  }

  void _setColorsLineWidth({required Color fill, required Color outline, required lineWidthPixels}) {
    final fillC = PdfColor.fromInt(fill.value), outlineC = PdfColor.fromInt(outline.value);
    _canvas
      ..setGraphicState(PdfGraphicState(fillOpacity: fillC.alpha, strokeOpacity: outlineC.alpha))
      ..setFillColor(fillC)
      ..setStrokeColor(outlineC)
      ..setLineWidth(lineWidthPixels * pixelSize);
  }

  void _fillAndStroke(double lineWidthPixels) {
    if (lineWidthPixels > 0) {
      _canvas.fillAndStrokePath();
    } else {
      _canvas.fillPath();
    }
  }

  @override
  void circle({required Offset center, required double size, Color fill = transparent, Color outline = black, double outlineWidthPixels = 1.0, double rotation = noRotation, double aspect = 1.0}) {
    _canvas
      ..saveContext()
      ..setTransform(Matrix4.translationValues(center.dx, center.dy, 0)
        ..rotateZ(rotation)
        ..scale(aspect, 1.0));
    _setColorsLineWidth(fill: fill, outline: outline, lineWidthPixels: outlineWidthPixels);
    _canvas.drawEllipse(0.0, 0.0, size / 2, size / 2);
    _fillAndStroke(outlineWidthPixels);
    _canvas.restoreContext();
  }

  @override
  void sector({
    required Offset center,
    required double radius,
    required double angle,
    Color fill = transparent,
    Color outlineCircle = black,
    double outlineCircleWidthPixels = 1.0,
    Color outlineRadius = black,
    double outlineRadiusWidthPixels = 1.0,
    double rotation = noRotation, // noRotation - first radius in upright
  }) {
    _canvas
      ..saveContext()
      ..setTransform(Matrix4.translationValues(center.dx, center.dy, 0)..rotateZ(rotation));
    final otherPointOnArc = Offset(math.sin(angle) * radius, -math.cos(angle) * radius);
    if (fill.alpha > 0) {
      final fillc = PdfColor.fromInt(fill.value);
      _canvas
        ..moveTo(0.0, 0.0)
        ..lineTo(0.0, -radius)
        ..bezierArc(0.0, -radius, radius, radius, otherPointOnArc.dx, otherPointOnArc.dy, large: angle > math.pi, sweep: true)
        ..lineTo(0.0, 0.0)
        ..setGraphicState(PdfGraphicState(fillOpacity: fillc.alpha))
        ..setFillColor(fillc)
        ..fillPath();
    }
    if (outlineCircleWidthPixels > 0 && outlineCircle.alpha > 0) {
      final outlineCircleC = PdfColor.fromInt(outlineCircle.value);
      _canvas
        ..moveTo(0.0, -radius)
        ..bezierArc(0.0, -radius, radius, radius, otherPointOnArc.dx, otherPointOnArc.dy, large: angle > math.pi, sweep: true)
        ..setGraphicState(PdfGraphicState(strokeOpacity: outlineCircleC.alpha))
        ..setStrokeColor(outlineCircleC)
        ..setLineWidth(outlineCircleWidthPixels * pixelSize)
        ..strokePath();
    }
    if (outlineRadiusWidthPixels > 0 && outlineRadius.alpha > 0) {
      final outlineRadiusC = PdfColor.fromInt(outlineRadius.value);
      _canvas
        ..moveTo(0.0, -radius)
        ..lineTo(0.0, 0.0)
        ..lineTo(otherPointOnArc.dx, otherPointOnArc.dy)
        ..setGraphicState(PdfGraphicState(strokeOpacity: outlineRadiusC.alpha))
        ..setStrokeColor(outlineRadiusC)
        ..setLineWidth(outlineRadiusWidthPixels * pixelSize)
        ..strokePath();
    }
    _canvas.restoreContext();
  }

  static const fontScaleToMatchCanvas = 1.02;

  @override
  void text(String text, Offset origin, {double sizePixels = 20.0, double rotation = 0.0, LabelStyle textStyle = const LabelStyle()}) {
    final colorC = PdfColor.fromInt(textStyle.color.value);
    _canvas
      ..saveContext()
      ..setTransform(Matrix4.translationValues(origin.dx, origin.dy, 0)
        ..rotateZ(rotation)
        ..scale(1.0, -1.0))
      ..setGraphicState(PdfGraphicState(strokeOpacity: colorC.alpha, fillOpacity: colorC.alpha))
      ..setFillColor(colorC)
      ..drawString(_canvasPdf.getFont(fontKey(textStyle)), sizePixels * pixelSize * fontScaleToMatchCanvas, text, 0.0, 0.0)
      ..restoreContext();
  }

  @override
  Size textSize(String text, {double sizePixels = 20.0, LabelStyle textStyle = const LabelStyle()}) {
    final metrics = _canvasPdf.getFont(fontKey(textStyle)).stringMetrics(text);
    const height = 1.0;         // instead of metrics.height (1.156) to match canvas font size
    return Size(metrics.width, height) * (sizePixels * pixelSize * fontScaleToMatchCanvas);
  }

  @override
  void grid({double step = 1.0, Color color = const Color(0xFFCCCCCC), double lineWidthPixels = 1.0}) {
    final colorc = PdfColor.fromInt(color.value);
    _canvas
      ..saveContext()
      ..setStrokeColor(colorc)
      ..setLineWidth(lineWidthPixels * pixelSize);
    for (var x = viewport.left.ceilToDouble(); x <= viewport.right; x += step) {
      _canvas
        ..moveTo(x, viewport.top)
        ..lineTo(x, viewport.bottom);
    }
    for (var y = viewport.top.ceilToDouble(); y <= viewport.bottom; y += step) {
      _canvas
        ..moveTo(viewport.left, y)
        ..lineTo(viewport.right, y);
    }
    _canvas
      ..strokePath()
      ..restoreContext();
  }

  // ----------------------------------------------------------------------
  // 3D
  // ----------------------------------------------------------------------

  @override
  void point3d(
      {required Vector3 center,
      required double sizePixels,
      PointShape shape = PointShape.circle,
      Color fill = transparent,
      Color outline = black,
      double outlineWidthPixels = 1.0,
      double rotation = noRotation,
      double aspect = 1.0}) {
    point(center: center, sizePixels: sizePixels, shape: shape, fill: fill, outline: outline, outlineWidthPixels: outlineWidthPixels, rotation: rotation, aspect: aspect);
  }
}
