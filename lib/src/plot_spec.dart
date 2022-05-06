import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

import 'chart.dart';
import 'draw_on.dart';
import 'color.dart';
import 'error.dart';
import 'cast.dart';

// ----------------------------------------------------------------------

abstract class PlotSpec {
  String title();
  List<int> drawingOrder();
  PointPlotSpec operator [](int pointNo);
  int priority();
  PlotTitle plotTitle();
  Legend legend();

  Color colorFromSpec(String? spec, Color dflt) {
    if (spec != null && spec.isNotEmpty) {
      spec = spec.toUpperCase();
      if (spec[0] == "#") {
        if (spec.length == 7) return Color(int.parse(spec.substring(1, 7), radix: 16) + 0xFF000000);
        // if (spec.length == 4) return Color(int.parse(spec.substring(1, 4), radix: 16) + 0xFF000000);
        if (spec.length == 9) return Color(int.parse(spec.substring(1, 7), radix: 16));
      } else if (spec == "T" || spec == "TRANSPARENT") {
        return transparent;
      }
    }
    return dflt;
  }
}

// ----------------------------------------------------------------------

class _DefaultDrawingOrder {
  void makeDefaultDrawingOrder(Chart chart, Projection projection) {
    bool hasCoord(int pointNo) => projection.layout[pointNo] != null;
    ddoSera = Iterable<int>.generate(chart.sera.length, (srNo) => srNo + chart.antigens.length).where(hasCoord).toList();
    ddoReferenceAntigens = chart.referenceAntigens().where(hasCoord).toList();
    ddoTestAntigens = Iterable<int>.generate(chart.antigens.length).where((agNo) => !ddoReferenceAntigens.contains(agNo)).where(hasCoord).toList();
  }

  late final List<int> ddoSera, ddoReferenceAntigens, ddoTestAntigens;
}

// ----------------------------------------------------------------------

abstract class _DefaultPointSpecs {
  void initDefaultPointSpecs({required Color testAntigenFill, required Color outline}) {
    referenceCell = PointPlotSpec.referenceCell(outline);
    referenceEgg = PointPlotSpec.referenceEgg(outline);
    referenceReassortant = PointPlotSpec.referenceReassortant(outline);
    testCell = PointPlotSpec.testCell(testAntigenFill, outline);
    testEgg = PointPlotSpec.testEgg(testAntigenFill, outline);
    testReassortant = PointPlotSpec.testReassortant(testAntigenFill, outline);
    serumCell = PointPlotSpec.serumCell(outline);
    serumEgg = PointPlotSpec.serumEgg(outline);
    serumReassortant = PointPlotSpec.serumReassortant(outline);
  }

  void makeDefaultPointSpecs({required Chart chart, required Function isReferenceAntigen}) {
    chart.antigens.asMap().forEach((agNo, antigen) {
      if (isReferenceAntigen(agNo)) {
        if (antigen.isReassortant) {
          _addPointSpec(referenceReassortant);
        } else if (antigen.isEgg) {
          _addPointSpec(referenceEgg);
        } else {
          _addPointSpec(referenceCell);
        }
      } else {
        if (antigen.isReassortant) {
          _addPointSpec(testReassortant);
        } else if (antigen.isEgg) {
          _addPointSpec(testEgg);
        } else {
          _addPointSpec(testCell);
        }
      }
    });
    chart.sera.asMap().forEach((srNo, serum) {
      if (serum.isReassortant) {
        _addPointSpec(serumReassortant);
      } else if (serum.isEgg) {
        _addPointSpec(serumEgg);
      } else {
        _addPointSpec(serumCell);
      }
    });
  }

  bool _addPointSpecByCloning();

  void _addPointSpec(PointPlotSpec spec) {
    if (_addPointSpecByCloning()) {
      pointSpec.add(PointPlotSpec.from(spec));
    } else {
      pointSpec.add(spec);
    }
  }

  final List<PointPlotSpec> pointSpec = [];

  late final PointPlotSpec referenceCell, referenceEgg, referenceReassortant, testCell, testEgg, testReassortant, serumCell, serumEgg, serumReassortant;
}

// ----------------------------------------------------------------------

class PlotSpecDefault extends PlotSpec with _DefaultDrawingOrder, _DefaultPointSpecs {
  PlotSpecDefault(this._chart, this._projection) {
    initDefaultPointSpecs(testAntigenFill: green, outline: black);
    makeDefaultDrawingOrder(_chart, _projection);
    makeDefaultPointSpecs(chart: _chart, isReferenceAntigen: (agNo) => ddoReferenceAntigens.contains(agNo));
  }

  @override
  String title() => "Default";

  @override
  List<int> drawingOrder() {
    return ddoSera + ddoReferenceAntigens + ddoTestAntigens;
  }

  @override
  PointPlotSpec operator [](int pointNo) => pointSpec[pointNo];

  @override
  int priority() => 999;

  @override
  bool _addPointSpecByCloning() => false;

  @override
  PlotTitle plotTitle() => PlotTitle();

  @override
  Legend legend() => Legend();

  // ----------------------------------------------------------------------

  final Chart _chart;
  final Projection _projection;
}

// ----------------------------------------------------------------------

class PlotSpecSemantic extends PlotSpec with _DefaultDrawingOrder, _DefaultPointSpecs {
  PlotSpecSemantic(this._chart, this._projection, this._name, this._data) {
    initDefaultPointSpecs(testAntigenFill: gray80, outline: gray80);
    makeDefaultDrawingOrder(_chart, _projection);
    _drawingOrder = ddoSera + ddoReferenceAntigens + ddoTestAntigens;
    makeDefaultPointSpecs(chart: _chart, isReferenceAntigen: (agNo) => ddoReferenceAntigens.contains(agNo));
    apply(_data["A"] ?? []);
  }

  @override
  String title() => _data["t"] ?? _name;

  @override
  List<int> drawingOrder() => _drawingOrder;

  @override
  PointPlotSpec operator [](int pointNo) => pointSpec[pointNo];

  @override
  int priority() => _data["z"] ?? 0;

  @override
  bool _addPointSpecByCloning() => true;

  @override
  PlotTitle plotTitle() => PlotTitle(_data["T"] ?? {});

  @override
  Legend legend() => Legend(_data["L"] ?? {});

  void apply(List<dynamic> data, [int recursionLevel = 1]) {
    if (recursionLevel > 10) throw FormatError("PlotSpecSemantic.apply: too deep recursion");
    for (final en in data) {
      applyEntry(en as Map<String, dynamic>, recursionLevel);
    }
  }

  void applyEntry(Map<String, dynamic> entry, int recursionLevel) {
    if (entry["R"] != null) {
      // reference to another style
      apply(_chart.data["c"]["R"][entry["R"]]?["A"] ?? [], recursionLevel + 1);
    }
    final points = selectPoints(entry["T"], entry["A"]);
    if (points.isNotEmpty) {
      for (final pointNo in points) {
        modifyPointPlotSpec(pointSpec[pointNo], entry);
      }
      raiseLowerPoints(entry["D"], points);
    }
  }

  List<int> selectPoints(Map<String, dynamic>? selector, dynamic antigensOnly) {
    bool match(Map<String, dynamic> semantic) {
      return selector != null ? semanticMatch(selector, semantic) : true; // select all if selector absent
    }

    final selected = <int>[];
    if (castToBool(antigensOnly, ifNull: true)) {
      selected.addAll(Iterable<int>.generate(_chart.antigens.length).where((agNo) => match(_chart.antigens[agNo].semantic))); //
    }
    if (!castToBool(antigensOnly, ifNull: false)) {
      selected.addAll(Iterable<List<int>>.generate(_chart.sera.length, (srNo) => [srNo, srNo + _chart.antigens.length]).where((ref) => match(_chart.sera[ref[0]].semantic)).map((ref) => ref[1]));
    }
    return selected;
  }

  void raiseLowerPoints(String? raiseLower, List<int> points) {
    if (raiseLower != null) {
      final List<int> keep = [], move = [];
      for (final pnt in _drawingOrder) {
        if (points.contains(pnt)) {
          move.add(pnt);
        } else {
          keep.add(pnt);
        }
      }
      if (raiseLower == "r") {
        _drawingOrder = keep + move;
      } else {
        _drawingOrder = move + keep;
      }
    }

    switch (raiseLower) {
      case "r":
        break;
      case "l":
        break;
      default:
        break;
    }
  }

  static void modifyPointPlotSpec(PointPlotSpec spec, Map<String, dynamic> mod) {
    mod.forEach((modKey, modValue) {
      switch (modKey) {
        case "S":
          spec.shape = pointShapeFromString(modValue);
          break;
        case "F":
          spec.fill = NamedColor.fromString(modValue);
          break;
        case "O":
          spec.outline = NamedColor.fromString(modValue);
          break;
        case "o":
          spec.outlineWidthPixels = modValue.toDouble();
          break;
        case "s":
          spec.sizePixels = modValue.toDouble();
          break;
        case "r":
          spec.rotation = modValue.toDouble();
          break;
        case "a":
          spec.aspect = modValue.toDouble();
          break;
        case "-":
          spec.shown = !(modValue as bool);
          break;
      }
    });
  }

  static PointShape pointShapeFromString(String src) {
    switch (src[0].toUpperCase()) {
      case "C":
        return PointShape.circle;
      case "B":
        return PointShape.box;
      case "T":
        return PointShape.triangle;
      case "E":
        return PointShape.egg;
      case "U":
        return PointShape.uglyegg;
    }
    return PointShape.circle;
  }

  final Chart _chart;
  final Projection _projection;

  final String _name;
  final Map<String, dynamic> _data;

  late List<int> _drawingOrder;
  final List<PointPlotSpec> pointSpec = [];
}

// ----------------------------------------------------------------------

abstract class _TitleLegendCommon {
  Map<String, dynamic> get data;

  bool shown() => data["-"] == null || !data["-"];

  Vector3 offset() {
    final offs = data["p"];
    if (offs == null) return Vector3.zero();
    return Vector3(offs[0].toDouble(), offs[1].toDouble(), 0.0);
  }

  // area
  List<double> padding() => data["A"]?["P"]?.map((val) => val.toDouble()) ?? <double>[0.0, 0.0, 0.0, 0.0];
  String borderColor() => data["A"]?["O"] ?? "black";
}

// ----------------------------------------------------------------------

class PlotTitle with _TitleLegendCommon {
  PlotTitle([this._data = const <String, dynamic>{}]);

  @override
  String toString() => "PlotTitle($_data)";

  @override
  Map<String, dynamic> get data => _data;

  // area
  double borderWidth() => data["A"]?["o"] ?? 0.0;
  String backgroundColor() => data["A"]?["F"] ?? "transparent";

  final Map<String, dynamic> _data;
}

// |             |     |      | "t" |     | str                              | title text                                                                                                                                                     |
// |             |     |      | "f" |     | str                              | font face                                                                                                                                                      |
// |             |     |      | "S" |     | str                              | font slant: "normal" (default), "italic"                                                                                                                       |
// |             |     |      | "W" |     | str                              | font weight: "normal" (default), "bold"                                                                                                                        |
// |             |     |      | "s" |     | float                            | label size, default 1.0                                                                                                                                        |
// |             |     |      | "c" |     | color                            | label color, default: "black"                                                                                                                                  |

// ----------------------------------------------------------------------

class Legend with _TitleLegendCommon {
  Legend([this._data = const <String, dynamic>{}]);

  @override
  String toString() => "Legend($_data)";

  @override
  Map<String, dynamic> get data => _data;

  // area
  double borderWidth() => data["A"]?["o"] ?? 1.0;
  String backgroundColor() => data["A"]?["F"] ?? "white";

  final Map<String, dynamic> _data;
}

// |             |     |      | "c" |     | "tl"                             | corner or center of the plot: t - top, c - center, b - bottom, l -left, r - right                                                                              |
// |             |     |      | "C" |     | bool                             | add counter                                                                                                                                                    |
// |             |     |      | "S" |     | 10.0                             | point size                                                                                                                                                     |
// |             |     |      | "T" |     | object                           | title -> TextData                                                                                                                                              |
// |             |     |      |     | "t" | str                              | title text                                                                                                                                                     |
// |             |     |      |     | "f" | str                              | font face                                                                                                                                                      |
// |             |     |      |     | "S" | str                              | font slant: "normal" (default), "italic"                                                                                                                       |
// |             |     |      |     | "W" | str                              | font weight: "normal" (default), "bold"                                                                                                                        |
// |             |     |      |     | "s" | float                            | label size, default 1.0                                                                                                                                        |
// |             |     |      |     | "c" | color                            | label color, default: "black"                                                                                                                                  |
// |             |     |      |     | "A" | object                           | plot spec of the area  -> AreaData                                                                                                                             |
// |             |     |      | "z" |     | bool                             | show rows with zero count                                                                                                                                      |

// ----------------------------------------------------------------------

class PlotSpecLegacy extends PlotSpec {
  PlotSpecLegacy(this._chart) : _data = _chart.data["c"]["p"] {
    for (final entry in _data["P"] ?? []) {
      final spec = PointPlotSpec();
      if (!(entry["+"] ?? true)) spec.shown = false;
      spec.fill = colorFromSpec(entry["F"], transparent);
      spec.outline = colorFromSpec(entry["O"], black);
      spec.outlineWidthPixels = entry["o"]?.toDouble() ?? 1.0;
      spec.sizePixels = (entry["s"]?.toDouble() ?? 1.0) * 10.0;
      switch (entry["S"]?.toUpperCase()[0] ?? "C") {
        case "C":
          spec.shape = PointShape.circle;
          break;
        case "B":
          spec.shape = PointShape.box;
          break;
        case "T":
          spec.shape = PointShape.triangle;
          break;
        case "E":
          spec.shape = PointShape.egg;
          break;
        case "U":
          spec.shape = PointShape.uglyegg;
          break;
      }
      spec.rotation = entry["r"]?.toDouble() ?? noRotation;
      spec.aspect = entry["a"]?.toDouble() ?? aspectNormal;
      // label
      _specs.add(spec);
    }
  }

  @override
  String title() => "Legacy";

  @override
  List<int> drawingOrder() {
    return _data["d"]?.cast<int>() ?? [];
  }

  @override
  PointPlotSpec operator [](int pointNo) => _specs[_data["p"][pointNo]];

  @override
  int priority() => 998;

  @override
  PlotTitle plotTitle() => PlotTitle();

  @override
  Legend legend() => Legend();

  final Chart _chart;
  final Map<String, dynamic> _data;
  final List<PointPlotSpec> _specs = [];
}

// ----------------------------------------------------------------------
