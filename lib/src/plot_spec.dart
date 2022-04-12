import 'chart.dart';

// ----------------------------------------------------------------------

abstract class PlotSpec {
  List<int> drawingOrder();
}

// ----------------------------------------------------------------------

class PlotSpecDefault extends PlotSpec {
  PlotSpecDefault(this._chart, this._projection);

  @override
  List<int> drawingOrder() {
    bool hasCoord(int pointNo) => _projection.layout[pointNo] != null;
    final sera = Iterable<int>.generate(_chart.sera.length, (srNo) => srNo + _chart.antigens.length).where(hasCoord).toList();
    final referenceAntigens = _chart.referenceAntigens().where(hasCoord).toList();
    final testAntigens = Iterable<int>.generate(_chart.antigens.length).where((agNo) => !referenceAntigens.contains(agNo)).where(hasCoord).toList();
    return sera + referenceAntigens + testAntigens;
  }

  Chart _chart;
  Projection _projection;
}

// ----------------------------------------------------------------------
