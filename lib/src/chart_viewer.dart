import 'dart:ui';
import 'dart:typed_data'; // Uint8List

import "chart.dart";
import 'draw_on.dart';
import 'draw_on_pdf.dart';

// ----------------------------------------------------------------------

class ChartViewer {
  final Chart chart;
  final Projection projection;
  late final Rect viewport;
  final CanvasRoot canvas;

  ChartViewer(this.chart, this.canvas) : projection = chart.projection(0) {
    viewport = projection.viewport();
    canvas.draw(Offset.zero & canvas.size, viewport, paint);
  }

  void paint(DrawOn canvas) {
    canvas.grid();
    for (var point in projection.layout()) {
      // print(point);
      // assert(point is List<dynamic>);
      if (point != null) {
        canvas.point(center: point, sizePixels: 10, shape: PointShape.circle, fill: const Color(0xFF00FF00), outlineWidthPixels: 1);
      }
    }
  }

  Future<Uint8List> exportPdf({bool open = true}) async {
    final canvasPdf = CanvasPdf(Size(1000.0, 1000.0 / viewport.width * viewport.height))..paintBy(paint);
    return canvasPdf.bytes();
  }
}

// ----------------------------------------------------------------------
