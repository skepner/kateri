import 'dart:ui';
import 'dart:math' as math;

enum PointShape { circle, box, triangle, egg, uglyegg }

const NoRotation = 0.0;
const RotationRight30 = math.pi / 6;
const RotationRight45 = math.pi / 4;
const RotationRight60 = math.pi / 3;
const RotationLeft30 = - math.pi / 6;
const RotationLeft45 = - math.pi / 4;
const RotationLeft60 = - math.pi / 3;

abstract class DrawOn {
  void point(Offset center, double size,
      {PointShape shape = PointShape.circle,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidth = 1.0,
      double rotation = NoRotation,
      double aspect = 1.0});
  void point3d(Offset center, double size,
      {PointShape shape = PointShape.circle,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidth = 1.0,
      double rotation = NoRotation,
      double aspect = 1.0});
}
