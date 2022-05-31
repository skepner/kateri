// import 'dart:io';
import 'dart:math';
import 'dart:typed_data'; // Uint8List

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:vector_math/vector_math_64.dart' as vec;
import 'package:window_manager/window_manager.dart';
import 'package:universal_platform/universal_platform.dart';

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
  const AntigenicMapViewWidget({Key? key, this.width = 1000.0, this.openExportedPdf = true, this.borderWidth = 1.0, this.borderColor = const Color(0xFF808080)}) : super(key: key);

  final double width;
  final double borderWidth;
  final Color borderColor;
  final bool openExportedPdf;

  @override
  State<AntigenicMapViewWidget> createState() => _AntigenicMapViewWidgetState();
}

// ----------------------------------------------------------------------

class _AntigenicMapViewWidgetState extends State<AntigenicMapViewWidget> with WindowListener implements AntigenicMapViewerCallbacks {
  var scaffoldKey = GlobalKey<ScaffoldState>();

  late final AntigenicMapViewerData _data;

  // String path = "*nothing*";
  // late double width;
  late double aspectRatio;
  late double borderWidth;
  late Color borderColor;
  late AntigenicMapPainter antigenicMapPainter; // re-created upon changing state in build()

  static const plotStyleMenuWidth = 200.0;
  static const minMapWidth = 500.0;

  _AntigenicMapViewWidgetState() {
    _data = AntigenicMapViewerData(this);
  }

  @override
  void initState() {
    // width = widget.width;
    aspectRatio = 1.0;
    borderWidth = widget.borderWidth;
    borderColor = widget.borderColor;
    _data.openExportedPdf = widget.openExportedPdf;

    if (UniversalPlatform.isMacOS) {
      windowManager.addListener(this);
      windowManager.ensureInitialized();
    }
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final commandLineData = CommandLineData.of(context);
    _data.didChangeDependencies(fileToOpen: commandLineData.fileToOpen, socketToConnect: commandLineData.socketToConnect);
  }

  @override
  Widget build(BuildContext context) {
    // print("build context: $context");
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
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Container(
                      decoration: BoxDecoration(border: Border.all(color: borderColor, width: borderWidth)),
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
                              ]))))),
              SizedBox(
                width: plotStyleMenuWidth,
                child: ListView(
                  children: plotStyleMenu(),
                ),
              ),
            ]))));
  }

  // ----------------------------------------------------------------------

  List<ListTile> plotStyleMenu() {
    return _data.plotSpecs
        .asMap()
        .entries
        .map<ListTile>((entry) => ListTile(
            title: Text(entry.value.title()),
            // selectedTileColor: Color(0xFFF0F0FF)
            selected: entry.key == _data.currentPlotSpecIndex,
            enableFeedback: false,
            onTap: () {
              updateCallback(plotSpecIndex: entry.key);
            }))
        .toList();
  }

  // ----------------------------------------------------------------------

  @override
  void updateCallback({int? plotSpecIndex}) {
    if (plotSpecIndex != null && plotSpecIndex != _data.currentPlotSpecIndex) {
      _data.setPlotSpec(plotSpecIndex);
      aspectRatio = _data.viewport?.aspectRatio() ?? 1.0;
      onWindowResized();
    }
    setState(() {
      /* AntigenicMapViewerData updated */
    });
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

  // ----------------------------------------------------------------------

  // @override
  // void onWindowEvent(String eventName) {
  //   print('[WindowManager] onWindowEvent: $eventName');
  // }

  @override
  void onWindowResized() async {
    final windowSize = await windowManager.getSize();
    var targetWidth = windowSize.width;
    if ((targetWidth - plotStyleMenuWidth) < minMapWidth) {
      targetWidth = minMapWidth + plotStyleMenuWidth;
    }
    final targetSize = Size(targetWidth, (targetWidth - plotStyleMenuWidth) / aspectRatio + 30.0);
    final diff = Offset(targetSize.width - windowSize.width, targetSize.height - windowSize.height).distanceSquared;
    if (diff > 4.0) await windowManager.setSize(targetSize, animate: true);
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
  final AntigenicMapViewerData _data;

  AntigenicMapPainter(this._data) : viewer = AntigenicMapViewer(_data);

  @override
  void paint(Canvas canvas, Size size) {
    final stopwatch = Stopwatch()..start();
    _data.antigenicMapPainterSize = size; // to auto-resize window
    viewer.paint(CanvasFlutter(canvas, size));
    if (stopwatch.elapsedMicroseconds > 5000) {
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
    canvas.grid();
    final layout = _data.projection!.transformedLayout();
    for (final pointNo in _data.currentPlotSpec.drawingOrder()) {
      if (layout[pointNo] != null) {
        final pointPlotSpec = _data.currentPlotSpec[pointNo];
        if (pointPlotSpec.shown) {
          canvas.pointOfPlotSpec(layout[pointNo]!, pointPlotSpec);
        }
      }
    }
    canvas.drawDelayedText();
    paintLegend(canvas);
    paintTitle(canvas);
  }

  // ----------------------------------------------------------------------

  void paintLegend(DrawOn canvas) {
    final legend = _data.currentPlotSpec.legend();
    if (legend != null && legend.shown) {
      final textFontSize = legend.rowStyle.fontSize, textStyle = legend.rowStyle.labelStyle;
      final countLeftPadding = legend.addCounter ? textFontSize * canvas.pixelSize * 0.5 : 0.0;
      final countTextWidth = legend.addCounter
          ? legend.legendRows.map((row) => row.count.toString()).map((txt) => canvas.textSize(txt, sizePixels: textFontSize, textStyle: textStyle)).map((sz) => sz.width).toList()
          : <double>[];
      final pointSizePixels = legend.pointSize;
      final pointSize = pointSizePixels * canvas.pixelSize;
      final pointSpace = pointSize * (legend.rowStyle.interline + 1.2);
      final maxCountTextWidth = countTextWidth.fold<double>(0.0, max);
      final box = _BoxData(
          canvas: canvas,
          text: legend.legendRows.map((row) => row.text).toList(),
          titleText: legend.title.text,
          textFontSize: textFontSize,
          titleFontSize: legend.title.fontSize,
          textStyle: textStyle,
          titleStyle: legend.title.labelStyle,
          textInterline: legend.rowStyle.interline,
          titleInterline: legend.title.interline,
          paddingPixels: legend.box.padding,
          paddingAddition: BoxPadding(left: pointSpace, right: countLeftPadding + maxCountTextWidth),
          offset: legend.box.offset,
          originDirection: legend.box.originDirection);

      canvas.rectangle(rect: box.rect(), fill: NamedColor.fromString(legend.box.backgroundColor), outline: NamedColor.fromString(legend.box.borderColor), outlineWidthPixels: legend.box.borderWidth);

      // canvas.rectangle(rect: box.origin & Size(box.padding.left, box.size.height));
      final dx = box.origin.dx + box.padding.left;
      var dy = box.origin.dy + box.textSize[0].height + box.padding.top;
      for (var lineNo = 0; lineNo < box.titleText.length; ++lineNo) {
        final size = canvas.textSize(box.titleText[lineNo], sizePixels: box.titleFontSize, textStyle: box.titleStyle);
        final textDx = dx + (box.size.width - box.padding.left - box.padding.right - size.width) / 2; // title centered
        canvas.text(box.titleText[lineNo], Offset(textDx, dy), sizePixels: box.titleFontSize, textStyle: box.titleStyle);
        dy += box.titleSize[lineNo].height * (box.titleInterline + 1.0);
      }
      for (var lineNo = 0; lineNo < box.text.length; ++lineNo) {
        final pointSpec = legend.legendRows[lineNo].point;
        canvas.point(
            center: vec.Vector3(dx + pointSize / 2, dy - box.textSize[lineNo].height * 0.35, 0.0),
            sizePixels: pointSizePixels,
            shape: pointSpec.shape,
            fill: pointSpec.fill.color,
            outline: pointSpec.outline.color,
            outlineWidthPixels: pointSpec.outlineWidthPixels);
        canvas.text(box.text[lineNo], Offset(dx + pointSpace, dy), sizePixels: box.textFontSize, textStyle: box.textStyle);
        if (legend.addCounter) {
          canvas.text(legend.legendRows[lineNo].count.toString(), Offset(dx + pointSpace + box.maxTextWidth + countLeftPadding + maxCountTextWidth - countTextWidth[lineNo], dy),
              sizePixels: box.textFontSize, textStyle: box.textStyle);
        }
        dy += box.textSize[lineNo].height * (box.textInterline + 1.0);
      }
    }
  }

  void paintTitle(DrawOn canvas) {
    final title = _data.currentPlotSpec.plotTitle();
    if (title != null && title.shown) {
      final box = _BoxData(
          canvas: canvas,
          text: title.text.text,
          textFontSize: title.text.fontSize,
          textStyle: title.text.labelStyle,
          textInterline: title.text.interline,
          paddingPixels: title.box.padding,
          offset: title.box.offset,
          originDirection: title.box.originDirection);

      canvas.rectangle(rect: box.rect(), fill: NamedColor.fromString(title.box.backgroundColor), outline: NamedColor.fromString(title.box.borderColor), outlineWidthPixels: title.box.borderWidth);

      var dy = box.origin.dy + box.textSize[0].height + box.padding.top;
      for (var lineNo = 0; lineNo < box.text.length; ++lineNo) {
        canvas.text(box.text[lineNo], Offset(box.origin.dx + box.padding.left, dy), sizePixels: box.textFontSize, textStyle: box.textStyle);
        dy += box.textSize[lineNo].height * (box.textInterline + 1.0);
      }
    }
  }

  Future<Uint8List?> exportPdf() async {
    if (_data.chart != null && _data.viewport != null) {
      const canvasPdfWidth = 1000.0;
      final canvasPdf = CanvasPdf(Size(canvasPdfWidth, canvasPdfWidth / _data.viewport!.width * _data.viewport!.height))..paintBy(paint);
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
      BoxPadding paddingAddition = const BoxPadding.zero(), // for legend points and counts (scaled)
      required String originDirection})
      : textSize = text.map((line) => canvas.textSize(line, sizePixels: textFontSize, textStyle: textStyle)).toList(growable: false),
        titleSize = titleText.map((line) => canvas.textSize(line, sizePixels: titleFontSize, textStyle: titleStyle)).toList(growable: false),
        padding = paddingPixels * canvas.pixelSize {
    _size(canvas, paddingAddition);
    origin = Offset(_originX(canvas, offset.dx, originDirection[1]), _originY(canvas, offset.dy, originDirection[0]));
  }

  Rect rect() => origin & size;

  void _size(DrawOn canvas, BoxPadding paddingAddition) {
    maxTextWidth = textSize.fold<double>(0.0, (res, ts) => max(res, ts.width));
    var width = maxTextWidth, height = textSize.skip(1).fold<double>(textSize[0].height, (res, ts) => res + ts.height * (textInterline + 1.0));
    if (titleSize.isNotEmpty) {
      width = titleSize.fold<double>(width, (res, ts) => max(res, ts.width));
      height += titleSize.skip(1).fold<double>(titleSize[0].height, (res, ts) => res + ts.height * (titleInterline + 1.0));
    }
    height += textSize[0].height * 0.4; // space at the bottom to somehow match font ascent
    size = Size(width + padding.left + padding.right + paddingAddition.left + paddingAddition.right, height + padding.top + padding.bottom + paddingAddition.top + paddingAddition.bottom);
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
