import 'dart:ui';
import 'chart.dart';
import 'draw_on.dart';

// ----------------------------------------------------------------------

abstract class PlotSpec {
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

class PlotSpecDefault extends PlotSpec {
  PlotSpecDefault(this._chart, this._projection) {
    bool hasCoord(int pointNo) => _projection.layout[pointNo] != null;
    sera = Iterable<int>.generate(_chart.sera.length, (srNo) => srNo + _chart.antigens.length).where(hasCoord).toList();
    referenceAntigens = _chart.referenceAntigens().where(hasCoord).toList();
    testAntigens = Iterable<int>.generate(_chart.antigens.length).where((agNo) => !referenceAntigens.contains(agNo)).where(hasCoord).toList();

    _chart.antigens.asMap().forEach((agNo, antigen) {
      if (referenceAntigens.contains(agNo)) {
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
  List<int> drawingOrder() {
    return sera + referenceAntigens + testAntigens;
  }

  @override
  PointPlotSpec operator [](int pointNo) => pointSpec[pointNo];

  // ----------------------------------------------------------------------

  final Chart _chart;
  final Projection _projection;

  late final List<int> sera, referenceAntigens, testAntigens;
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
