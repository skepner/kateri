// import 'dart:io';
import 'dart:math';
import 'dart:typed_data'; // Uint8List

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart' as vec;
import 'package:window_manager/window_manager.dart';
import 'package:universal_platform/universal_platform.dart';

import 'app.dart'; // CommandLineData
import 'map-viewer-data.dart';
import 'chart.dart';

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

  late double aspectRatio;
  late double borderWidth;
  late final int _nativeWindowTitleBarHeight;

  late Color borderColor;
  late AntigenicMapPainter antigenicMapPainter; // re-created upon changing state in build()
  late final PointHoveringDetector _pointHoveringDetector;

  static const minMapWidth = 500.0;
  static const menuSectionColumnWidth = 400.0;

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
    _pointHoveringDetector = PointHoveringDetector(data: _data);

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
    _data.buildStarted();
    antigenicMapPainter = AntigenicMapPainter(_data); // must be re-created!
    return AntigenicMapShortcuts(
        callbacks: this,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          buildMapPart(),
          MenuSectionColumnWidget(antigenicMapViewWidgetState: this, columnWidth: menuSectionColumnWidth, hoveredPointsNotifier: _pointHoveringDetector.hoveredPointsNotifier),
        ]));
  }

  Widget buildMapPart() {
    return Expanded(
        child: Container(
            decoration: BoxDecoration(border: Border.all(color: borderColor, width: borderWidth)),
            child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Scaffold(
                    key: scaffoldKey,
                    // appBar: AppBar(), //title: Text("Kateri")),
                    drawer: Drawer(child: AntigenicMapViewWidgetMenu(antigenicMapViewerData: _data)),
                    body: Stack(children: <Widget>[
                      _pointHoveringDetector.build(antigenicMapPainter),
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
                    ])))));
  }

  // ----------------------------------------------------------------------

  // List<Widget> aaPerPosMenu() {
  //   String entryTitle(MapEntry<int, Map<String, int>> entry) {
  //     final val = entry.value.entries.map<String>((ee) => "${ee.key}:${ee.value}").join(" ");
  //     return "${entry.key} $val";
  //   }

  //   return _data.aaPerPos.entries
  //       .map<ListTile>((entry) => ListTile(
  //             title: Text(entryTitle(entry)),
  //             // selected: entry.key == _data.currentPlotSpecIndex,
  //             enableFeedback: false,
  //             onTap: () {
  //               // updateCallback(plotSpecIndex: entry.key);
  //             },
  //             contentPadding: const EdgeInsets.only(),
  //             minVerticalPadding: 0.0,
  //             dense: true,
  //             visualDensity: const VisualDensity(vertical: -2.0),
  //           ))
  //       .toList();
  // }

  // ----------------------------------------------------------------------

  @override
  void updateCallback({int? plotSpecIndex}) {
    // print("plotSpecIndex: $plotSpecIndex");
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

  void setPlotSpecColoredByAA(List<int> positions) {
    updateCallback(plotSpecIndex: _data.addPlotSpecColorByAA(positions));
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
    await windowManager.setSize(Size(defaultWindowWidth + menuSectionColumnWidth, defaultWindowWidth / aspectRatio + _nativeWindowTitleBarHeight), animate: true);
  }

  // @override
  // void onWindowEvent(String eventName) {
  //   print('[WindowManager] onWindowEvent: $eventName');
  // }

  @override
  void onWindowResized() async {
    final windowSize = await windowManager.getSize();
    var targetWidth = windowSize.width;
    if ((targetWidth - menuSectionColumnWidth) < minMapWidth) {
      targetWidth = minMapWidth + menuSectionColumnWidth;
    }
    final targetSize = Size(targetWidth, (targetWidth - menuSectionColumnWidth) / aspectRatio + _nativeWindowTitleBarHeight);
    final diff = Offset(targetSize.width - windowSize.width, targetSize.height - windowSize.height).distanceSquared;
    if (diff > 4.0) await windowManager.setSize(targetSize, animate: true);
    debug("resized $targetSize <- $windowSize");
  }

  // ----------------------------------------------------------------------

}

// ----------------------------------------------------------------------

class _PointElement {
  final int no;
  late final bool antigen;
  late final String name;

  _PointElement(this.no, Chart chart) {
    antigen = no < chart.antigens.length;
    if (antigen) {
      name = chart.antigens[no].designation();
    } else {
      name = chart.sera[no - chart.antigens.length].designation();
    }
  }
}

class PointHoveringDetector {
  final AntigenicMapViewerData data;
  final hoveredPointsNotifier = ValueNotifier<List<_PointElement>>([]);
  late AntigenicMapPainter _antigenicMapPainter;
  static final _lockKeys = Set<LogicalKeyboardKey>.unmodifiable(<LogicalKeyboardKey>[LogicalKeyboardKey.alt, LogicalKeyboardKey.altLeft, LogicalKeyboardKey.altRight]);

  PointHoveringDetector({required this.data});

  Widget build(AntigenicMapPainter antigenicMapPainter) {
    _antigenicMapPainter = antigenicMapPainter;
    return MouseRegion(
      onHover: mouseMoved,
      onExit: mouseExit,
      child: CustomPaint(painter: antigenicMapPainter, size: const Size(99999, 99999)),
    );
  }

  void mouseMoved(PointerEvent ev) {
    if (data.chart != null && data.viewport != null && !isLocked()) {
      final unitSize = _antigenicMapPainter.viewer.canvasSize.width / data.viewport!.width;
      final newlyHoveredPoints = _antigenicMapPainter.viewer.pointLookupByCoordinates
          .lookupByMouseCoordinates(vec.Vector3(ev.position.dx / unitSize + data.viewport!.left, ev.position.dy / unitSize + data.viewport!.top, 0.0))
          .map((index) => _PointElement(index, data.chart!))
          .toList();
      if (!listEquals(newlyHoveredPoints, hoveredPointsNotifier.value)) {
        hoveredPointsNotifier.value = newlyHoveredPoints;
        // print("mouse $newlyHoveredPoints ${Offset(ev.position.dx / unitSize + data.viewport!.left, ev.position.dy / unitSize + data.viewport!.top)} canvas:${_antigenicMapPainter.viewer.canvasSize}");
      }
    }
  }

  void mouseExit(PointerEvent ev) {
    if (!isLocked() && hoveredPointsNotifier.value.isNotEmpty) {
      hoveredPointsNotifier.value = [];
    }
  }

  bool isLocked() {
    return HardwareKeyboard.instance.logicalKeysPressed.intersection(_lockKeys).isNotEmpty;
  }
}

// ----------------------------------------------------------------------

class MenuSectionColumnWidget extends StatefulWidget {
  const MenuSectionColumnWidget({Key? key, required this.antigenicMapViewWidgetState, required this.hoveredPointsNotifier, required this.columnWidth}) : super(key: key);

  final double columnWidth;
  final _AntigenicMapViewWidgetState antigenicMapViewWidgetState;
  final ValueNotifier<List<_PointElement>> hoveredPointsNotifier;

  @override
  State<MenuSectionColumnWidget> createState() => _MenuSectionColumnWidgetState();
}

class _MenuSectionColumnWidgetState extends State<MenuSectionColumnWidget> {
  late final List<_MenuSection> _sections;
  static const antigenColor = Color(0xFF000080);
  static const serumColor = Color(0xFF804000);

  @override
  void initState() {
    _sections = <_MenuSection>[
      _MenuSectionFile(widget.antigenicMapViewWidgetState._data),
      _MenuSectionColorByAA(this),
      _MenuSectionRegion(this),
      _MenuSectionStyles(widget.antigenicMapViewWidgetState, isExpanded: true),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.columnWidth,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: ExpansionPanelList(
              expansionCallback: (int index, bool isExpanded) {
                setState(() {
                  _sections[index].expand(!isExpanded);
                });
              },
              children: _sections.map<ExpansionPanel>((_MenuSection section) => section.build()).toList(),
            ),
            primary: false,
          ),
          ValueListenableBuilder(
              valueListenable: widget.hoveredPointsNotifier,
              builder: (BuildContext context, List<_PointElement> hoveredPoints, Widget? child) {
                if (hoveredPoints.isNotEmpty) {
                  return DecoratedBox(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SelectableText.rich(formatAntigensSera(hoveredPoints)),
                      ),
                      primary: true,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      color: Colors.white,
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }),
        ],
      ),
    );
  }

  TextSpan formatAntigensSera(List<_PointElement> points) {
    return TextSpan(
      children: points.asMap().entries.map<TextSpan>((entry) {
        // final no = entry.value.no.toString().padLeft(4, ' ');
        final nl = (entry.key < (points.length - 1)) ? "\n" : "";
        return TextSpan(
          text: "${entry.value.name}$nl",
          style: TextStyle(color: entry.value.antigen ? antigenColor : serumColor),
        );
      }).toList(),
    );
  }

  void redraw() {
    setState(() {});
  }

  void collapseAll() {
    for (final section in _sections) {
      section.isExpanded = false;
    }
  }
}

abstract class _MenuSection {
  bool isExpanded;

  _MenuSection(this.isExpanded);

  ExpansionPanel build();

  void expand(bool exp) {
    isExpanded = exp;
  }
}

class _MenuSectionFile extends _MenuSection {
  final AntigenicMapViewerData _data;

  _MenuSectionFile(this._data, {bool isExpanded = false}) : super(isExpanded);

  @override
  ExpansionPanel build() {
    return ExpansionPanel(
      canTapOnHeader: true,
      headerBuilder: (BuildContext context, bool isExpanded) => const ListTile(title: Text("File")),
      body: Material(
        color: const Color(0xFFF8F8FF),
        shape: Border.all(color: const Color(0xFFA0A0FF)),
        child: Column(
          children: [
            ListTile(
              title: const Text("Open"),
              onTap: () => _data.openChart(),
            ),
            ListTile(
              title: const Text("Reload"),
              onTap: () => _data.reloadChart(),
            ),
            ListTile(
              title: const Text("Pdf"),
              onTap: () => _data.generatePdf(),
            ),
          ],
        ),
      ),
      isExpanded: isExpanded,
    );
  }
}

class _MenuSectionStyles extends _MenuSection {
  final _AntigenicMapViewWidgetState _parent;

  _MenuSectionStyles(this._parent, {bool isExpanded = false}) : super(isExpanded);

  @override
  ExpansionPanel build() {
    return ExpansionPanel(
      canTapOnHeader: true,
      headerBuilder: (BuildContext context, bool isExpanded) => const ListTile(title: Text("Styles")),
      body: Material(
        color: const Color(0xFFF8FFF8),
        shape: Border.all(color: const Color(0xFFA0FFA0)),
        child: Column(
          children: styleTiles(),
        ),
      ),
      isExpanded: isExpanded,
    );
  }

  List<Widget> styleTiles() {
    return _parent._data.plotSpecs.asMap().entries.map<ListTile>((entry) {
      return ListTile(
        title: Text(entry.value.title()),
        selected: entry.key == _parent._data.currentPlotSpecIndex,
        enableFeedback: false,
        onTap: () => _parent.updateCallback(plotSpecIndex: entry.key),
      );
    }).toList();
  }
}

class _MenuSectionColorByAA extends _MenuSection {
  final _MenuSectionColumnWidgetState _menuSectionColumn;
  late final _focusNode;
  String? _error;

  _MenuSectionColorByAA(this._menuSectionColumn, {bool isExpanded = false}) : super(isExpanded) {
    _focusNode = FocusNode();
  }

  @override
  ExpansionPanel build() {
    return ExpansionPanel(
      canTapOnHeader: true,
      headerBuilder: (BuildContext context, bool isExpanded) => const ListTile(title: Text("Color by AA")),
      body: Material(
        color: const Color(0xFFFFF8F0),
        shape: Border.all(color: const Color(0xFFFFFBA0)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                autofocus: true,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  labelText: "Positions",
                  hintText: "space separated, e.g. 193 156",
                  errorText: _error,
                ),
                onSubmitted: onSubmitted,
              ),
            ),
          ],
        ),
      ),
      isExpanded: isExpanded,
    );
  }

  @override
  void expand(bool exp) {
    super.expand(exp);
    if (isExpanded) {
      // print("requestFocus");
      _focusNode.requestFocus();
    }
  }

  void onSubmitted(String? value) {
    _error = null;
    if (value != null && value.isNotEmpty) {
      try {
        final positions = value.trim().split(" ").map<int>((String elt) {
          final val = int.parse(elt);
          if (val < 1 || val > 550) {
            throw DataError("invalid position");
          }
          return val;
        }).toList();
        _menuSectionColumn.widget.antigenicMapViewWidgetState.setPlotSpecColoredByAA(positions);
        _menuSectionColumn.collapseAll();
        isExpanded = true;
      } on DataError {
        _error = "enter space separated positions";
      }
      _menuSectionColumn.redraw();
    }
    _focusNode.requestFocus();
  }
}

class _MenuSectionRegion extends _MenuSection {
  final _MenuSectionColumnWidgetState _menuSectionColumn;
  String? _error;

  _MenuSectionRegion(this._menuSectionColumn, {bool isExpanded = false}) : super(isExpanded);

  @override
  ExpansionPanel build() {
    return ExpansionPanel(
      canTapOnHeader: true,
      headerBuilder: (BuildContext context, bool isExpanded) => const ListTile(title: Text("Regions")),
      body: Material(
        color: const Color(0xFFFFF8FF),
        shape: Border.all(color: const Color(0xFFFFE0FF)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Vertices",
                  hintText: "small number",
                  errorText: _error,
                ),
                onSubmitted: onSubmitted,
              ),
            ),
          ],
        ),
      ),
      isExpanded: isExpanded,
    );
  }

  void onSubmitted(String? value) {
    _error = null;
    if (value != null && value.isNotEmpty) {
      try {
        final vertices = int.parse(value.trim());
        if (vertices < 3 || vertices > 10) throw DataError("invalid number of vertices");
        isExpanded = true;
      } on DataError {
        _error = "invalid number";
      }
      _menuSectionColumn.redraw();
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
  final List<RegionPath> regions = [
    RegionPath(vertices: const [Offset(-0.5, -0.5), Offset(0.5, -0.5), Offset(0.5, 0.5), Offset(-0.5, 0.5)])
  ];

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
    for (final region in regions) {
      region.paint(canvas);
    }

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

// ----------------------------------------------------------------------

class RegionPath {
  final List<Offset> vertices;
  final Color color;
  final double lineWidthPixels;
  final double vertexSizePixels;

  RegionPath({required this.vertices, this.color = Colors.red, this.lineWidthPixels = 3.0, this.vertexSizePixels = 8.0});

  void paint(DrawOn canvas) {
    canvas.path(vertices, outline: color, lineWidthPixels: lineWidthPixels, close: true);
    for (final vertex in vertices) {
      canvas.point(center: vec.Vector3(vertex.dx, vertex.dy, 0.0), sizePixels: vertexSizePixels, fill: color, outline: color);
    }
  }
}

// ======================================================================
