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

  // ----------------------------------------------------------------------

  void paintLegend(DrawOn canvas) {
    final legend = _data.plotSpec?.legend();
    if (legend != null && legend.shown) {
      final box = _BoxData(
          canvas: canvas,
          text: legend.legendRows.map((row) => row.text).toList(),
          titleText: legend.title.text,
          textFontSize: legend.rowStyle.fontSize,
          titleFontSize: legend.title.fontSize,
          textStyle: legend.rowStyle.labelStyle,
          titleStyle: legend.title.labelStyle,
          textInterline: legend.rowStyle.interline,
          titleInterline: legend.title.interline,
          paddingPixels: legend.box.padding,
          offset: legend.box.offset,
          originDirection: legend.box.origin);

      canvas.rectangle(rect: box.rect(), fill: NamedColor.fromString(legend.box.backgroundColor), outline: NamedColor.fromString(legend.box.borderColor), outlineWidthPixels: legend.box.borderWidth);

      final dx = box.origin.dx + box.padding.left;
      var dy = box.origin.dy + box.textSize[0].height + box.padding.top;
      for (var lineNo = 0; lineNo < box.titleText.length; ++lineNo) {
        canvas.text(box.titleText[lineNo], Offset(dx, dy), sizePixels: box.titleFontSize, textStyle: box.titleStyle);
        dy += box.titleSize[lineNo].height * (box.titleInterline + 1.0);
      }
      for (var lineNo = 0; lineNo < box.text.length; ++lineNo) {
        canvas.text(box.text[lineNo], Offset(dx, dy), sizePixels: box.textFontSize, textStyle: box.textStyle);
        if (true || legend.addCounter) {
          canvas.text(legend.legendRows[lineNo].count.toString(), Offset(dx + box.maxTextWidth, dy), sizePixels: box.textFontSize, textStyle: box.textStyle);
        }
        dy += box.textSize[lineNo].height * (box.textInterline + 1.0);
      }
    }
  }

  void paintTitle(DrawOn canvas) {
    final title = _data.plotSpec?.plotTitle() ?? PlotTitle();
    final box = _BoxData(
        canvas: canvas,
        text: title.text.text,
        textFontSize: title.text.fontSize,
        textStyle: title.text.labelStyle,
        textInterline: title.text.interline,
        paddingPixels: title.box.padding,
        offset: title.box.offset,
        originDirection: title.box.origin);

    canvas.rectangle(rect: box.rect(), fill: NamedColor.fromString(title.box.backgroundColor), outline: NamedColor.fromString(title.box.borderColor), outlineWidthPixels: title.box.borderWidth);

    var dy = box.origin.dy + box.textSize[0].height + box.padding.top;
    for (var lineNo = 0; lineNo < box.text.length; ++lineNo) {
      canvas.text(box.text[lineNo], Offset(box.origin.dx + box.padding.left, dy), sizePixels: box.textFontSize, textStyle: box.textStyle);
      dy += box.textSize[lineNo].height * (box.textInterline + 1.0);
    }
  }

  Future<Uint8List?> exportPdf() async {
    if (_data.chart != null && _data.viewport != null) {
      final canvasPdf = CanvasPdf(Size(1000.0, 1000.0 / _data.viewport!.width * _data.viewport!.height))..paintBy(paint);
      return canvasPdf.bytes();
    }
    return null;
  }
}

class _BoxData {
  _BoxData(
      {required DrawOn canvas,
      required this.text,
      this.titleText = const <String>[],
      required this.textFontSize,
      this.titleFontSize = 0.0,
      required this.textStyle,
      this.titleStyle = const LabelStyle(),
      required this.textInterline,
      this.titleInterline = 0.0,
      required Offset offset,
      required BoxPadding paddingPixels,
      required String originDirection})
      : textSize = text.map((line) => canvas.textSize(line, sizePixels: textFontSize, textStyle: textStyle)).toList(growable: false),
        titleSize = titleText.map((line) => canvas.textSize(line, sizePixels: titleFontSize, textStyle: titleStyle)).toList(growable: false),
        padding = paddingPixels * canvas.pixelSize {
    _size(canvas);
    origin = Offset(_originX(canvas, offset.dx, originDirection[1]), _originY(canvas, offset.dy, originDirection[0]));
  }

  Rect rect() => origin & size;

  void _size(DrawOn canvas) {
    maxTextWidth = textSize.fold<double>(0.0, (res, ts) => max(res, ts.width));
    var width = maxTextWidth, height = textSize.skip(1).fold<double>(textSize[0].height, (res, ts) => res + ts.height * (textInterline + 1.0));
    if (titleSize.isNotEmpty) {
      width = titleSize.fold<double>(width, (res, ts) => max(res, ts.width));
      height += titleSize.skip(1).fold<double>(titleSize[0].height, (res, ts) => res + ts.height * (titleInterline + 1.0));
    }
    height += textSize[0].height * 0.4; // space at the bottom to somehow match font ascent
    size = Size(width + padding.left + padding.right, height + padding.top + padding.bottom);
  }

  double _originX(DrawOn canvas, double offset, String originDirection) {
    switch (originDirection) {
      case "L":
        return canvas.viewport.left + offset * canvas.pixelSize - size.width;
      case "l":
        return canvas.viewport.left + offset * canvas.pixelSize;
      case "R":
        return canvas.viewport.right + offset * canvas.pixelSize - size.width;
      case "r":
        return canvas.viewport.right + offset * canvas.pixelSize;
      case "c":
        return canvas.viewport.centerX + offset * canvas.pixelSize - size.width / 2;
    }
    return 0.0;
  }

  double _originY(DrawOn canvas, double offset, String originDirection) {
    switch (originDirection) {
      case "T":
        return canvas.viewport.top - offset * canvas.pixelSize - size.height;
      case "t":
        return canvas.viewport.top + offset * canvas.pixelSize;
      case "B":
        return canvas.viewport.bottom + offset * canvas.pixelSize - size.height;
      case "b":
        return canvas.viewport.bottom + offset * canvas.pixelSize;
      case "c":
        return canvas.viewport.centerY + offset * canvas.pixelSize - size.height / 2;
    }
    return 0.0;
  }

  final List<String> text, titleText;
  final List<Size> textSize, titleSize;
  final double textFontSize, titleFontSize;
  final LabelStyle textStyle, titleStyle;
  final double textInterline, titleInterline;
  late final BoxPadding padding;
  late final Size size;
  late final Offset origin;
  late final double maxTextWidth;
}


// ======================================================================
