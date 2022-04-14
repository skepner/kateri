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
  final Chart? chart;
  final Projection? projection;
  Viewport? viewport;
  PlotSpec? plotSpec;

  ChartViewer(this.chart) : projection = chart?.projections[0] {
    viewport = projection?.viewport();
  }

  void paint(CanvasRoot canvas) {
    if (chart != null && viewport != null) {
      canvas.draw(Offset.zero & canvas.size, viewport!, paintOn);
    }
  }

  void paintOn(DrawOn canvas) {
    plotSpec ??= chart!.plotSpecLegacy(projection); // chart.plotSpecDefault(projection);
    canvas.grid();
    final layout = projection!.transformedLayout();
    for (final pointNo in plotSpec!.drawingOrder()) {
      if (layout[pointNo] != null) {
        canvas.pointOfPlotSpec(layout[pointNo]!, plotSpec![pointNo]);
      }
    }
  }

  Future<Uint8List?> exportPdf({bool open = true}) async {
    if (chart != null && viewport != null) {
      final canvasPdf = CanvasPdf(Size(1000.0, 1000.0 / viewport!.width * viewport!.height))..paintBy(paint);
      return canvasPdf.bytes();
    }
    return null;
  }
}

// ----------------------------------------------------------------------
