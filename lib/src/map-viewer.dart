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

import 'error.dart';
import 'draw_on.dart';
import 'draw_on_canvas.dart';
import 'draw_on_pdf.dart';
import 'plot_spec.dart';
import 'color.dart';
import 'map-shortcuts.dart';

// ======================================================================

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

class _AntigenicMapViewWidgetState extends State<AntigenicMapViewWidget> with WindowListener implements AntigenicMapViewerCallbacks, AntigenicMapShortcutCallbacks {
  var scaffoldKey = GlobalKey<ScaffoldState>();

  late final AntigenicMapViewerData _data;

  // String path = "*nothing*";
  // late double width;
  late double aspectRatio;
  late double borderWidth;
  late final int _nativeWindowTitleBarHeight;

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
      windowManager.getTitleBarHeight().then((titleBarHeight) {
        _nativeWindowTitleBarHeight = titleBarHeight;
        resetWindowSize();
      });
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
    return AntigenicMapShortcuts(
        callbacks: this,
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
                            MouseRegion(
                              onHover: mouseMoved,
                              child: CustomPaint(painter: antigenicMapPainter, size: const Size(99999, 99999)),
                            ),
                            Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.menu),
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => scaffoldKey.currentState?.openDrawer(),
                                ))
                          ]))))),
          SizedBox(
            width: plotStyleMenuWidth,
            child: ListView(
              children: plotStyleMenu(),
            ),
          ),
        ]));
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
      if (UniversalPlatform.isMacOS) {
        onWindowResized();
      }
    }
    setState(() {
      /* AntigenicMapViewerData updated */
    });
  }

  @override
  void showMessage(String text, {Color backgroundColor = Colors.red}) {
    debug("showMessage \"$text\"");
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), backgroundColor: backgroundColor, duration: const Duration(days: 1)));
  }

  @override
  void hideMessage() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  @override
  Future<Uint8List?> exportPdf({double canvasPdfWidth = 800.0}) async {
    return antigenicMapPainter.viewer.exportPdf(canvasPdfWidth: canvasPdfWidth);
  }

  // ----------------------------------------------------------------------

  @override
  void openChart() => _data.openChart();

  @override
  void reloadChart() => _data.reloadChart();

  @override
  void generatePdf() => _data.generatePdf();

  @override
  void resetWindowSize() async {
    const defaultWindowWidth = 785.0;
    await windowManager.setSize(Size(defaultWindowWidth + plotStyleMenuWidth, defaultWindowWidth / aspectRatio + _nativeWindowTitleBarHeight), animate: true);
  }

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
    final targetSize = Size(targetWidth, (targetWidth - plotStyleMenuWidth) / aspectRatio + _nativeWindowTitleBarHeight);
    final diff = Offset(targetSize.width - windowSize.width, targetSize.height - windowSize.height).distanceSquared;
    if (diff > 4.0) await windowManager.setSize(targetSize, animate: true);
    debug("resized $targetSize <- $windowSize");
  }

  // ----------------------------------------------------------------------

  void mouseMoved(PointerEvent ev) {
    if (_data.chart != null && _data.viewport != null) {
      final unitSize = antigenicMapPainter.viewer.canvasSize.width / _data.viewport!.width;
      final hoveredPoints = antigenicMapPainter.viewer.pointLookupByCoordinates
          .lookupByMouseCoordinates(vec.Vector3(ev.position.dx / unitSize + _data.viewport!.left, ev.position.dy / unitSize + _data.viewport!.top, 0.0));
      if (hoveredPoints.length > 0) {
        print("mouse $hoveredPoints ${Offset(ev.position.dx / unitSize + _data.viewport!.left, ev.position.dy / unitSize + _data.viewport!.top)} canvas:${antigenicMapPainter.viewer.canvasSize}");
      }
    }
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
            antigenicMapViewerData.openChart();
          }),
      ListTile(
          leading: const Icon(Icons.picture_as_pdf_rounded),
          title: const Text("Export pdf F4"),
          onTap: () {
            antigenicMapViewerData.generatePdf(width: 800.0);
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
    if (stopwatch.elapsedMicroseconds > 50000) info("[paint] ${stopwatch.elapsed} -> ${1e6 / stopwatch.elapsedMicroseconds} frames per second");
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// ----------------------------------------------------------------------

class AntigenicMapViewer {
  final AntigenicMapViewerData _data;
  var canvasSize = const Size(0, 0);
  final pointLookupByCoordinates = PointLookupByCoordinates();

  AntigenicMapViewer(this._data);

  void paint(CanvasRoot canvas) {
    if (_data.chart != null && _data.viewport != null) {
      canvas.draw(Offset.zero & canvas.size, _data.viewport!, paintOn);
      canvasSize = canvas.size;
    }
  }

  void paintOn(DrawOn canvas) {
    // debug("paintOn");
    pointLookupByCoordinates.clear();
    canvas.grid();
    final layout = _data.projection!.transformedLayout();
    _data.currentPlotSpec.drawingOrder().asMap().forEach((pointDrawingOrder, pointNo) {
      if (layout[pointNo] != null) {
        final pointPlotSpec = _data.currentPlotSpec[pointNo];
        if (pointPlotSpec.shown) {
          canvas.pointOfPlotSpec(layout[pointNo]!, pointPlotSpec);
          pointLookupByCoordinates.addPoint(pointNo: pointNo, position: layout[pointNo]!, size: pointPlotSpec.sizePixels * canvas.pixelSize, drawingOrder: pointDrawingOrder);
        }
      }
    });
    canvas.drawDelayed();
    paintLegend(canvas);
    paintTitle(canvas);
    // pointLookupByCoordinates.report();
  }

  // ----------------------------------------------------------------------

  void paintLegend(DrawOn canvas) {
    final legend = _data.currentPlotSpec.legend();
    if (legend != null && legend.shown) {
      final textFontSize = legend.rowStyle.fontSize, textStyle = legend.rowStyle.labelStyle;
      final countLeftPadding = legend.addCounter ? (textFontSize * canvas.pixelSize * 1.0) : 0.0;
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

  Future<Uint8List?> exportPdf({double canvasPdfWidth = 800.0}) async {
    if (_data.chart != null && _data.viewport != null) {
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

// ----------------------------------------------------------------------

class PointLookupByCoordinates {
  final _data = <_PointLookupByCoordinatesData>[];

  void addPoint({required int pointNo, required vec.Vector3 position, required double size, required int drawingOrder}) {
    _data.add(_PointLookupByCoordinatesData(pointNo: pointNo, position: position, size: size, drawingOrder: drawingOrder));
  }

  void clear() {
    _data.clear();
  }

  // returns list of point indexes under the passed coordinates, first point is drawn on top of others
  List<int> lookupByMouseCoordinates(vec.Vector3 pos) {
    final hovered = _data.where((element) => element.position.distanceTo(pos) <= (element.size / 2)).toList();
    hovered.sort((a, b) => b.drawingOrder.compareTo(a.drawingOrder));
    return hovered.map((element) => element.pointNo).toList();
  }

  void report() => _data.forEach((en) => print(en.toString()));
}

class _PointLookupByCoordinatesData {
  final int pointNo;
  final vec.Vector3 position;
  final double size;
  final int drawingOrder;

  _PointLookupByCoordinatesData({required this.pointNo, required this.position, required this.size, required this.drawingOrder});

  @override
  String toString() => "${pointNo.toString().padLeft(4, ' ')} ${size.toStringAsFixed(3)} $position $drawingOrder";
}

// ======================================================================
