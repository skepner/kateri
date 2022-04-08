import 'dart:ui';
import 'dart:math' as math;

enum PointShape { circle, box, triangle, egg, uglyegg }

const NoRotation = 0.0;
const RotationRight30 = math.pi / 6;
const RotationRight45 = math.pi / 4;
const RotationRight60 = math.pi / 3;
const RotationLeft30 = -math.pi / 6;
const RotationLeft45 = -math.pi / 4;
const RotationLeft60 = -math.pi / 3;

// ----------------------------------------------------------------------

enum LabelFontFamily { monospace, sansSerif, serif, helvetica, courier, times /* , symbol, zapf */ }

class LabelStyle {
  final Color color;
  final LabelFontFamily fontFamily;
  final FontWeight fontWeight;
  final FontStyle fontStyle;

  const LabelStyle({this.color = const Color(0xFF000000), this.fontFamily = LabelFontFamily.helvetica, this.fontStyle = FontStyle.normal, this.fontWeight = FontWeight.normal});
}

// ----------------------------------------------------------------------

class PointLabel extends LabelStyle {
  final Offset offset;
  final String text;
  final double sizePixels;
  final double rotation;

  const PointLabel(this.text,
      {this.offset = const Offset(0.0, 1.0),
      this.sizePixels = 24,
      this.rotation = 0.0,
      Color color = const Color(0xFF000000),
      LabelFontFamily fontFamily = LabelFontFamily.helvetica,
      FontStyle fontStyle = FontStyle.normal,
      FontWeight fontWeight = FontWeight.normal})
      : super(color: color, fontFamily: fontFamily, fontStyle: fontStyle, fontWeight: fontWeight);
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

  void draw(Rect drawingArea, Rect viewport, Function doDraw);

  final Size size;
}

// ----------------------------------------------------------------------

abstract class DrawOn {
  final Rect viewport;
  final List<DelayedText> _delayedText;

  DrawOn(this.viewport) : _delayedText = <DelayedText>[];

  double get pixelSize;

  // ----------------------------------------------------------------------
  // 2D
  // ----------------------------------------------------------------------

  void path(List<Offset> vertices, {Color outline = const Color(0xFF000000), Color fill = const Color(0x00000000), double lineWidthPixels = 1.0, bool close = true});

  // legend

  void point(
      {required Offset center,
      required double sizePixels,
      PointShape shape = PointShape.circle,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidthPixels = 1.0,
      double rotation = NoRotation,
      double aspect = 1.0,
      PointLabel? label});

  void addPointLabel({required Offset center, required double sizePixels, required double outlineWidthPixels, required PointLabel label, required bool delayed}) {
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
    delayedText(label.text, center + offset, sizePixels: label.sizePixels, rotation: label.rotation, textStyle: label);
  }

  void line(Offset p1, Offset p2, {Color outline = const Color(0xFF000000), double lineWidthPixels = 1.0}) {
    path([p1, p2], outline: outline, lineWidthPixels: lineWidthPixels, close: false);
  }

  void arrow(Offset p1, Offset p2,
      {Color outline = const Color(0xFF000000),
      double lineWidthPixels = 1.0,
      Color headOutline = const Color(0xFF000000),
      double headOutlineWidthPixels = 1.0,
      Color headFill = const Color(0xFF000000),
      double headLengthPixels = 15.0,
      double headAspect = 0.5}) {
    final vec = p2 - p1;
    final headRotation = vec.direction + math.pi / 2;
    final headRadiusOffset = vec / vec.distance * (headLengthPixels / 2 + headOutlineWidthPixels) * pixelSize; // account head outline influencing final arrow length
    final headCenter = p2 - headRadiusOffset;
    path([p1, headCenter - headRadiusOffset / 2], outline: outline, lineWidthPixels: lineWidthPixels, close: false);
    point(
        center: headCenter,
        sizePixels: headLengthPixels,
        shape: PointShape.triangle,
        fill: headFill,
        outline: headOutline,
        outlineWidthPixels: headOutlineWidthPixels,
        rotation: headRotation,
        aspect: headAspect);
  }

  void circle(
      {required Offset center,
      required double size,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidthPixels = 1.0,
      double rotation = NoRotation,
      double aspect = 1.0});

  void rectangle({required Rect rect, Color fill = const Color(0x00000000), Color outline = const Color(0xFF000000), double outlineWidthPixels = 1.0}) {
    path([rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft], fill: fill, outline: outline, lineWidthPixels: outlineWidthPixels, close: true);
  }

  void sector({
    required Offset center,
    required double radius,
    required double angle,
    Color fill = const Color(0x00000000),
    Color outlineCircle = const Color(0xFF000000),
    double outlineCircleWidthPixels = 1.0,
    Color outlineRadius = const Color(0xFF000000),
    double outlineRadiusWidthPixels = 1.0,
    double rotation = NoRotation, // NoRotation - first radius in upright
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
      {required Offset center,
      required double sizePixels,
      PointShape shape = PointShape.circle,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidthPixels = 1.0,
      double rotation = NoRotation,
      double aspect = 1.0});
}

// ----------------------------------------------------------------------
