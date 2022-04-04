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
  void grid({double step = 1.0, Color color = const Color(0xFFCCCCCC), double lineWidthPixels = 1.0});

  // ----------------------------------------------------------------------
  // 2D
  // ----------------------------------------------------------------------

  void line(Offset p1, Offset p2, {Color color = const Color(0xFF000000), double lineWidthPixels = 1.0}) {
    path([p1, p2], color: color, lineWidthPixels: lineWidthPixels, close: false);
  }

  void path(List<Offset> vertices, {Color color = const Color(0xFF000000), double lineWidthPixels = 1.0, bool close = true});

  // arrow
  // circle
  // sector
  // rectangle (filled)
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
