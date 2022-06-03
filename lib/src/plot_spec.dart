import 'dart:math' as math;
import 'dart:ui';
import 'dart:convert';
import 'package:vector_math/vector_math_64.dart';

import 'chart.dart';
import 'draw_on.dart';
import 'color.dart';
import 'error.dart';
import 'cast.dart';
import 'viewport.dart';

// ----------------------------------------------------------------------

abstract class PlotSpec {
  String name();
  String title() => name();
  List<int> drawingOrder();
  PointPlotSpec operator [](int pointNo);
  int priority();
  PlotTitle? plotTitle() => null;
  Legend? legend() => null;
  Viewport? viewport() => null;
  void activate() {
    // called when plot spac activated, allows calculating delayed configuration
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
  void initDefaultPointSpecs({required ColorAndModifier testAntigenFill, required ColorAndModifier outline}) {
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
    initDefaultPointSpecs(testAntigenFill: ColorAndModifier("green"), outline: ColorAndModifier("black"));
    makeDefaultDrawingOrder(_chart, _projection);
    makeDefaultPointSpecs(chart: _chart, isReferenceAntigen: (agNo) => ddoReferenceAntigens.contains(agNo));
  }

  @override
  String name() => "Default";

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

  // ----------------------------------------------------------------------

  final Chart _chart;
  final Projection _projection;
}

// ----------------------------------------------------------------------

class PlotSpecSemantic extends PlotSpec with _DefaultDrawingOrder, _DefaultPointSpecs {
  PlotSpecSemantic(this._chart, this._projection, this._name, this._data);

  @override
  String name() => _name;

  @override
  String title() => _data["t"] ?? name();

  @override
  List<int> drawingOrder() => _drawingOrder;

  @override
  Viewport? viewport() => _data["V"] != null ? Viewport.originSizeList(_data["V"].map((value) => value.toDouble()).cast<double>().toList()) : null;

  @override
  PointPlotSpec operator [](int pointNo) => pointSpec[pointNo];

  @override
  int priority() => _data["z"] ?? 0;

  @override
  bool _addPointSpecByCloning() => true;

  @override
  PlotTitle? plotTitle() => _data["T"] != null ? PlotTitle(_data["T"]) : null;

  @override
  Legend? legend() => _data["L"] != null ? Legend(_data["L"], _legendRows) : null;

  @override // called when plot spac activated, allows calculating delayed configuration
  void activate() {
    if (!_activated) {
      final stopwatch = Stopwatch()..start();
      initDefaultPointSpecs(testAntigenFill: ColorAndModifier("gray80"), outline: ColorAndModifier("gray80"));
      makeDefaultDrawingOrder(_chart, _projection);
      _drawingOrder = ddoSera + ddoReferenceAntigens + ddoTestAntigens;
      makeDefaultPointSpecs(chart: _chart, isReferenceAntigen: (agNo) => ddoReferenceAntigens.contains(agNo));
      apply(_data["A"] ?? []);
      _activated = true;
      debug("$_name activated in ${stopwatch.elapsed}");
    }
  }

  void apply(List<dynamic> data, [int recursionLevel = 1]) {
    if (recursionLevel > 10) throw FormatError("PlotSpecSemantic.apply: too deep recursion");
    for (final en in data) {
      applyEntry(en as Map<String, dynamic>, recursionLevel);
    }
    _legendRows.sort((e1, e2) => e1.priority.compareTo(e2.priority));
  }

  void applyEntry(Map<String, dynamic> entry, int recursionLevel) {
    if (entry["R"] != null) {
      // parent style
      final parentStyle = _chart.data["c"]["R"][entry["R"]];
      if (parentStyle != null) {
        apply(parentStyle["A"] ?? [], recursionLevel + 1);
      }
    }
    final points = selectPoints(entry["T"], entry["A"]);
    if (points.isNotEmpty) {
      for (final pointNo in points) {
        modifyPointPlotSpec(entry, pointSpec[pointNo], pointNo: pointNo);
      }
      raiseLowerPoints(entry["D"], points);
    }
    final legend = entry["L"];
    if (legend != null) {
      final point = points.isNotEmpty ? PointPlotSpec.from(pointSpec[points[0]]) : modifyPointPlotSpec(entry, PointPlotSpec());
      _legendRows.add(LegendRow(text: legend["t"] ?? "", point: point, count: points.length, priority: legend["p"] ?? 0));
    } else if (entry["T"] == null && (entry["F"]?[0] == ":" || entry["O"]?[0] == ":")) {
      // color of all points modified, modify existing legends as well (hack to make legend for pale clades pale too)
      for (final legendRow in _legendRows) {
        modifyPointPlotSpec({"F": entry["F"] ?? "", "O": entry["O"] ?? ""}, legendRow.point);
      }
    }
  }

  List<int> selectPoints(Map<String, dynamic>? selector, dynamic antigensOnly) {
    bool match(int pointNo, int agSrNo, Map<String, dynamic> semantic) {
      if (selector != null) {
        return selector.entries.fold(true, (result, en) {
          if (!result) return false;
          if (en.key == "!i") return agSrNo == en.value;
          if (en.key == "!D") {
            // date range
            if (pointNo >= _chart.antigens.length) return false;
            final within = _chart.antigens[pointNo].withinDateRange(en.value[0] as String, en.value[1] as String);
            // print("$pointNo ${_chart.antigens[pointNo].date} -- ${en.value} -> $within");
            return within;
          }
          return semanticMatch(en.key, en.value, semantic);
        });
      } else {
        return true; // select all if selector absent
      }
    }

    final selected = <int>[];
    if (castToBool(antigensOnly, ifNull: true)) {
      selected.addAll(Iterable<int>.generate(_chart.antigens.length).where((agNo) => match(agNo, agNo, _chart.antigens[agNo].semantic))); //
    }
    if (!castToBool(antigensOnly, ifNull: false)) {
      selected.addAll(
          Iterable<List<int>>.generate(_chart.sera.length, (srNo) => [srNo, srNo + _chart.antigens.length]).where((ref) => match(ref[1], ref[0], _chart.sera[ref[0]].semantic)).map((ref) => ref[1]));
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

  PointPlotSpec modifyPointPlotSpec(Map<String, dynamic> mod, PointPlotSpec spec, {int? pointNo}) {
    mod.forEach((modKey, modValue) {
      switch (modKey) {
        case "S":
          spec.shape = pointShapeFromString(modValue);
          break;
        case "F":
          spec.fill.modify(modValue);
          break;
        case "O":
          spec.outline.modify(modValue);
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
        case "l":
          spec.label = pointLabelFromAce(modValue);
          break;
        case "CI": // serum circle
          spec.serumCircle = serumCircleData(modValue, pointNo);
          break;
        case "R": // reference to another style, processed in applyEntry()
        case "T": // selector, processed earlier
        case "D": // order, processed in applyEntry()
        case "A": // antigens only, processed in selectPoints()
        case "L": // legend row, processed in applyEntry()
          break;
        default:
          warning("modifyPointPlotSpec: unknown key $modKey: $modValue");
          break;
      }
    });
    return spec;
  }

  SerumCircle? serumCircleData(Map<String, dynamic> mod, int? pointNo) {
    try {
      final serumNo = (pointNo ?? 0) - _chart.antigens.length;
      if (serumNo < 0 || serumNo >= _chart.sera.length) throw DataError("invalid pointNo: $pointNo or serumNo $serumNo (AG: ${_chart.antigens.length} SR: ${_chart.sera.length})");
      final circleData = _chart.sera[serumNo].semantic["CI${mod['u']?.round() ?? 2}"];
      if (circleData == null) throw DataError("no serum circle data for fold ${mod['u']}");
      final radius = ((mod["T"] ?? false) ? circleData["e"] : circleData["t"])?.toDouble();
      final dash = (radius != null ? (mod["d"] ?? 0) : 100);
      return SerumCircle(
          radius: radius ?? mod["u"]?.toDouble() ?? 2.0,
          outline: NamedColor.fromString(mod["O"] ?? "blue"),
          outlineWidthPixels: mod["o"].toDouble() ?? 1.0,
          fill: NamedColor.fromString(mod["F"] ?? "transparent"),
          dash: dash,
          sector: mod["a"] != null ? Sector.fromTwoAngles(mod["a"][0], mod["a"][1]) : null,
          radiusOutline: mod["r"]?["O"],
          radiusWidthPixels: mod["r"]?["o"],
          radiusDash: mod["r"]?["d"]);
    } catch (err) {
      error("serumCircleData: $err $mod");
      return null;
    }
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

  static PointLabel pointLabelFromAce(Map<String, dynamic> source) {
    final args = <Symbol, dynamic>{};
    source.forEach((key, val) {
      switch (key) {
        case "t":
          args[const Symbol("text")] = val;
          break;
        case "p": // [x, y]: label offset (2D only), list of two doubles, default is [0, 1] means under point
          args[const Symbol("offset")] = Offset(val[0].toDouble(), val[1].toDouble());
          break;
        case "f": // font face
          args[const Symbol("fontFamily")] = labelFontFamilyFromString(val);
          break;
        case "S": // font slant: "normal" (default), "italic"
          args[const Symbol("fontStyle")] = fontStyleFromString(val);
          break;
        case "W": // font weight: "normal" (default), "bold"
          args[const Symbol("fontWeight")] = fontWeightFromString(val);
          break;
        case "s": // label size, default 16.0
          args[const Symbol("sizePixels")] = val.toDouble();
          break;
        case "c": // label color, default: "black"
          args[const Symbol("color")] = NamedColor.fromStringOr(val, "black");
          break;
        case "r": // label rotation, default 0.0
          args[const Symbol("rotation")] = val.toDouble();
          break;
        // case "-":                // if label is hidden
        // args[const Symbol("shown")] = !val;
        // break;
        // case "i":                // addtional interval between lines as a fraction of line height
        // break;
        default:
          warning("pointLabelFromAce: unknown point label specification key $key: $val");
          break;
      }
    });

    // print("$args");
    return Function.apply(PointLabel.apply, [], args);
  }

  bool _activated = false;
  final Chart _chart;
  final Projection _projection;

  final String _name;
  final Map<String, dynamic> _data;

  late List<int> _drawingOrder;
  final List<PointPlotSpec> pointSpec = [];
  final List<LegendRow> _legendRows = [];
}

// ----------------------------------------------------------------------

class _Defaults {
  const _Defaults.title()
      : fontWeight = "bold",
        fontSize = 28,
        interline = 0.2,
        backgroundColor = "transparent",
        borderColor = "black",
        borderWidth = 0.0,
        padding = const BoxPadding.zero(),
        originDirection = "tl",
        offset = const Offset(30, 30);
  const _Defaults.legend({this.fontWeight = "normal", this.interline = 0.3})
      : fontSize = 20,
        backgroundColor = "white",
        borderColor = "black",
        borderWidth = 1.0,
        padding = const BoxPadding.hw(10.0, 15.0),
        originDirection = "Bl",
        offset = const Offset(20, -20);
  const _Defaults.legendTitle() : this.legend(fontWeight: "bold", interline: 0.2);

  final String fontWeight;
  final double fontSize;
  final double interline;
  final String backgroundColor;
  final String borderColor;
  final double borderWidth;
  final BoxPadding padding;
  final String originDirection;
  final Offset offset;
}

const _plotTitleDefaults = _Defaults.title();
const _legendDefaults = _Defaults.legend();
const _legendTitleDefaults = _Defaults.legendTitle();

// ----------------------------------------------------------------------

class PlotTitle {
  PlotTitle([this.data = const <String, dynamic>{}]);

  String toString() => "PlotTitle($data)";

  bool get shown => !(data["-"] ?? false);
  PlotBox get box => PlotBox.Title(data["B"]);
  PlotText get text => PlotText(data["T"], _plotTitleDefaults);

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
  double get pointSize => data["S"] ?? _legendDefaults.fontSize;
  bool get showRowsWithZeroCount => data["z"] ?? false;
  PlotBox get box => PlotBox.Legend(data["B"]);
  PlotText get rowStyle => PlotText(data["t"], _legendDefaults);
  PlotText get title => PlotText(data["T"], _legendTitleDefaults);

  final Map<String, dynamic> data;
  final List<LegendRow> legendRows;
}

// ----------------------------------------------------------------------

class PlotBox {
  PlotBox.Title(Map<String, dynamic>? dat)
      : data = dat ?? <String, dynamic>{},
        _defaults = _Defaults.title();
  PlotBox.Legend(Map<String, dynamic>? dat)
      : data = dat ?? <String, dynamic>{},
        _defaults = _Defaults.legend();

  String get originDirection => data["o"] ?? _defaults.originDirection;
  Offset get offset => data["O"] != null ? Offset(data["O"][0].toDouble(), data["O"][1].toDouble()) : _defaults.offset;
  BoxPadding get padding => BoxPadding(
      top: data["p"]?["t"]?.toDouble() ?? _defaults.padding.top,
      bottom: data["p"]?["b"]?.toDouble() ?? _defaults.padding.bottom,
      left: data["p"]?["l"]?.toDouble() ?? _defaults.padding.left,
      right: data["p"]?["r"]?.toDouble() ?? _defaults.padding.right);
  double get borderWidth => data["W"]?.toDouble() ?? _defaults.borderWidth;
  String get backgroundColor => data["F"] ?? _defaults.backgroundColor;
  String get borderColor => data["B"] ?? _defaults.borderColor;

  final Map<String, dynamic> data;
  final _Defaults _defaults;
}

class BoxPadding {
  BoxPadding({this.top = 0.0, this.bottom = 0.0, this.left = 0.0, this.right = 0.0});
  const BoxPadding.zero()
      : top = 0.0,
        bottom = 0.0,
        left = 0.0,
        right = 0.0;
  const BoxPadding.all(double val)
      : top = val,
        bottom = val,
        left = val,
        right = val;
  const BoxPadding.hw(double vert, double horiz)
      : top = vert,
        bottom = vert,
        left = horiz,
        right = horiz;
  BoxPadding operator *(double pixelSize) => BoxPadding(top: top * pixelSize, bottom: bottom * pixelSize, left: left * pixelSize, right: right * pixelSize);
  BoxPadding operator +(BoxPadding rhs) => BoxPadding(top: top + rhs.top, bottom: bottom + rhs.bottom, left: left + rhs.left, right: right + rhs.right);
  String toString() => "BoxPadding(top: $top, bottom: $bottom, left: $left, right: $right)";
  final double top, bottom, left, right;
}

// ----------------------------------------------------------------------

class PlotText {
  PlotText(Map<String, dynamic>? dat, this._defaults) : data = dat ?? <String, dynamic>{};

  List<String> get text => data["t"] != null ? const LineSplitter().convert(data["t"]) : <String>[];

  LabelStyle get labelStyle => LabelStyle(
      color: NamedColor.fromString(data["c"] ?? "black"),
      fontFamily: labelFontFamilyFromString(data["f"]),
      fontStyle: fontStyleFromString(data["S"]),
      fontWeight: fontWeightFromString(data["W"], _defaults.fontWeight));
  double get fontSize => data["s"]?.toDouble() ?? _defaults.fontSize;
  double get interline => data["i"]?.toDouble() ?? _defaults.interline;

  final Map<String, dynamic> data;
  final _Defaults _defaults;
}

// ----------------------------------------------------------------------

class PlotSpecLegacy extends PlotSpec {
  PlotSpecLegacy(this._chart) : _data = _chart.data["c"]["p"] {
    for (final entry in _data["P"] ?? []) {
      final spec = PointPlotSpec();
      if (!(entry["+"] ?? true)) spec.shown = false;
      spec.fill = ColorAndModifier(entry["F"] ?? "transparent");
      spec.outline = ColorAndModifier(entry["O"] ?? "black");
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
  String name() => "Legacy";

  @override
  List<int> drawingOrder() {
    return _data["d"]?.cast<int>() ?? [];
  }

  @override
  PointPlotSpec operator [](int pointNo) => _specs[_data["p"][pointNo]];

  @override
  int priority() => 998;

  final Chart _chart;
  final Map<String, dynamic> _data;
  final List<PointPlotSpec> _specs = [];
}

// ----------------------------------------------------------------------
