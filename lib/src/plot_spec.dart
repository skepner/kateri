import 'chart.dart';
import 'draw_on.dart';

// ----------------------------------------------------------------------

abstract class PlotSpec {
  List<int> drawingOrder();
  PointPlotSpec operator [](int pointNo);
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
