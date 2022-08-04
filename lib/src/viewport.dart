import 'package:vector_math/vector_math_64.dart';

// ----------------------------------------------------------------------

typedef Layout = List<Vector3?>;

// ----------------------------------------------------------------------

class Viewport {
  Viewport.originSizeList(List<double> values) {
    switch (values.length) {
      case 4: // left, top, width, height
        _aabb = Aabb3.minMax(Vector3(values[0], values[1], 0.0), Vector3(values[0] + values[2], values[1] + values[3], 0.0));
        break;
      case 3: // left, top, width, height=width
        _aabb = Aabb3.minMax(Vector3(values[0], values[1], 0.0), Vector3(values[0] + values[2], values[1] + values[2], 0.0));
        break;
      default:
        throw FormatException("cannot infer viewport from $values");
    }
  }

  Viewport.hullLayout(Layout layout) {
    var present = layout.where(notNull).cast<Vector3>();
    if (present.isNotEmpty) {
      _aabb = Aabb3.centerAndHalfExtents(present.elementAt(0), Vector3.all(0.0));
      present.skip(1).forEach((elt) => _aabb.hullPoint(elt));
    } else {
      _aabb = Aabb3();
    }
    _layoutCenter = _aabb.center;
  }

  double get width => _aabb.max.x - _aabb.min.x;
  double get height => _aabb.max.y - _aabb.min.y;
  double get left => _aabb.min.x;
  double get right => _aabb.max.x;
  double get centerX => (_aabb.min.x + _aabb.max.x) / 2;
  double get top => _aabb.min.y;
  double get bottom => _aabb.max.y;
  double get centerY => (_aabb.min.y + _aabb.max.y) / 2;

  // Vector3? get layoutCenter => _layoutCenter; // for get_vieport command for sig pages mapi data

  List<double>? layoutCenter2() {
    // for get_vieport command for sig pages mapi data
    if (_layoutCenter != null) {
      return [_layoutCenter!.x, _layoutCenter!.y];
    } else {
      return null;
    }
  }

  double aspectRatio() => width / height;

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
  void roundAndRecenter(Layout layout, int numberOfDimensions) {
    final roundedSize = (_aabb.max - _aabb.min + Vector3.all(1.0))..ceil();
    final roundedHalfSize = roundedSize / 2;
    final roundedHalfSizeCeiled = Vector3.copy(roundedSize)..ceil();
    final origCenter = _aabb.center;
    _aabb.setCenterAndHalfExtents(roundedHalfSizeCeiled - roundedHalfSize, roundedHalfSize);

    var adjust = _aabb.center - origCenter;
    switch (numberOfDimensions) {
      case 1:
        adjust.y = 0.0;
        adjust.z = 0.0;
        break;
      case 2:
        adjust.z = 0.0;
        break;
    }

    for (final element in layout) {
      element?.setFrom(element + adjust);
    }

    // for (var ind = 0; ind < layout.length; ++ind) {
    //   if (layout[ind] != null) {
    //     layout[ind] = layout[ind]! + adjust;
    //   }
    // }
    // print("Viewport.roundAndRecenter ${toString()}");
  }

  static bool notNull(Vector3? elt) => elt != null;

  String toString() => "Viewport[$left, $top, $width, $height]";
  List<double> toListDouble() => [left, top, width, height];

  // ----------------------------------------------------------------------

  late final Aabb3 _aabb;
  Vector3? _layoutCenter; // for get_vieport command for sig pages mapi data
}

// ----------------------------------------------------------------------
