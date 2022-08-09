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
  int numberOfPoints();
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
  makeDefaultDrawingOrder(Chart chart, Projection projection) {
    bool hasCoord(int pointNo) => projection.layout[pointNo] != null;
    ddoSera = Iterable<int>.generate(chart.sera.length, (srNo) => srNo + chart.antigens.length).where(hasCoord).toList();
    ddoReferenceAntigens = chart.referenceAntigens().where(hasCoord).toList();
    ddoTestAntigens = Iterable<int>.generate(chart.antigens.length).where((agNo) => !ddoReferenceAntigens.contains(agNo)).where(hasCoord).toList();
  }

  List<int> defaultDrawingOrder() => ddoSera + ddoReferenceAntigens + ddoTestAntigens;

  static List<int> raiseLowerPoints(List<int> order, String? raiseLower, List<int> points) {
    if (raiseLower != null) {
      final List<int> keep = [], move = [];
      for (final pnt in order) {
        if (points.contains(pnt)) {
          move.add(pnt);
        } else {
          keep.add(pnt);
        }
      }
      if (raiseLower == "r") {
        order = keep + move;
      } else {
        order = move + keep;
      }
    }
    return order;
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
  List<int> drawingOrder() => defaultDrawingOrder();

  @override
  PointPlotSpec operator [](int pointNo) => pointSpec[pointNo];

  @override
  int numberOfPoints() => pointSpec.length;

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
  PlotSpecSemantic(this._chart, this._projection, this._name, this._data) {
    _legend.update(_data["L"]);
    // debug("PlotSpecSemantic ${name()} legend ${_data["L"]}");
  }

  @override
  String name() => _name;

  @override
  String title() => _data["t"] ?? name();

  @override
  List<int> drawingOrder() => _drawingOrder;

  @override
  Viewport? viewport() => _viewport;

  @override
  PointPlotSpec operator [](int pointNo) => pointSpec[pointNo];

  @override
  int numberOfPoints() => pointSpec.length;

  @override
  int priority() => _data["z"] ?? 0;

  @override
  bool _addPointSpecByCloning() => true;

  @override
  PlotTitle? plotTitle() => _data["T"] != null ? PlotTitle(_data["T"]) : null;

  @override
  Legend? legend() => _legend; // _data["L"] != null ? Legend(_data["L"], _legendRows) : null;

  @override // called when plot spac activated, allows calculating delayed configuration
  void activate() {
    if (!_activated) {
      final stopwatch = Stopwatch()..start();
      initDefaultPointSpecs(testAntigenFill: ColorAndModifier("gray80"), outline: ColorAndModifier("gray80"));
      makeDefaultDrawingOrder(_chart, _projection);
      _drawingOrder = ddoSera + ddoReferenceAntigens + ddoTestAntigens;
      makeDefaultPointSpecs(chart: _chart, isReferenceAntigen: (agNo) => ddoReferenceAntigens.contains(agNo));
      _setViewport(_data["V"]);
      apply(_data["A"] ?? []);
      _activated = true;
      debug("$_name activated in ${stopwatch.elapsed}");
    }
  }

  void _setViewport(List<dynamic>? source) {
    if (source != null) {
      _viewport = Viewport.originSizeList(source.map((value) => value.toDouble()).cast<double>().toList());
    }
  }

  void apply(List<dynamic> data, [int recursionLevel = 1]) {
    if (recursionLevel > 10) throw FormatError("PlotSpecSemantic.apply: too deep recursion");
    for (final en in data) {
      applyEntry(en as Map<String, dynamic>, recursionLevel);
    }
    _legend.legendRows.sort((e1, e2) => e1.priority.compareTo(e2.priority));
  }

  void applyEntry(Map<String, dynamic> entry, int recursionLevel) {
    if (entry["R"] != null) {
      // parent style
      final parentStyle = _chart.data["c"]["R"][entry["R"]];
      if (parentStyle != null) {
        _setViewport(parentStyle["V"]);
        _legend.update(parentStyle["L"]);
        apply(parentStyle["A"] ?? [], recursionLevel + 1);
      } else {
        warning("(parent) style not found: ${entry['R']}");
      }
    }
    final points = selectPoints(entry["T"], entry["A"]);
    if (points.isNotEmpty) {
      for (final pointNo in points) {
        modifyPointPlotSpec(entry, pointSpec[pointNo], pointNo: pointNo);
        if (pointSpec[pointNo].serumCoverage != null) {
          applySerumCoverage(pointSpec[pointNo].serumCoverage!, pointNo);
        }
      }
      _drawingOrder = _DefaultDrawingOrder.raiseLowerPoints(_drawingOrder, entry["D"], points);
    }
    final legend = entry["L"];
    if (legend != null) {
      final point = points.isNotEmpty ? PointPlotSpec.from(pointSpec[points[0]], forceShape: PointShape.circle) : modifyPointPlotSpec(entry, PointPlotSpec());
      _legend.legendRows.add(LegendRow(text: legend["t"] ?? "", point: point, count: points.length, priority: legend["p"] ?? 0));
    } else if (entry["T"] == null && (entry["F"]?[0] == ":" || entry["O"]?[0] == ":")) {
      // color of all points modified, modify existing legends as well (hack to make legend for pale clades pale too)
      for (final legendRow in _legend.legendRows) {
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
        case "SC": // serum coverage
          spec.serumCoverage = serumCoverageData(modValue, pointNo);
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

  // ----------------------------------------------------------------------

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
          outlineWidthPixels: mod["o"]?.toDouble() ?? 1.0,
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

  // ----------------------------------------------------------------------

  SerumCoverage? serumCoverageData(Map<String, dynamic> mod, int? pointNo) {
    try {
      final serumNo = (pointNo ?? 0) - _chart.antigens.length;
      if (serumNo < 0 || serumNo >= _chart.sera.length) throw DataError("invalid pointNo: $pointNo or serumNo $serumNo (AG: ${_chart.antigens.length} SR: ${_chart.sera.length})");
      return SerumCoverage(
        fold: mod["u"].toDouble() ?? 2.0,
        withinOutline: mod["I"]?["O"] ?? "pink",
        withinOutlineWidthPixels: mod["I"]?["o"]?.toDouble() ?? 3.0,
        withinFill: mod["I"]?["F"] ?? ":bright",
        outsideOutline: mod["O"]?["O"] ?? "black",
        outsideOutlineWidthPixels: mod["O"]?["o"]?.toDouble() ?? 3.0,
        outsideFill: mod["O"]?["F"] ?? ":bright",
      );
    } catch (err) {
      error("serumCoverageData: $err $mod");
      return null;
    }
  }

  void applySerumCoverage(SerumCoverage serumCoverage, int pointNo) {
    final serumNo = pointNo - _chart.antigens.length;
    final homologousTiter = _chart.homologousTiterForSerum(serumNo);
    if (homologousTiter.isDontCare) throw DataError("serum coverage data not available: homologous titer is \"*\"");
    final titerThreshold = homologousTiter.logged - serumCoverage.fold;
    if (titerThreshold <= 0.0) throw DataError("serum coverage data for fold ${serumCoverage.fold} not available: homologous titer is too low: $homologousTiter");
    final antigensWithin = <int>[], antigensOutside = <int>[];
    for (int agNo = 0; agNo < _chart.antigens.length; ++agNo) {
      final titer = _chart.titers.titer(agNo, serumNo);
      if (!titer.isDontCare) {
        if (titer.loggedForColumnBases >= titerThreshold) {
          applySerumCoverageAntigenWithin(serumCoverage, pointSpec[agNo]);
          antigensWithin.add(agNo);
        } else {
          applySerumCoverageAntigenOutside(serumCoverage, pointSpec[agNo]);
          antigensOutside.add(agNo);
        }
      }
    }
    _drawingOrder = _DefaultDrawingOrder.raiseLowerPoints(_drawingOrder, "r", antigensWithin);
    _drawingOrder = _DefaultDrawingOrder.raiseLowerPoints(_drawingOrder, "r", antigensOutside);
    if (antigensWithin.isEmpty) warning("serum coverage for SR $serumNo: no antigens within fold ${serumCoverage.fold} from homologous titer $homologousTiter");
    // debug("SR $serumNo titer: $homologousTiter $serumCoverage");
  }

  void applySerumCoverageAntigenWithin(SerumCoverage serumCoverage, PointPlotSpec antigenSpec) {
    antigenSpec.fill.modify(serumCoverage.withinFill);
    antigenSpec.outline.modify(serumCoverage.withinOutline);
    antigenSpec.outlineWidthPixels = serumCoverage.withinOutlineWidthPixels;
  }

  void applySerumCoverageAntigenOutside(SerumCoverage serumCoverage, PointPlotSpec antigenSpec) {
    antigenSpec.fill.modify(serumCoverage.outsideFill);
    antigenSpec.outline.modify(serumCoverage.outsideOutline);
    antigenSpec.outlineWidthPixels = serumCoverage.outsideOutlineWidthPixels;
  }

  // ----------------------------------------------------------------------

  bool _activated = false;
  final Chart _chart;
  final Projection _projection;

  final String _name;
  final Map<String, dynamic> _data;

  late List<int> _drawingOrder;
  final pointSpec = <PointPlotSpec>[];
  final _legend = Legend();
  Viewport? _viewport;
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
        padding = const BoxPadding.hw(5.0, 10.0),
        originDirection = "Bl",
        offset = const Offset(10, -10);
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
  PlotBox get box => PlotBox.title(data["B"]);
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
  void update(Map<String, dynamic>? source) {
    // debug("legend update $source");
    source?.forEach((key, val) {
      switch (key) {
        case "-":
          _shown = !val;
          break;
        case "C":
          addCounter = val;
          break;
        case "S":
          pointSize = val.toDouble();
          break;
        case "z":
          showRowsWithZeroCount = val;
          break;
        case "B":
          box.update(val);
          break;
        case "t":
          rowStyle.update(val);
          break;
        case "T":
          title.update(val);
          break;
        default:
          warning("[legend] unrecognized key \"$key\"");
          break;
      }
    });
  }

  String toString() => "Legend(...)";

  bool get shown => _shown && legendRows.isNotEmpty;

  void reset() {
    legendRows.clear();
  }

  bool _shown = true;
  bool addCounter = false;
  double pointSize = _legendDefaults.fontSize;
  bool showRowsWithZeroCount = false;
  PlotBox box = PlotBox.legend();
  PlotText rowStyle = PlotText(null, _legendDefaults);
  PlotText title = PlotText(null, _legendTitleDefaults);
  final List<LegendRow> legendRows = <LegendRow>[];
}

// ----------------------------------------------------------------------

class PlotBox {
  factory PlotBox.title([Map<String, dynamic>? dat]) {
    final pb = PlotBox.defaults(_Defaults.title());
    pb.update(dat);
    return pb;
  }
  factory PlotBox.legend([Map<String, dynamic>? dat]) {
    final pb = PlotBox.defaults(_Defaults.legend());
    pb.update(dat);
    return pb;
  }
  PlotBox.defaults(_Defaults defaults)
      : originDirection = defaults.originDirection,
        offset = defaults.offset,
        padding = BoxPadding(top: defaults.padding.top, bottom: defaults.padding.bottom, left: defaults.padding.left, right: defaults.padding.right),
        borderWidth = defaults.borderWidth,
        backgroundColor = defaults.backgroundColor,
        borderColor = defaults.borderColor;

  void update(Map<String, dynamic>? dat) {
    dat?.forEach((key, val) {
      switch (key) {
        case "o":
          originDirection = val;
          break;
        case "O":
          offset = Offset(val[0].toDouble(), val[1].toDouble());
          break;
        case "p":
          padding = BoxPadding(
              top: val["t"]?.toDouble() ?? padding.top, bottom: val["b"]?.toDouble() ?? padding.bottom, left: val["l"]?.toDouble() ?? padding.left, right: val["r"]?.toDouble() ?? padding.right);
          break;
        case "W":
          borderWidth = val.toDouble();
          break;
        case "F":
          backgroundColor = val;
          break;
        case "B":
          borderColor = val;
          break;
      }
    });
  }

  String originDirection;
  Offset offset;
  BoxPadding padding;
  double borderWidth;
  String backgroundColor;
  String borderColor;
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
  PlotText(Map<String, dynamic>? dat, _Defaults defaults)
      : labelStyle =
            LabelStyle(color: NamedColor.fromString("black"), fontFamily: labelFontFamilyFromString(), fontStyle: fontStyleFromString(), fontWeight: fontWeightFromString(null, defaults.fontWeight)),
        fontSize = defaults.fontSize,
        interline = defaults.interline {
    if (dat != null) update(dat);
  }

  void update(Map<String, dynamic> dat) {
    dat.forEach((key, val) {
      switch (key) {
        case "t":
          text = const LineSplitter().convert(val);
          break;
        case "s":
          fontSize = val.toDouble();
          break;
        case "i":
          interline = val.toDouble();
          break;
        case "c":
          labelStyle = labelStyle.cloneWith(color: NamedColor.fromString(val));
          break;
        case "f":
          labelStyle = labelStyle.cloneWith(fontFamily: labelFontFamilyFromString(val));
          break;
        case "S":
          labelStyle = labelStyle.cloneWith(fontStyle: fontStyleFromString(val));
          break;
        case "W":
          labelStyle = labelStyle.cloneWith(fontWeight: fontWeightFromString(val));
          break;
      }
    });
  }

  List<String> text = <String>[];
  LabelStyle labelStyle;
  double fontSize;
  double interline;
}

// ----------------------------------------------------------------------

class PlotSpecLegacy extends PlotSpec {
  PlotSpecLegacy(this._chart) : _data = _chart.data["c"]["p"] {
    _importFromData();
  }

  static const myName = "Legacy";
  static const _sizeScale = 5.0;

  @override
  String name() => myName;

  @override
  List<int> drawingOrder() {
    return _data["d"]?.cast<int>() ?? [];
  }

  @override
  PointPlotSpec operator [](int pointNo) => _specs[_data["p"][pointNo]];

  @override
  int numberOfPoints() => _data["p"]?.length ?? 0;

  @override
  int priority() => 998;

  void _importFromData() {
    _specs.clear();
    for (final entry in _data["P"] ?? []) {
      final spec = PointPlotSpec();
      if (!(entry["+"] ?? true)) spec.shown = false;
      spec.fill = ColorAndModifier(entry["F"] ?? "transparent");
      spec.outline = ColorAndModifier(entry["O"] ?? "black");
      spec.outlineWidthPixels = entry["o"]?.toDouble() ?? 1.0;
      spec.sizePixels = (entry["s"]?.toDouble() ?? 1.0) * _sizeScale;
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

  void setFrom(PlotSpec source) {
    _data.clear();
    _data["d"] = source.drawingOrder();
    final uniqueSpecs = <PointPlotSpec>[];
    final specNoForPoint = <int>[];
    for (int pointNo = 0; pointNo < source.numberOfPoints(); ++pointNo) {
      final pointSpec = source[pointNo];
      int? matchingIndex;
      for (int specIndex = 0; specIndex < uniqueSpecs.length; ++specIndex) {
        if (uniqueSpecs[specIndex] == pointSpec) {
          matchingIndex = specIndex;
          break;
        }
      }
      if (matchingIndex == null) {
        uniqueSpecs.add(pointSpec);
        matchingIndex = uniqueSpecs.length - 1;
      }
      specNoForPoint.add(matchingIndex);
    }
    debug("[legacy from] ${uniqueSpecs.length} unique specs for ${source.numberOfPoints()} points");
    _data["p"] = specNoForPoint;
    _data["P"] = uniqueSpecs.map<Map<String, dynamic>>((PointPlotSpec src) {
      final obj = <String, dynamic>{};
      if (!src.shown) obj["+"] = false;
      if (src.fill != ColorAndModifier("transparent")) obj["F"] = src.fill.toString();
      if (src.outline != ColorAndModifier("black")) obj["O"] = src.outline.toString();
      if (src.outlineWidthPixels != 1.0) obj["o"] = src.outlineWidthPixels;
      if (src.shape != PointShape.circle) obj["S"] = pointShapeToString(src.shape);
      if (src.sizePixels != 10.0) obj["s"] = src.sizePixels / _sizeScale;
      if (src.rotation != 0.0) obj["r"] = src.rotation;
      if (src.aspect != 1.0) obj["a"] = src.aspect;
      // label
      return obj;
    }).toList();
    _importFromData();
  }

  final Chart _chart;
  final Map<String, dynamic> _data;
  final List<PointPlotSpec> _specs = [];
}

// ----------------------------------------------------------------------

class PlotSpecColorByAA extends PlotSpec with _DefaultDrawingOrder, _DefaultPointSpecs {
  PlotSpecColorByAA(this._chart, this._projection) {
    initDefaultPointSpecs(testAntigenFill: ColorAndModifier("grey"), outline: ColorAndModifier("grey"));
    makeDefaultDrawingOrder(_chart, _projection);
    _drawingOrder = defaultDrawingOrder();
    makeDefaultPointSpecs(chart: _chart, isReferenceAntigen: (agNo) => ddoReferenceAntigens.contains(agNo));
  }

  static const myName = "*color-by-aa";
  // static const _sizeScale = 5.0;

  @override
  String name() => myName;

  @override
  List<int> drawingOrder() => _drawingOrder;

  @override
  PointPlotSpec operator [](int pointNo) => pointSpec[pointNo];

  @override
  int numberOfPoints() => _drawingOrder.length;

  @override
  Legend? legend() => _legend;

  @override
  int priority() => 997;

  @override
  bool _addPointSpecByCloning() => true;

  void setPositions(List<int> positions) {
    final posAaAntigenIndexes = _collectAAPerPos(positions);
    _legend.reset();
    _legend.addCounter = true;
    // print("$aaPerPos");
    for (int specNo = 0; specNo < posAaAntigenIndexes.length; ++specNo) {
      final points = posAaAntigenIndexes[specNo].value;
      // print("${posAaAntigenIndexes[specNo].key} $points");
      for (final no in points) {
        pointSpec[no].fill.modify(distinctColors[specNo]);
        pointSpec[no].outline.modify("black");
      }
      _drawingOrder = _DefaultDrawingOrder.raiseLowerPoints(_drawingOrder, "r", points);
      final point = PointPlotSpec.from(pointSpec[points[0]], forceShape: PointShape.circle);
      _legend.legendRows.add(LegendRow(text: posAaAntigenIndexes[specNo].key, point: point, count: points.length, priority: specNo));
    }
    // print(_drawingOrder);
  }

  List<MapEntry<String, List<int>>> _collectAAPerPos(List<int> positions) {
    final dataMap = <String, List<int>>{};
    for (final entry in _chart.antigens.asMap().entries) {
      final key = positions.map((pos) => "$pos${entry.value.aa.length >= pos ? entry.value.aa[pos - 1] : 'X'}").join(" "); // --> "192K 182L"
      dataMap.update(key, (List<int> old) {
        old.add(entry.key);
        return old;
      }, ifAbsent: () => [entry.key]);
    }
    final data = dataMap.entries.toList();
    data.sort((e1, e2) => e2.value.length.compareTo(e1.value.length)); // sort by number of antigens descending
    return data;
  }

  final Chart _chart;
  final Projection _projection;
  late List<int> _drawingOrder;
  final _legend = Legend();

  static const distinctColors = [
    "#03569b", // dark blue
    "#e72f27", // dark red
    "#ffc808", // yellow
    "#a2b324", // dark green
    "#a5b8c7", // grey
    "#049457", // green
    "#f1b066", // pale orange
    "#742f32", // brown
    "#9e806e", // brown
    "#75ada9", // turquoise
    "#675b2c",
    "#a020f0",
    "#8b8989",
    "#e9a390",
    "#dde8cf",
    "#00939f",
  ];
}

// ----------------------------------------------------------------------
