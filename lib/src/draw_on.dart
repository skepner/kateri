import 'dart:ui';

enum PointShape { circle, box, egg, uglyegg }

abstract class DrawOn {
  void point(Offset center, double size,
    {PointShape shape = PointShape.circle,
      Color fill = const Color(0x00000000),
      Color outline = const Color(0xFF000000),
      double outlineWidth = 1.0,
      double rotation = 0.0,
      double aspect = 1.0});
}
