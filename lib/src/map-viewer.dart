import 'dart:io';
import 'dart:convert';
import 'dart:typed_data'; // Uint8List

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';

import 'package:universal_platform/universal_platform.dart';

import 'app.dart'; // CommandLineData
import 'chart.dart';
import 'socket-events.dart' as socket_events;
import 'viewport.dart' as vp;
import 'plot_spec.dart';

import 'draw_on.dart';
import 'draw_on_canvas.dart';
import 'draw_on_pdf.dart';

import 'decompress.dart';

// ======================================================================

class AntigenicMapViewerData {
  Chart? chart;
  Projection? projection;
  vp.Viewport? viewport;
  PlotSpec? plotSpec;
  bool chartBeingLoaded = false;
  Socket? _socket;
  Function updateCallback;
  Function showMessage;
  Function? exportPdfToString; // set by AntigenicMapPainter constructor
  late bool openExportedPdf;

  AntigenicMapViewerData({required this.updateCallback, required this.showMessage});

  void setChart(Chart aChart) {
    chart = aChart;
    projection = chart!.projections[0];
    viewport = projection!.viewport();
    chartBeingLoaded = false;
    updateCallback();
  }

  void resetChart() {
    chart = null;
    projection = null;
    viewport = null;
    plotSpec = null;
    chartBeingLoaded = false;
    updateCallback();
  }

  bool empty() => chart != null;

  void buildStarted() {
    if (UniversalPlatform.isMacOS && chart == null && !chartBeingLoaded
        //&& socketToConnect == null
        ) {
      // forcing open dialog here does not work in web and eventually leads to problems
      selectAndOpenAceFile();
    }
  }

  void didChangeDependencies(CommandLineData commandLineData) {
    openLocalAceFile(commandLineData.fileToOpen);
    connectToServer(commandLineData.socketToConnect);
  }

  // ----------------------------------------------------------------------

  Future<void> selectAndOpenAceFile() async {
    final file = (await FilePicker.platform.pickFiles())?.files.single;
    if (file != null) {
      try {
        // accesing file?.path on web always reports an error (regardles of using try/catch)
        if (file.bytes != null) {
          setChart(Chart(decompressBytes(file.bytes!)));
        } else if (file.path != null) {
          setChart(Chart(await decompressFile(file.path!)));
        }
      } on Exception catch (err) {
        // cannot import chart from a file
        showMessage(err.toString());
        resetChart();
      }
    } else {
      resetChart();
    }
  }

  Future<void> openLocalAceFile(String? path) async {
    print("openLocalAceFile path:$path chart:$chart");
    if (chart == null && path != null) {
      try {
        chartBeingLoaded = true;
        if (path == "-") {
          setChart(Chart(await decompressStdin()));
        } else {
          setChart(Chart(await decompressFile(path)));
        }
      } on Exception catch (err) {
        // cannot import chart from a file
        showMessage(err.toString());
        resetChart();
      }
    }
  }

  // ----------------------------------------------------------------------

  void connectToServer(String? socketName) async {
    if (socketName != null) {
      _socket = await Socket.connect(InternetAddress(socketName, type: InternetAddressType.unix), 0);
      socket_events.SocketEventHandler(_socket!).handle(eventFromServer);
      _socket!.write("Hello from Kateri");
    }
  }

  void eventFromServer(socket_events.Event event) {
    print(event);
  }

  // ----------------------------------------------------------------------

  void exportPdf() async {
    if (chart != null && exportPdfToString != null) {
      final stopwatch = Stopwatch()..start();
      final bytes = await exportPdfToString!(); // antigenicMapPainter.viewer.exportPdf();
      if (bytes != null) {
        final filename = await FileSaver.instance.saveFile(chart!.info.nameForFilename(), bytes, "pdf", mimeType: MimeType.PDF);
        if (openExportedPdf && UniversalPlatform.isMacOS) {
          await Process.run("open", [filename]);
        }
      }
      print("[exportPdf] ${stopwatch.elapsed} -> ${1e6 / stopwatch.elapsedMicroseconds} frames per second");
    }
  }
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

class _AntigenicMapViewWidgetState extends State<AntigenicMapViewWidget> {
  var scaffoldKey = GlobalKey<ScaffoldState>();

  late final AntigenicMapViewerData _data;

  // String path = "*nothing*";
  // late double width;
  late double aspectRatio;
  late double borderWidth;
  late Color borderColor;
  late AntigenicMapPainter antigenicMapPainter; // re-created upon changing state in build()

  _AntigenicMapViewWidgetState() {
    _data = AntigenicMapViewerData(updateCallback: updateCallback, showMessage: showMessage);
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
    _data.didChangeDependencies(CommandLineData.of(context));
  }

  @override
  Widget build(BuildContext context) {
    _data.buildStarted();
    antigenicMapPainter = AntigenicMapPainter(_data); // must be re-created!
    return Container(
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
                ]))));
    // }
  }

  // ----------------------------------------------------------------------

  void updateCallback() {
    setState(() {/* AntigenicMapViewerData updated */});
  }

  void showMessage(String text, {Color backgroundColor = Colors.red}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), backgroundColor: backgroundColor, duration: const Duration(days: 1)));
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
          title: const Text("Open"),
          onTap: () {
            Navigator.pop(context);
            antigenicMapViewerData.selectAndOpenAceFile();
          }),
      ListTile(
          leading: const Icon(Icons.picture_as_pdf_rounded),
          title: const Text("Export pdf"),
          onTap: () {
            antigenicMapViewerData.exportPdf();
            Navigator.pop(context);
          }),
    ]);
  }
}

// ----------------------------------------------------------------------

class AntigenicMapPainter extends CustomPainter {
  final AntigenicMapViewer viewer;

  AntigenicMapPainter(AntigenicMapViewerData data) : viewer = AntigenicMapViewer(data) {
    data.exportPdfToString = viewer.exportPdf;
  }

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
    _data.plotSpec ??= _data.chart!.plotSpecLegacy(_data.projection); // chart.plotSpecDefault(projection);
    canvas.grid();
    final layout = _data.projection!.transformedLayout();
    for (final pointNo in _data.plotSpec!.drawingOrder()) {
      if (layout[pointNo] != null) {
        canvas.pointOfPlotSpec(layout[pointNo]!, _data.plotSpec![pointNo]);
      }
    }
  }

  Future<Uint8List?> exportPdf({bool open = true}) async {
    if (_data.chart != null && _data.viewport != null) {
      final canvasPdf = CanvasPdf(Size(1000.0, 1000.0 / _data.viewport!.width * _data.viewport!.height))..paintBy(paint);
      return canvasPdf.bytes();
    }
    return null;
  }
}


// ======================================================================
