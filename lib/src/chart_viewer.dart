import 'dart:ui';
import 'dart:typed_data'; // Uint8List

import 'package:vector_math/vector_math_64.dart';

import "chart.dart";
import 'draw_on.dart';
import 'draw_on_pdf.dart';
import 'viewport.dart';
import 'plot_spec.dart';

// ----------------------------------------------------------------------

class ChartViewer {
  final Chart chart;
  final Projection projection;
  late Viewport viewport;
  final CanvasRoot canvas;
  PlotSpec? plotSpec;

  ChartViewer(this.chart, this.canvas) : projection = chart.projections[0] {
    // print(chart.referenceAntigens().map((agNo) => "$agNo ${chart.antigens[agNo].name}").join("\n"));
    viewport = projection.viewport();
    canvas.draw(Offset.zero & canvas.size, viewport, paint);
  }

  void paint(DrawOn canvas) {
    final stopwatch = Stopwatch()..start();
    plotSpec ??= chart.plotSpecLegacy(projection); // chart.plotSpecDefault(projection);
    canvas.grid();
    final layout = projection.transformedLayout();
    for (final pointNo in plotSpec!.drawingOrder()) {
      if (layout[pointNo] != null) {
        canvas.pointOfPlotSpec(layout[pointNo]!, plotSpec![pointNo]);
      }
    }
    print("drawing chart: ${stopwatch.elapsed} -> ${1e6 / stopwatch.elapsedMicroseconds} frames per second");
  }

  Future<Uint8List> exportPdf({bool open = true}) async {
    final canvasPdf = CanvasPdf(Size(1000.0, 1000.0 / viewport.width * viewport.height))..paintBy(paint);
    return canvasPdf.bytes();
  }
}

// ----------------------------------------------------------------------
