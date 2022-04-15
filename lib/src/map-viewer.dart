import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';

import 'package:universal_platform/universal_platform.dart';

import 'chart-viewer.dart';
import 'chart.dart';

// import 'draw_on.dart';
import 'draw_on_canvas.dart';
// import 'draw_on_pdf.dart';

// ======================================================================

class AntigenicMapViewWidget extends StatefulWidget {
  const AntigenicMapViewWidget({Key? key, this.width = 500.0, this.aspectRatio = 1.0, this.openExportedPdf = true, this.borderWidth = 5.0, this.borderColor = const Color(0xFF000000)})
      : super(key: key);

  // setup
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

  Chart? chart;
  String path = "*nothing*";
  late bool openExportedPdf;
  // late double width;
  late double aspectRatio;
  late double borderWidth;
  late Color borderColor;
  late AntigenicMapPainter antigenicMapPainter; // re-created upon changing state in build()

  @override
  void initState() {
    super.initState();
    // width = widget.width;
    aspectRatio = widget.aspectRatio;
    borderWidth = widget.borderWidth;
    borderColor = widget.borderColor;
    openExportedPdf = widget.openExportedPdf;

    chart = Chart(localPath: "/r/h1pdm-hi-turkey-vidrl.chain.ace");
  }

  @override
  Widget build(BuildContext context) {
    antigenicMapPainter = AntigenicMapPainter(chart); // must be re-created!
    return Container(
        // margin: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(border: Border.all(color: borderColor, width: borderWidth)),
        // width: width,
        child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Scaffold(
                key: scaffoldKey,
                // appBar: AppBar(), //title: Text("Kateri")),
                drawer: Drawer(child: AntigenicMapViewWidgetMenu(antigenicMapViewWidgetState: this)),
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
  }

  // ----------------------------------------------------------------------

  void openAceFile() async {
    final file = (await FilePicker.platform.pickFiles())?.files.single;

    // accesing file?.path on web always reports an error (regardles of using try/catch)
    if (file?.bytes != null) {
      setState(() { chart = Chart(bytes: file?.bytes); });
    } else {
      setState(() { chart = Chart(localPath: file?.path); });
    }
  }

  void exportPdf() async {
    if (chart != null) {
      final stopwatch = Stopwatch()..start();
      final bytes = await antigenicMapPainter.viewer.exportPdf();
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

class AntigenicMapViewWidgetMenu extends StatelessWidget {
  const AntigenicMapViewWidgetMenu({Key? key, required this.antigenicMapViewWidgetState}) : super(key: key);

  final _AntigenicMapViewWidgetState antigenicMapViewWidgetState;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: EdgeInsets.zero, children: [
      ListTile(
          leading: const Icon(Icons.file_open_rounded),
          title: const Text("Open"),
          onTap: () {
            Navigator.pop(context);
            antigenicMapViewWidgetState.openAceFile();
          }),
      ListTile(
          leading: const Icon(Icons.picture_as_pdf_rounded),
          title: const Text("Export pdf"),
          onTap: () {
            antigenicMapViewWidgetState.exportPdf();
            Navigator.pop(context);
          }),
    ]);
  }
}

// ----------------------------------------------------------------------

class AntigenicMapPainter extends CustomPainter {
  final ChartViewer viewer;

  AntigenicMapPainter(Chart? chart) : viewer = ChartViewer(chart);

  @override
  void paint(Canvas canvas, Size size) {
    final stopwatch = Stopwatch()..start();
    viewer.paint(CanvasFlutter(canvas, size));
    // print("[paint] ${chart?.antigens.length}:${chart?.sera.length} ${stopwatch.elapsed} -> ${1e6 / stopwatch.elapsedMicroseconds} frames per second");
    print("[paint] ${stopwatch.elapsed} -> ${1e6 / stopwatch.elapsedMicroseconds} frames per second");
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// ======================================================================