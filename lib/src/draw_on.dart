import 'dart:ui';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

import 'viewport.dart';
import 'color.dart';

// ----------------------------------------------------------------------

enum PointShape { circle, box, triangle, egg, uglyegg }

const noRotation = 0.0;
const rotationReassortant = 0.5;
const rotationRight30 = math.pi / 6;
const rotationRight45 = math.pi / 4;
const rotationRight60 = math.pi / 3;
const rotationLeft30 = -math.pi / 6;
const rotationLeft45 = -math.pi / 4;
const rotationLeft60 = -math.pi / 3;

const aspectNormal = 1.0;
const aspectEgg = 0.75;

// ----------------------------------------------------------------------

class PointPlotSpec {
  static const testSize = 20.0;
  static const refSize = 32.0;

  bool shown = true;
  double sizePixels = testSize;
  PointShape shape = PointShape.circle;
  Color fill = transparent;
  Color outline = black;
  double outlineWidthPixels = 1.0;
  double rotation = noRotation;
  double aspect = aspectNormal;
  PointLabel? label;

  PointPlotSpec();
  PointPlotSpec.from(PointPlotSpec src)
      : shown = src.shown,
        sizePixels = src.sizePixels,
        shape = src.shape,
        fill = src.fill,
        outline = src.outline,
        outlineWidthPixels = src.outlineWidthPixels,
        rotation = src.rotation,
        aspect = src.aspect {
    if (src.label != null) label = PointLabel.from(src.label!);
  }

  PointPlotSpec.referenceCell(this.outline) : sizePixels = refSize;
  PointPlotSpec.referenceEgg(this.outline)
      : sizePixels = refSize,
        shape = PointShape.egg;
  PointPlotSpec.referenceReassortant(this.outline)
      : sizePixels = refSize,
        shape = PointShape.egg,
        rotation = rotationReassortant;
  PointPlotSpec.testCell(this.fill, this.outline);
  PointPlotSpec.testEgg(this.fill, this.outline) : shape = PointShape.egg;
  PointPlotSpec.testReassortant(this.fill, this.outline)
      : shape = PointShape.egg,
        rotation = rotationReassortant;
  PointPlotSpec.serumCell(this.outline)
      : sizePixels = refSize,
        shape = PointShape.box;
  PointPlotSpec.serumEgg(this.outline)
      : sizePixels = refSize,
        shape = PointShape.uglyegg;
  PointPlotSpec.serumReassortant(this.outline)
      : sizePixels = refSize,
        shape = PointShape.uglyegg,
        rotation = rotationReassortant;
}

// ----------------------------------------------------------------------

enum LabelFontFamily {
  monospace,
  sansSerif,
  serif,
  helvetica,
  courier,
  times /* , symbol, zapf */
}

LabelFontFamily labelFontFamilyFromString(String? str) =>
    str == null ? LabelFontFamily.helvetica : LabelFontFamily.values.firstWhere((lff) => lff.toString().toLowerCase() == ("LabelFontFamily." + str.toLowerCase()));

FontWeight fontWeightFromString(String? str, [String? dflt]) => (str ?? dflt)?.toLowerCase() == "bold" ? FontWeight.bold : FontWeight.normal;
FontStyle fontStyleFromString(String? str, [String? dflt]) => (str ?? dflt)?.toLowerCase() == "italic" ? FontStyle.italic : FontStyle.normal;

class LabelStyle {
  final Color color;
  final LabelFontFamily fontFamily;
  final FontWeight fontWeight;
  final FontStyle fontStyle;

  const LabelStyle({this.color = black, this.fontFamily = LabelFontFamily.helvetica, this.fontStyle = FontStyle.normal, this.fontWeight = FontWeight.normal});
  LabelStyle.from(LabelStyle src)
      : color = src.color,
        fontFamily = src.fontFamily,
        fontWeight = src.fontWeight,
        fontStyle = src.fontStyle;
}

// ----------------------------------------------------------------------

class PointLabel extends LabelStyle {
  final Offset offset;
  final String text;
  final double sizePixels;
  final double rotation;

  const PointLabel.fromArgs(
      {required this.text,
      required this.offset,
      required this.sizePixels,
      required this.rotation,
      required Color color,
      required LabelFontFamily fontFamily,
      required FontStyle fontStyle,
      required FontWeight fontWeight})
      : super(color: color, fontFamily: fontFamily, fontStyle: fontStyle, fontWeight: fontWeight);

  static PointLabel apply(
          {String text = "",
          Offset offset = const Offset(0.0, 1.0),
          double sizePixels = 24.0,
          double rotation = 0.0,
          Color color = black,
          LabelFontFamily fontFamily = LabelFontFamily.helvetica,
          FontStyle fontStyle = FontStyle.normal,
          FontWeight fontWeight = FontWeight.normal}) =>
      PointLabel.fromArgs(text: text, offset: offset, sizePixels: sizePixels, rotation: rotation, color: color, fontFamily: fontFamily, fontStyle: fontStyle, fontWeight: fontWeight);

  PointLabel.from(PointLabel src)
      : offset = src.offset,
        text = src.text,
        sizePixels = src.sizePixels,
        rotation = src.rotation,
        super.from(src);
}

// ----------------------------------------------------------------------

class DelayedText {
  final String text;
  final Offset origin;
  final double sizePixels;
  final double rotation;
  final LabelStyle textStyle;

  DelayedText(this.text, this.origin, this.sizePixels, this.rotation, this.textStyle);
}

// ----------------------------------------------------------------------

abstract class CanvasRoot {
  CanvasRoot(this.size);

  void draw(Rect drawingArea, Viewport viewport, Function doDraw, {Color? debuggingOutline, bool clip = false});

  final Size size;
}

// ----------------------------------------------------------------------

abstract class DrawOn {
  final Viewport viewport;
  final List<DelayedText> _delayedText;

  DrawOn(this.viewport) : _delayedText = <DelayedText>[];

  double get pixelSize;

  void transform(Matrix4 transformation);

  // ----------------------------------------------------------------------
  // 2D
  // ----------------------------------------------------------------------

  void path(List<Offset> vertices, {Color outline = black, Color fill = transparent, double lineWidthPixels = 1.0, bool close = true});

  // legend

  void point(
      {required Vector3 center,
      required double sizePixels,
      PointShape shape = PointShape.circle,
      Color fill = transparent,
      Color outline = black,
      double outlineWidthPixels = 1.0,
      double rotation = noRotation,
      double aspect = 1.0,
      PointLabel? label});

  void pointOfPlotSpec(Vector3 center, PointPlotSpec plotSpec) {
    point(
        center: center,
        sizePixels: plotSpec.sizePixels,
        shape: plotSpec.shape,
        fill: plotSpec.fill,
        outline: plotSpec.outline,
        outlineWidthPixels: plotSpec.outlineWidthPixels,
        rotation: plotSpec.rotation,
        aspect: plotSpec.aspect,
        label: plotSpec.label);
  }

  void addPointLabel({required Vector3 center, required double sizePixels, required double outlineWidthPixels, required PointLabel label, required bool delayed}) {
    double labelOffset(double labelOffset, double pointSize, double textSize, bool vertical) {
      if (labelOffset >= 1.0) {
        return pointSize * labelOffset + (vertical ? textSize : 0.0);
      } else if (labelOffset > -1.0) {
        return pointSize * labelOffset + (vertical ? (textSize * (labelOffset + 1) / 2) : (textSize * (labelOffset - 1) / 2));
      } else {
        return pointSize * labelOffset - (vertical ? 0.0 : textSize);
      }
    }

    final pointSize = (sizePixels + outlineWidthPixels) * pixelSize / 2;
    final textSize = this.textSize(label.text, sizePixels: label.sizePixels, textStyle: label);
    final Offset offset = Offset(labelOffset(label.offset.dx, pointSize, textSize.width, false), labelOffset(label.offset.dy, pointSize, textSize.height, true));
    delayedText(label.text, Offset(center.x + offset.dx, center.y + offset.dy), sizePixels: label.sizePixels, rotation: label.rotation, textStyle: label);
  }

  void line(Offset p1, Offset p2, {Color outline = black, double lineWidthPixels = 1.0}) {
    path([p1, p2], outline: outline, lineWidthPixels: lineWidthPixels, close: false);
  }

  void arrow(Offset p1, Offset p2,
      {Color outline = black,
      double lineWidthPixels = 1.0,
      Color headOutline = black,
      double headOutlineWidthPixels = 1.0,
      Color headFill = black,
      double headLengthPixels = 15.0,
      double headAspect = 0.5}) {
    final vec = p2 - p1;
    final headRotation = vec.direction + math.pi / 2;
    final headRadiusOffset = vec / vec.distance * (headLengthPixels / 2 + headOutlineWidthPixels) * pixelSize; // account head outline influencing final arrow length
    final headCenter = p2 - headRadiusOffset;
    path([p1, headCenter - headRadiusOffset / 2], outline: outline, lineWidthPixels: lineWidthPixels, close: false);
    point(
        center: Vector3(headCenter.dx, headCenter.dy, 0.0),
        sizePixels: headLengthPixels,
        shape: PointShape.triangle,
        fill: headFill,
        outline: headOutline,
        outlineWidthPixels: headOutlineWidthPixels,
        rotation: headRotation,
        aspect: headAspect);
  }

  void circle({required Offset center, required double size, Color fill = transparent, Color outline = black, double outlineWidthPixels = 1.0, double rotation = noRotation, double aspect = 1.0});

  void rectangle({required Rect rect, Color fill = transparent, Color outline = black, double outlineWidthPixels = 1.0}) {
    path([rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft], fill: fill, outline: outline, lineWidthPixels: outlineWidthPixels, close: true);
  }

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
  });

  void text(String text, Offset origin, {double sizePixels = 20.0, double rotation = 0.0, LabelStyle textStyle = const LabelStyle()});

  /// return size of text in the current scale units
  Size textSize(String text, {double sizePixels = 20.0, LabelStyle textStyle = const LabelStyle()});

  /// Text to be written by drawDelayedText(), i.e. on top of everything
  void delayedText(String text, Offset origin, {double sizePixels = 20.0, double rotation = 0.0, LabelStyle textStyle = const LabelStyle()}) {
    _delayedText.add(DelayedText(text, origin, sizePixels, rotation, textStyle));
  }

  void drawDelayedText() {
    for (var textData in _delayedText) {
      text(textData.text, textData.origin, sizePixels: textData.sizePixels, rotation: textData.rotation, textStyle: textData.textStyle);
    }
  }

  void grid({double step = 1.0, Color color = const Color(0xFFCCCCCC), double lineWidthPixels = 1.0});

  // ----------------------------------------------------------------------
  // 3D
  // ----------------------------------------------------------------------

  void point3d(
      {required Vector3 center,
      required double sizePixels,
      PointShape shape = PointShape.circle,
      Color fill = transparent,
      Color outline = black,
      double outlineWidthPixels = 1.0,
      double rotation = noRotation,
      double aspect = 1.0});
}

// ----------------------------------------------------------------------
