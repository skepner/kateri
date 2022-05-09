// import 'dart:io';
import 'dart:math';
import 'dart:typed_data'; // Uint8List

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart'; // CommandLineData
import 'map-viewer-data.dart';

import 'draw_on.dart';
import 'draw_on_canvas.dart';
import 'draw_on_pdf.dart';
import 'plot_spec.dart';
import 'color.dart';

// ======================================================================

class OpenChartIntent extends Intent {
  const OpenChartIntent();
}

class ReloadChartIntent extends Intent {
  const ReloadChartIntent();
}

class PdfIntent extends Intent {
  const PdfIntent();
}

// ----------------------------------------------------------------------

class AntigenicMapViewWidget extends StatefulWidget {
  const AntigenicMapViewWidget({Key? key, this.width = 500.0, this.aspectRatio = 1.0, this.openExportedPdf = true, this.borderWidth = 5.0, this.borderColor = const Color(0xFF000000)})
      : super(key: key);

  final double width;
  final double aspectRatio;
  final double borderWidth;
  final Color borderColor;
  final bool openExportedPdf;

  @override
  State<AntigenicMapViewWidget> createState() => _AntigenicMapViewWidgetState();
}

// ----------------------------------------------------------------------

class _AntigenicMapViewWidgetState extends State<AntigenicMapViewWidget> implements AntigenicMapViewerCallbacks {
  var scaffoldKey = GlobalKey<ScaffoldState>();

  late final AntigenicMapViewerData _data;

  // String path = "*nothing*";
  // late double width;
  late double aspectRatio;
  late double borderWidth;
  late Color borderColor;
  late AntigenicMapPainter antigenicMapPainter; // re-created upon changing state in build()

  _AntigenicMapViewWidgetState() {
    _data = AntigenicMapViewerData(this);
  }

  @override
  void initState() {
    super.initState();
    // width = widget.width;
    aspectRatio = widget.aspectRatio;
    borderWidth = widget.borderWidth;
    borderColor = widget.borderColor;
    _data.openExportedPdf = widget.openExportedPdf;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final commandLineData = CommandLineData.of(context);
    _data.didChangeDependencies(fileToOpen: commandLineData.fileToOpen, socketToConnect: commandLineData.socketToConnect);
  }

  @override
  Widget build(BuildContext context) {
    _data.buildStarted();
    antigenicMapPainter = AntigenicMapPainter(_data); // must be re-created!
    return Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          LogicalKeySet(LogicalKeyboardKey.f3): const OpenChartIntent(),
          LogicalKeySet(LogicalKeyboardKey.f4): const PdfIntent(),
          LogicalKeySet(LogicalKeyboardKey.f5): const ReloadChartIntent(),
        },
        child: Actions(
            actions: <Type, Action<Intent>>{
              OpenChartIntent: CallbackAction<OpenChartIntent>(onInvoke: (OpenChartIntent intent) => _data.selectAndOpenAceFile()),
              ReloadChartIntent: CallbackAction<ReloadChartIntent>(onInvoke: (ReloadChartIntent intent) => _data.reloadChart()),
              PdfIntent: CallbackAction<PdfIntent>(onInvoke: (PdfIntent intent) => _data.exportPdf()),
            },
            child: Focus(
                child: Container(
                    // margin: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(border: Border.all(color: borderColor, width: borderWidth)),
                    // width: width,
                    child: AspectRatio(
                        aspectRatio: aspectRatio,
                        child: Scaffold(
                            key: scaffoldKey,
                            // appBar: AppBar(), //title: Text("Kateri")),
                            drawer: Drawer(child: AntigenicMapViewWidgetMenu(antigenicMapViewerData: _data)),
                            body: Stack(children: <Widget>[
                              CustomPaint(painter: antigenicMapPainter, size: const Size(99999, 99999)),
                              Positioned(
                                  left: 0,
                                  top: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.menu),
                                    onPressed: () => scaffoldKey.currentState?.openDrawer(),
                                  ))
                            ])))))));
  }

  // ----------------------------------------------------------------------

  @override
  void updateCallback() {
    setState(() {/* AntigenicMapViewerData updated */});
  }

  @override
  void showMessage(String text, {Color backgroundColor = Colors.red}) {
    print("showMessage \"$text\"");
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), backgroundColor: backgroundColor, duration: const Duration(days: 1)));
  }

  @override
  void hideMessage() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  @override
  Future<Uint8List?> exportPdf() async {
    return antigenicMapPainter.viewer.exportPdf();
  }
}

// ----------------------------------------------------------------------

class AntigenicMapViewWidgetMenu extends StatelessWidget {
  const AntigenicMapViewWidgetMenu({Key? key, required this.antigenicMapViewerData}) : super(key: key);

  final AntigenicMapViewerData antigenicMapViewerData;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: EdgeInsets.zero, children: [
      ListTile(
          leading: const Icon(Icons.file_open_rounded),
          title: const Text("Open F3"),
          onTap: () {
            Navigator.pop(context);
            antigenicMapViewerData.selectAndOpenAceFile();
          }),
      ListTile(
          leading: const Icon(Icons.picture_as_pdf_rounded),
          title: const Text("Export pdf F4"),
          onTap: () {
            antigenicMapViewerData.exportPdf();
            Navigator.pop(context);
          }),
      ListTile(
          leading: const Icon(Icons.file_open_rounded),
          title: const Text("Reload F5"),
          onTap: () {
            antigenicMapViewerData.reloadChart();
            Navigator.pop(context);
          }),
    ]);
  }
}

// ----------------------------------------------------------------------

class AntigenicMapPainter extends CustomPainter {
  final AntigenicMapViewer viewer;

  AntigenicMapPainter(AntigenicMapViewerData data) : viewer = AntigenicMapViewer(data);

  @override
  void paint(Canvas canvas, Size size) {
    final stopwatch = Stopwatch()..start();
    viewer.paint(CanvasFlutter(canvas, size));
    // print("[paint] ${chart?.antigens.length}:${chart?.sera.length} ${stopwatch.elapsed} -> ${1e6 / stopwatch.elapsedMicroseconds} frames per second");
    if (stopwatch.elapsedMicroseconds > 100) {
      print("[paint] ${stopwatch.elapsed} -> ${1e6 / stopwatch.elapsedMicroseconds} frames per second");
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// ----------------------------------------------------------------------

class AntigenicMapViewer {
  final AntigenicMapViewerData _data;

  AntigenicMapViewer(this._data);

  void paint(CanvasRoot canvas) {
    if (_data.chart != null && _data.viewport != null) {
      canvas.draw(Offset.zero & canvas.size, _data.viewport!, paintOn);
    }
  }

  void paintOn(DrawOn canvas) {
    _data.plotSpec ??= _data.chart!.plotSpecs(_data.projection)[0];
    canvas.grid();
    final layout = _data.projection!.transformedLayout();
    for (final pointNo in _data.plotSpec!.drawingOrder()) {
      if (layout[pointNo] != null) {
        canvas.pointOfPlotSpec(layout[pointNo]!, _data.plotSpec![pointNo]);
      }
    }
    paintLegend(canvas);
    paintTitle(canvas);
  }

  void paintLegend(DrawOn canvas) {
    final legend = _data.plotSpec?.legend() ?? Legend();

  }

  void paintTitle(DrawOn canvas) {
    final title = _data.plotSpec?.plotTitle() ?? PlotTitle();
    final text = title.text.text, fontSizePixels = title.text.fontSize, textStyle = title.text.labelStyle, interline1 = title.text.interline + 1.0;
    final padding = [title.box.padding_top, title.box.padding_right, title.box.padding_bottom, title.box.padding_left].map((val) => val * canvas.pixelSize).toList();
    final textSize = text.map((line) => canvas.textSize(line, sizePixels: fontSizePixels, textStyle: textStyle)).toList(growable: false);

    final box = _box(canvas, text, textSize, padding, interline1, title.box.origin, title.box.offset);
    canvas.rectangle(
        rect: box, // Rect.fromLTWH(boxX, boxY, boxWidth, boxHeight),
        fill: NamedColor.fromString(title.box.backgroundColor),
        outline: NamedColor.fromString(title.box.borderColor),
        outlineWidthPixels: title.box.borderWidth);

    var dy = box.top + textSize[0].height + padding[0];
    for (var lineNo = 0; lineNo < text.length; ++lineNo) {
      canvas.text(text[lineNo], Offset(box.left + padding[3], dy), sizePixels: fontSizePixels, textStyle: textStyle);
      dy += textSize[lineNo].height * interline1;
    }
  }

  Rect _box(DrawOn canvas, List<String> text, List<Size> textSize, List<double> padding, double interline1, String origin, Offset offsetPixels) {
    final boxWidth = textSize.fold<double>(0.0, (res, ts) => max(res, ts.width)) + padding[3] + padding[1];
    final boxHeight = textSize.skip(1).fold<double>(textSize[0].height, (res, ts) => res + ts.height * interline1) + padding[0] + padding[2];

    double boxX = 0.0, boxY = 0.0;
    switch (origin[0]) {
      case "T":
        boxY = canvas.viewport.top - offsetPixels.dy * canvas.pixelSize - boxHeight;
        break;
      case "t":
        boxY = canvas.viewport.top + offsetPixels.dy * canvas.pixelSize;
        break;
      case "B":
        boxY = canvas.viewport.bottom - offsetPixels.dy * canvas.pixelSize - boxHeight;
        break;
      case "b":
        boxY = canvas.viewport.bottom + offsetPixels.dy * canvas.pixelSize;
        break;
      case "c":
        boxY = canvas.viewport.centerY - offsetPixels.dy * canvas.pixelSize - boxHeight / 2;
        break;
    }
    switch (origin[1]) {
      case "L":
        boxX = canvas.viewport.left - offsetPixels.dx * canvas.pixelSize - boxWidth;
        break;
      case "l":
        boxX = canvas.viewport.left + offsetPixels.dx * canvas.pixelSize;
        break;
      case "R":
        boxX = canvas.viewport.right - offsetPixels.dx * canvas.pixelSize - boxWidth;
        break;
      case "r":
        boxX = canvas.viewport.right + offsetPixels.dx * canvas.pixelSize;
        break;
      case "c":
        boxX = canvas.viewport.centerX - offsetPixels.dx * canvas.pixelSize - boxWidth / 2;
        break;
    }


    return Rect.fromLTWH(boxX, boxY, boxWidth, boxHeight);
  }

  Future<Uint8List?> exportPdf() async {
    if (_data.chart != null && _data.viewport != null) {
      final canvasPdf = CanvasPdf(Size(1000.0, 1000.0 / _data.viewport!.width * _data.viewport!.height))..paintBy(paint);
      return canvasPdf.bytes();
    }
    return null;
  }
}


// ======================================================================
