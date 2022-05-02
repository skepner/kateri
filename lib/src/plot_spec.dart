import 'dart:ui';
import 'chart.dart';
import 'draw_on.dart';

// ----------------------------------------------------------------------

abstract class PlotSpec {
  String title();
  List<int> drawingOrder();
  PointPlotSpec operator [](int pointNo);

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

class PlotSpecDefault extends PlotSpec with _DefaultDrawingOrder {
  PlotSpecDefault(this._chart, this._projection) {
    makeDefaultDrawingOrder(_chart, _projection);
    _chart.antigens.asMap().forEach((agNo, antigen) {
      if (ddoReferenceAntigens.contains(agNo)) {
        if (antigen.isReassortant) {
          pointSpec.add(referenceReassortant);
        } else if (antigen.isEgg) {
          pointSpec.add(referenceEgg);
        } else {
          pointSpec.add(referenceCell);
        }
      } else {
        if (antigen.isReassortant) {
          pointSpec.add(testReassortant);
        } else if (antigen.isEgg) {
          pointSpec.add(testEgg);
        } else {
          pointSpec.add(testCell);
        }
      }
    });
    _chart.sera.asMap().forEach((srNo, serum) {
      if (serum.isReassortant) {
        pointSpec.add(serumReassortant);
      } else if (serum.isEgg) {
        pointSpec.add(serumEgg);
      } else {
        pointSpec.add(serumCell);
      }
    });
  }

  @override
  String title() => "Default";

  @override
  List<int> drawingOrder() {
    return ddoSera + ddoReferenceAntigens + ddoTestAntigens;
  }

  @override
  PointPlotSpec operator [](int pointNo) => pointSpec[pointNo];

  // ----------------------------------------------------------------------

  final Chart _chart;
  final Projection _projection;

  final List<PointPlotSpec> pointSpec = [];
  final PointPlotSpec referenceCell = PointPlotSpec.referenceCell(),
      referenceEgg = PointPlotSpec.referenceEgg(),
      referenceReassortant = PointPlotSpec.referenceReassortant(),
      testCell = PointPlotSpec.testCell(),
      testEgg = PointPlotSpec.testEgg(),
      testReassortant = PointPlotSpec.testReassortant(),
      serumCell = PointPlotSpec.serumCell(),
      serumEgg = PointPlotSpec.serumEgg(),
      serumReassortant = PointPlotSpec.serumReassortant();
}

// ----------------------------------------------------------------------

class PlotSpecSemantic extends PlotSpec with _DefaultDrawingOrder {
  PlotSpecSemantic(this._chart, this._projection, this._name, this._data) {
    makeDefaultDrawingOrder(_chart, _projection);
    _drawingOrder = ddoSera + ddoReferenceAntigens + ddoTestAntigens;
  }

  @override
  String title() => _data["T"] ?? _name;

  @override
  List<int> drawingOrder() => _drawingOrder;

  @override
  PointPlotSpec operator [](int pointNo) {
    return PointPlotSpec();
  }

  final Chart _chart;
  final Projection _projection;

  final String _name;
  final Map<String, dynamic> _data;

  late final List<int> _drawingOrder;
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
      spec.rotation = entry["r"]?.toDouble() ?? NoRotation;
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

  final Chart _chart;
  final Map<String, dynamic> _data;
  final List<PointPlotSpec> _specs = [];
}

// ----------------------------------------------------------------------
