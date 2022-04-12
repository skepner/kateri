// import 'dart:ui';
import 'dart:io';
import 'dart:typed_data';
// import 'dart:math' as math;

// import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart'; // MouseRegion
import 'package:universal_platform/universal_platform.dart';

import 'package:intl/intl.dart';

// import 'package:file_selector/file_selector.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';

// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;

// import 'package:path_provider/path_provider.dart';

import 'src/chart.dart';

import 'src/draw_on.dart';
import 'src/draw_on_canvas.dart';
import 'src/draw_on_pdf.dart';

import 'src/chart_viewer.dart';

// import 'src/sample/drawings1.dart' as sample_drawings1;
// import 'src/sample/drawings2.dart' as sample_drawings2;

// ----------------------------------------------------------------------

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _updateLocation(PointerEvent details) {
    // print("_updateLocation $details");
  }

  @override
  Widget build(BuildContext context) {
    final antigenicMapPainter = AntigenicMapPainter();

    print("_MyHomePageState build");
    return Scaffold(
      appBar: AppBar(
        title: Text('Kateri ${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())}'),
        backgroundColor: Colors.green,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.file_open),
            tooltip: 'Open ace file',
            onPressed: () {
              antigenicMapPainter.openAceFile();
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export pdf',
            onPressed: () {
              antigenicMapPainter.exportPdf();
            },
          ),
        ],
      ),
      body: MouseRegion(
        onHover: _updateLocation,
        child: CustomPaint(
          painter: antigenicMapPainter,
          size: const Size(99999, 99999),
        ),
      ),
      // body: ListView(children: <Widget>[
      //   CustomPaint(
      //     painter: AntigenicMapPainter(),
      //     size: const Size(1000, 1000),
      //   ),
      // ]),
      // body: ListView(children: <Widget>[
      //   Container(
      //     // width: 1000,
      //     // height: 1000,
      //     child: CustomPaint(
      //       painter: AntigenicMapPainter(),
      //       size: Size(1000, 1000),
      //     ),
      //   ),
      // ]),
    );
  }
}

// ----------------------------------------------------------------------

class AntigenicMapPainter extends CustomPainter {
  Chart? chart;
  ChartViewer? viewer;

  @override
  void paint(Canvas canvas, Size size) {
    chart = Chart(localPath: "/r/h1pdm-hi-turkey-vidrl.chain.ace");
    paintOn(CanvasFlutter(canvas, size));
  }

  void exportPdf({bool open = true}) async {
    if (chart != null && viewer != null) {
      final filename = await FileSaver.instance.saveFile(chart!.info.nameForFilename(), await viewer!.exportPdf(), "pdf", mimeType: MimeType.PDF);
      if (open && UniversalPlatform.isMacOS) {
        await Process.run("open-and-back-to-emacs", [filename]);
      }
    }
  }

  void openAceFile() async {
    final file = (await FilePicker.platform.pickFiles())?.files.single;
    chart = Chart(bytes: file?.bytes, localPath: file?.path);
  }

  void paintOn(CanvasRoot canvas) {
    // if (chart != null) {
    //   print("${chart!.name()} projections: ${chart!.numberOfProjections()}");
    // }
    ChartViewer(chart!, canvas);
    // canvas.draw(Offset.zero & canvas.size / 2, viewport, sample_drawings2.draw, debuggingOutline: Colors.green, clip: true);
    // canvas.draw(Offset(canvas.size.width / 2, 0.0) & canvas.size / 2, viewport, sample_drawings2.draw, debuggingOutline: Colors.red, clip: true);
    // canvas.draw(Offset(10.0, canvas.size.height / 1.9) & canvas.size / 2.1, viewport, sample_drawings2.draw);
    // canvas.draw(Offset(canvas.size.width / 1.9, canvas.size.height / 1.9) & canvas.size / 2.1, viewport, sample_drawings2.draw);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
