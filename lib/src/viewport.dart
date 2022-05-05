import 'package:vector_math/vector_math_64.dart';

// ----------------------------------------------------------------------

typedef Layout = List<Vector3?>;

// ----------------------------------------------------------------------

class Viewport {
  Viewport.hullLayout(Layout layout) {
    var present = layout.where(notNull).cast<Vector3>();
    if (present.isNotEmpty) {
      _aabb = Aabb3.centerAndHalfExtents(present.elementAt(0), Vector3.all(0.0));
      present.skip(1).forEach((elt) => _aabb.hullPoint(elt));
    } else {
      _aabb = Aabb3();
    }
  }

  double get width => _aabb.max.x - _aabb.min.x;
  double get height => _aabb.max.y - _aabb.min.y;
  double get left => _aabb.min.x;
  double get right => _aabb.max.x;
  double get top => _aabb.min.y;
  double get bottom => _aabb.max.y;

  // /// Move center of this viewport to Vector3.all(0.0) and adjust points in the layout accordingly
  // void moveCenterToOrigin(Layout layout) {
  //   for (var ind = 0; ind < layout.length; ++ind) {
  //     if (layout[ind] != null) {
  //       layout[ind] = layout[ind]! - _aabb.center;
  //     }
  //   }
  //   _aabb.setCenterAndHalfExtents(Vector3.all(0.0), (_aabb.max - _aabb.min) / 2);
  // }

  /// extend viewport so it's corners are at the whole number vectors, then re-center layout within this viewport
  void roundAndRecenter(Layout layout) {
    final roundedSize = (_aabb.max - _aabb.min)..ceil();
    final roundedHalfSize = roundedSize / 2;
    final roundedHalfSizeCeiled = Vector3.copy(roundedSize)..ceil();
    final origCenter = _aabb.center;
    _aabb.setCenterAndHalfExtents(roundedHalfSizeCeiled - roundedHalfSize, roundedHalfSize);
    final adjust = _aabb.center - origCenter;
    for (var ind = 0; ind < layout.length; ++ind) {
      if (layout[ind] != null) {
        layout[ind] = layout[ind]! + adjust;
      }
    }
    // print("Viewport.roundAndRecenter ${toString()}");
  }

  static bool notNull(Vector3? elt) => elt != null;

  String toString() => "Viewport[$left, $top, $width, $height]";

  // ----------------------------------------------------------------------

  late final Aabb3 _aabb;
}

// ----------------------------------------------------------------------
