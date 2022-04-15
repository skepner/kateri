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
  const AntigenicMapViewWidget({Key? key, this.width = 500.0, this.aspectRatio = 1.0, this.borderWidth = 5.0, this.borderColor = const Color(0xFF000000)}) : super(key: key);

  // setup
  final double width;
  final double aspectRatio;
  final double borderWidth;
  final Color borderColor;

  @override
  State<AntigenicMapViewWidget> createState() => _AntigenicMapViewWidgetState();
}

class _AntigenicMapViewWidgetState extends State<AntigenicMapViewWidget> {
  var scaffoldKey = GlobalKey<ScaffoldState>();

  Chart? chart;
  String path = "*nothing*";
  // late double width;
  late double aspectRatio;
  late double borderWidth;
  late Color borderColor;
  // late AntigenicMapPainter antigenicMapPainter;

  @override
  void initState() {
    super.initState();
    // width = widget.width;
    aspectRatio = widget.aspectRatio;
    borderWidth = widget.borderWidth;
    borderColor = widget.borderColor;

    // antigenicMapPainter = AntigenicMapPainter(this);
    chart = Chart(localPath: "/r/h1pdm-hi-turkey-vidrl.chain.ace");
  }

  @override
  Widget build(BuildContext context) {
    print("_AntigenicMapViewWidgetState.build");
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
                  // Column(children: [Container(color: orange, child: Text("path: $path")), Container(color: Colors.green, child: Text("path: $path"))]),
                  // Center(child: Container(color: borderColor /*  Colors.orange */, child: Text("path: $path $borderColor"))),
                  CustomPaint(painter: AntigenicMapPainter(chart), size: const Size(99999, 99999)),
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
      setChart(Chart(bytes: file?.bytes));
    } else {
      setChart(Chart(localPath: file?.path));
    }
  }

  void setChart(Chart? newChart) {
    setState(() {
      chart = newChart;
      // antigenicMapPainter.chartUpdated();
    });
  }

  // void setColor(Color color) {
  //   setState(() {
  //     borderColor = color;
  //     print("borderColor $borderColor");
  //   });
  // }

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
            Navigator.pop(context);
          }),
      // ListTile(
      //     title: Text("3"),
      //     onTap: () {
      //       Navigator.pop(context);
      //     }),
      // ListTile(
      //     title: Text("4"),
      //     onTap: () {
      //       Navigator.pop(context);
      //     }),
      // ListTile(
      //     title: Text("5"),
      //     onTap: () {
      //       Navigator.pop(context);
      //     }),
      // ListTile(
      //     title: Text("6"),
      //     onTap: () {
      //       Navigator.pop(context);
      //     }),
      // ListTile(
      //     title: Text("7"),
      //     onTap: () {
      //       Navigator.pop(context);
      //     }),
      // ListTile(
      //     title: Text("8"),
      //     onTap: () {
      //       Navigator.pop(context);
      //     }),
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

  // void exportPdf({bool open = true}) async {
  //   if (chart != null) {
  //     final bytes = await viewer.exportPdf();
  //     if (bytes != null) {
  //       final filename = await FileSaver.instance.saveFile(chart!.info.nameForFilename(), bytes, "pdf", mimeType: MimeType.PDF);
  //       if (open && UniversalPlatform.isMacOS) {
  //         await Process.run("open-and-back-to-emacs", [filename]);
  //       }
  //     }
  //   }
  // }

  // void openAceFile() async {
  //   final file = (await FilePicker.platform.pickFiles())?.files.single;

  //   // accesing file?.path on web always reports an error (regardles of using try/catch)
  //   if (file?.bytes != null) {
  //     setChart(Chart(bytes: file?.bytes));
  //   } else {
  //     setChart(Chart(localPath: file?.path));
  //   }
  // }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// ======================================================================
