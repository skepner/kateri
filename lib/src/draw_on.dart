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

abstract class DrawOn {
  double get pixelSize;

  // ----------------------------------------------------------------------
  // 2D
  // ----------------------------------------------------------------------

  void path(List<Offset> vertices, {Color outline = const Color(0xFF000000), Color fill = const Color(0x00000000), double lineWidthPixels = 1.0, bool close = true});

  // sector
  // rectangle (filled) -> path
  // text
  // label
  // legend

  void point(
      {required Offset center,
      required double sizePixels,
      PointShape shape = PointShape.circle,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidthPixels = 1.0,
      double rotation = NoRotation,
      double aspect = 1.0});

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
