import 'dart:math' as math;
import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

import 'color.dart';
import 'viewport.dart';
import 'error.dart';

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
  ColorAndModifier fill = ColorAndModifier("transparent").copy();
  ColorAndModifier outline = ColorAndModifier("black").copy();
  double outlineWidthPixels = 1.0;
  double rotation = noRotation;
  double aspect = aspectNormal;
  PointLabel? label;
  SerumCircle? serumCircle;
  SerumCoverage? serumCoverage;

  PointPlotSpec();
  PointPlotSpec.from(PointPlotSpec src)
      : shown = src.shown,
        sizePixels = src.sizePixels,
        shape = src.shape,
        fill = src.fill.copy(),
        outline = src.outline.copy(),
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

  const LabelStyle({this.color = const Color(0xFF000000), this.fontFamily = LabelFontFamily.helvetica, this.fontStyle = FontStyle.normal, this.fontWeight = FontWeight.normal});
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
          Color color = const Color(0xFF000000),
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

class SerumCircle {
  Vector3? center;
  final double radius;
  final Color outline;
  final double outlineWidthPixels;
  final Color fill;
  final int dash;
  final Sector? sector;
  final Color? radiusOutline;
  final double? radiusWidthPixels;
  final int? radiusDash;

  SerumCircle(
      {required this.radius,
      required this.outline,
      required this.outlineWidthPixels,
      required this.fill,
      required this.dash,
      this.sector,
      this.radiusOutline,
      this.radiusWidthPixels,
      this.radiusDash});

  @override
  String toString() =>
      "SerumCircle(radius: $radius, outline: $outline, outlineWidth: $outlineWidthPixels, fill: $fill, dash: $dash, sector: $sector, radiusOutline: $radiusOutline, radiusWidth: $radiusWidthPixels, radiusDash: $radiusDash)";

  void draw(DrawOn canvas) {
    // debug(toString());
    if (center != null) {
      if (sector == null) {
        canvas.circleDashed(center: center!, radius: radius, outline: outline, outlineWidthPixels: outlineWidthPixels, fill: fill, dash: dash);
      } else {
        canvas.sectorDashed(
            center: center!,
            radius: radius,
            outline: outline,
            outlineWidthPixels: outlineWidthPixels,
            fill: fill,
            dash: dash,
            sector: sector!,
            radiusOutline: radiusOutline ?? outline,
            radiusWidthPixels: radiusWidthPixels ?? outlineWidthPixels,
            radiusDash: radiusDash ?? dash);
      }
    }
  }
}

// ----------------------------------------------------------------------

class SerumCoverage {
  final double fold;
  final String withinOutline;
  final double withinOutlineWidthPixels;
  final String withinFill;
  final String outsideOutline;
  final double outsideOutlineWidthPixels;
  final String outsideFill;

  SerumCoverage(
      {required this.fold,
      required this.withinOutline,
      required this.withinOutlineWidthPixels,
      required this.withinFill,
      required this.outsideOutline,
      required this.outsideOutlineWidthPixels,
      required this.outsideFill});

  @override
  String toString() =>
      "SerumCoverage(fold: $fold, within: {outline: $withinOutline, outlineWidth: $withinOutlineWidthPixels, fill: $withinFill}, outside: {outline: $outsideOutline, outlineWidth: $outsideOutlineWidthPixels, fill: $outsideFill})";
}

// ======================================================================

abstract class CanvasRoot {
  CanvasRoot(this.size);

  void draw(Rect drawingArea, Viewport viewport, Function doDraw, {Color? debuggingOutline, bool clip = false});

  final Size size;
}

// ----------------------------------------------------------------------

class Sector {
  final double begin;
  final double angle;

  Sector(double bb, double an)
      : begin = an >= 0.0 ? bb : bb + an,
        angle = an.abs();
  const Sector.wholeCircle()
      : begin = 0.0,
        angle = math.pi * 2.0;
  Sector.fromTwoAngles(double a1, double a2)
      : begin = a2 >= a1 ? a1 : a2,
        angle = (a2 - a1).abs();

  bool get wholeCircle => angle >= math.pi * 2.0;
  double get end => begin + angle;
}

// ----------------------------------------------------------------------

abstract class DrawOn {
  final Viewport viewport;
  final List<DelayedText> _delayedText = <DelayedText>[];
  final List<SerumCircle> _delayedSerumCircle = <SerumCircle>[];

  DrawOn(this.viewport);

  double get pixelSize;

  void transform(Matrix4 transformation);

  // ----------------------------------------------------------------------
  // 2D
  // ----------------------------------------------------------------------

  void path(List<Offset> vertices, {Color outline = const Color(0xFF000000), Color fill = const Color(0x00000000), double lineWidthPixels = 1.0, bool close = true});

  void point(
      {required Vector3 center,
      required double sizePixels,
      PointShape shape = PointShape.circle,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidthPixels = 1.0,
      double rotation = noRotation,
      double aspect = 1.0,
      PointLabel? label});

  void pointOfPlotSpec(Vector3 center, PointPlotSpec plotSpec) {
    point(
        center: center,
        sizePixels: plotSpec.sizePixels,
        shape: plotSpec.shape,
        fill: plotSpec.fill.color,
        outline: plotSpec.outline.color,
        outlineWidthPixels: plotSpec.outlineWidthPixels,
        rotation: plotSpec.rotation,
        aspect: plotSpec.aspect,
        label: plotSpec.label);
    delayedSerumCircle(center, plotSpec.serumCircle);
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

  void line(Offset p1, Offset p2, {Color outline = const Color(0xFF000000), double lineWidthPixels = 1.0}) {
    path([p1, p2], outline: outline, lineWidthPixels: lineWidthPixels, close: false);
  }

  void lineDashed(Offset p1, Offset p2, {Color outline = const Color(0xFF000000), double lineWidthPixels = 1.0, int dash = 10}) {
    final dxy = (p2 - p1) / (dash + 0.5);
    for (double dno = 0.0; dno <= dash; ++dno) {
      path([p1 + dxy * dno, p1 + dxy * (dno + 0.5)], outline: outline, lineWidthPixels: lineWidthPixels, close: false);
    }
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
        center: Vector3(headCenter.dx, headCenter.dy, 0.0),
        sizePixels: headLengthPixels,
        shape: PointShape.triangle,
        fill: headFill,
        outline: headOutline,
        outlineWidthPixels: headOutlineWidthPixels,
        rotation: headRotation,
        aspect: headAspect);
  }

  void circle(
      {required Vector3 center,
      required double radius,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidthPixels = 1.0,
      double rotation = noRotation,
      double aspect = 1.0});

  void arc(
      {required Vector3 center,
      required double radius,
      required Sector sector, // 0.0 is upright
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidthPixels = 1.0});

  void circleDashed(
      {required Vector3 center,
      required double radius,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidthPixels = 1.0,
      double rotation = noRotation,
      double aspect = 1.0,
      required int dash}) {
    if (dash == 0 || aspect != 1.0) {
      // no dash
      if (dash != 0) warning("dashed circle with aspect $aspect is not supported, solid circle is drawn");
      circle(center: center, radius: radius, fill: fill, outline: outline, outlineWidthPixels: outlineWidthPixels, rotation: rotation, aspect: aspect);
    } else {
      sectorDashed(
          center: center, radius: radius, fill: fill, outline: outline, outlineWidthPixels: outlineWidthPixels, dash: dash, sector: const Sector.wholeCircle(), radiusWidthPixels: 0.0, radiusDash: 0);
    }
  }

  void rectangle({required Rect rect, Color fill = const Color(0x00000000), Color outline = const Color(0xFF000000), double outlineWidthPixels = 1.0}) {
    path([rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft], fill: fill, outline: outline, lineWidthPixels: outlineWidthPixels, close: true);
  }

  void sector(
      {required Vector3 center,
      required double radius,
      required Sector sector, // 0.0 is upright
      Color fill = const Color(0x00000000),
      Color outlineCircle = const Color(0xFF000000),
      double outlineCircleWidthPixels = 1.0,
      Color outlineRadius = const Color(0xFF000000),
      double outlineRadiusWidthPixels = 1.0}) {
    arc(center: center, radius: radius, sector: sector, fill: fill, outline: outlineCircle, outlineWidthPixels: outlineCircleWidthPixels);
    if (outlineRadiusWidthPixels > 0 && outlineRadius.alpha > 0) {
      line(Offset(center.x, center.y), Offset(center.x + math.sin(sector.begin) * radius, center.y - math.cos(sector.begin) * radius),
          outline: outlineRadius, lineWidthPixels: outlineRadiusWidthPixels);
      line(Offset(center.x, center.y), Offset(center.x + math.sin(sector.end) * radius, center.y - math.cos(sector.end) * radius), outline: outlineRadius, lineWidthPixels: outlineRadiusWidthPixels);
    }
  }

  void sectorDashed(
      {required Vector3 center,
      required double radius,
      required Sector sector, // 0.0 is upright
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidthPixels = 1.0,
      required int dash,
      Color radiusOutline = const Color(0xFF000000),
      double radiusWidthPixels = 1.0,
      required int radiusDash}) {
    if (dash == 0) {
      if (sector.wholeCircle) {
        circle(center: center, radius: radius, fill: fill, outline: outline, outlineWidthPixels: outlineWidthPixels);
      } else {
        this.sector(
            center: center,
            radius: radius,
            sector: sector,
            fill: fill,
            outlineCircle: outline,
            outlineCircleWidthPixels: outlineWidthPixels,
            outlineRadius: radiusOutline,
            outlineRadiusWidthPixels: radiusWidthPixels);
      }
    } else {
      final gap = math.pi / dash / 2;
      final singleAngle = (math.pi * 2.0) / dash;
      final dashes = (sector.angle / singleAngle).round();
      // fill
      if (fill.alpha > 0.0) {
        this.sector(center: center, radius: radius, sector: sector, fill: fill, outlineCircle: const Color(0x00000000), outlineCircleWidthPixels: 0.0, outlineRadiusWidthPixels: 0.0);
      }
      // dashed circle outline
      for (int i = 0; i < dashes; i++) {
        arc(
            center: center,
            radius: radius,
            sector: Sector(sector.begin + gap + singleAngle * i, singleAngle - gap * 2.0),
            fill: const Color(0x00000000),
            outline: outline,
            outlineWidthPixels: outlineWidthPixels);
      }
      // dashed radius lines
      if (radiusWidthPixels > 0.0 && radiusOutline.alpha > 0.0) {
        final lineDash = dash ~/ 7;
        lineDashed(Offset(center.x, center.y), Offset(center.x + math.sin(sector.begin) * radius, center.y - math.cos(sector.begin) * radius),
            outline: radiusOutline, lineWidthPixels: radiusWidthPixels, dash: lineDash);
        lineDashed(Offset(center.x, center.y), Offset(center.x + math.sin(sector.end) * radius, center.y - math.cos(sector.end) * radius),
            outline: radiusOutline, lineWidthPixels: radiusWidthPixels, dash: lineDash);
      }
    }
  }

  void text(String text, Offset origin, {double sizePixels = 20.0, double rotation = 0.0, LabelStyle textStyle = const LabelStyle()});

  /// return size of text in the current scale units
  Size textSize(String text, {double sizePixels = 20.0, LabelStyle textStyle = const LabelStyle()});

  // ----------------------------------------------------------------------

  /// Text to be written by drawDelayed(), i.e. on top of everything
  void delayedText(String text, Offset origin, {double sizePixels = 20.0, double rotation = 0.0, LabelStyle textStyle = const LabelStyle()}) {
    _delayedText.add(DelayedText(text, origin, sizePixels, rotation, textStyle));
  }

  void delayedSerumCircle(Vector3 center, SerumCircle? serumCircle) {
    if (serumCircle != null) {
      serumCircle.center = center;
      _delayedSerumCircle.add(serumCircle);
    }
  }

  void drawDelayed() {
    for (var serumCircle in _delayedSerumCircle) {
      serumCircle.draw(this);
    }
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
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidthPixels = 1.0,
      double rotation = noRotation,
      double aspect = 1.0});
}

// ----------------------------------------------------------------------
