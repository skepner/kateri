import 'dart:ui';
import 'dart:convert';
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
  Legend legend() => Legend(_data["L"] ?? {}, _legendRows);

  void apply(List<dynamic> data, [int recursionLevel = 1]) {
    if (recursionLevel > 10) throw FormatError("PlotSpecSemantic.apply: too deep recursion");
    for (final en in data) {
      applyEntry(en as Map<String, dynamic>, recursionLevel);
    }
    _legendRows.sort((e1, e2) => e1.priority.compareTo(e2.priority));
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
    final legend = entry["L"];
    if (legend != null) {
      var point = PointPlotSpec();
      if (points.isNotEmpty) {
        point = pointSpec[points[0]];
      } else {
        modifyPointPlotSpec(point, entry);
      }
      _legendRows.add(LegendRow(text: legend["t"] ?? "", point: point, count: points.length, priority: legend["p"] ?? 0));
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
  final List<LegendRow> _legendRows = [];
}

// ----------------------------------------------------------------------

class PlotTitle {
  PlotTitle([this.data = const <String, dynamic>{}]);

  String toString() => "PlotTitle($data)";

  bool get shown => !(data["-"] ?? false);
  PlotBox get box => PlotBox.Title(data["B"]);
  PlotText get text => PlotText(data["T"], defaultFontWeight: "bold", defaultFontSize: 42.0);

  final Map<String, dynamic> data;
}

// ----------------------------------------------------------------------

class LegendRow {
  LegendRow({required this.text, required this.point, required this.count, required this.priority});
  String toString() => "\"$text}\" $point count:$count priority:$priority";

  final String text;
  final PointPlotSpec point;
  final int count;
  final int priority;
}

class Legend {
  Legend([this.data = const <String, dynamic>{}, this.legendRows = const <LegendRow>[]]);

  String toString() => "Legend($data)";

  bool get shown => !(data["-"] ?? false) && legendRows.isNotEmpty;
  bool get addCounter => data["C"] ?? false;
  double get pointSize => data["S"] ?? 32.0;
  bool get showRowsWithZeroCount => data["z"] ?? false;
  PlotBox get box => PlotBox.Legend(data["B"]);
  PlotText get rowStyle => PlotText(data["t"], defaultFontWeight: "normal", defaultFontSize: 36.0);
  PlotText get title => PlotText(data["T"], defaultFontWeight: "bold", defaultFontSize: 36.0);

  final Map<String, dynamic> data;
  final List<LegendRow> legendRows;
}

// ----------------------------------------------------------------------

class PlotBox {
  PlotBox.Title(Map<String, dynamic>? dat)
      : data = dat ?? <String, dynamic>{},
        defaultBackgroundColor = "transparent",
        defaultBorderWidth = 0.0,
        defaultPadding = BoxPadding.zero(), defaultOrigin = "tl", defaultOffset = Offset(30, 30);
  PlotBox.Legend(Map<String, dynamic>? dat)
      : data = dat ?? <String, dynamic>{},
        defaultBackgroundColor = "white",
        defaultBorderWidth = 1.0,
        defaultPadding = BoxPadding.all(10.0), defaultOrigin = "Bl", defaultOffset = Offset(20, -20);

  String get origin => data["o"] ?? defaultOrigin;
  Offset get offset => data["O"] != null ? Offset(data["O"][0].toDouble(), data["O"][1].toDouble()) : defaultOffset;
  BoxPadding get padding => BoxPadding(
      top: data["p"]?["t"]?.toDouble() ?? defaultPadding.top,
      bottom: data["p"]?["b"]?.toDouble() ?? defaultPadding.bottom,
      left: data["p"]?["l"]?.toDouble() ?? defaultPadding.left,
      right: data["p"]?["r"]?.toDouble() ?? defaultPadding.right);
  double get borderWidth => data["W"]?.toDouble() ?? defaultBorderWidth;
  String get backgroundColor => data["F"] ?? defaultBackgroundColor;
  String get borderColor => data["B"] ?? "black";

  final Map<String, dynamic> data;
  final String defaultBackgroundColor;
  final double defaultBorderWidth;
  final BoxPadding defaultPadding;
  final String defaultOrigin;
  final Offset defaultOffset;
}

class BoxPadding {
  BoxPadding({this.top = 0.0, this.bottom = 0.0, this.left = 0.0, this.right = 0.0});
  const BoxPadding.zero()
      : top = 0.0,
        bottom = 0.0,
        left = 0.0,
        right = 0.0;
  BoxPadding.all(double val)
      : top = val,
        bottom = val,
        left = val,
        right = val;
  BoxPadding operator *(double pixelSize) => BoxPadding(top: top * pixelSize, bottom: bottom * pixelSize, left: left * pixelSize, right: right * pixelSize);
  BoxPadding operator +(BoxPadding rhs) => BoxPadding(top: top + rhs.top, bottom: bottom + rhs.bottom, left: left + rhs.left, right: right + rhs.right);
  String toString() => "BoxPadding(top: $top, bottom: $bottom, left: $left, right: $right)";
  final double top, bottom, left, right;
}

// ----------------------------------------------------------------------

class PlotText {
  PlotText(Map<String, dynamic>? dat, {this.defaultFontWeight = "normal", this.defaultFontSize = 16.0}) : data = dat ?? <String, dynamic>{};

  List<String> get text => data["t"] != null ? const LineSplitter().convert(data["t"]) : <String>[];

  LabelStyle get labelStyle => LabelStyle(
      color: NamedColor.fromString(data["c"] ?? "black"),
      fontFamily: labelFontFamilyFromString(data["f"]),
      fontStyle: fontStyleFromString(data["S"]),
      fontWeight: fontWeightFromString(data["W"], defaultFontWeight));
  double get fontSize => data["s"]?.toDouble() ?? defaultFontSize;
  double get interline => data["i"]?.toDouble() ?? 0.2;

  final Map<String, dynamic> data;
  final String defaultFontWeight;
  final double defaultFontSize;
}

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
