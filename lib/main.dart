// import 'dart:ui';
import 'dart:io';
// import 'dart:math' as math;

// import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart'; // MouseRegion
import 'package:universal_platform/universal_platform.dart';

import 'package:intl/intl.dart';

import 'package:file_selector/file_selector.dart';
import 'package:file_saver/file_saver.dart';

// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;

// import 'package:path_provider/path_provider.dart';

import 'src/draw_on.dart';
import 'src/draw_on_canvas.dart';
import 'src/draw_on_pdf.dart';

// import 'src/sample/drawings1.dart' as sample_drawings1;
import 'src/sample/drawings2.dart' as sample_drawings2;

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
    final antigenicMapPainter = AntigenicMapPainter(const Offset(-5.0, -5.0) & const Size.square(20.0));

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
  final String mapName;
  Rect viewport;

  AntigenicMapPainter(this.viewport) : mapName = "mapp";

  @override
  void paint(Canvas canvas, Size size) {
    paintOn(CanvasFlutter(canvas, size));
  }

  void exportPdf({bool open = true}) async {
    final canvasPdf = CanvasPdf(Size(1000.0, 1000.0 / viewport.width * viewport.height))..paintBy(paintOn);
    final filename = await FileSaver.instance.saveFile(mapName, await canvasPdf.bytes(), "pdf", mimeType: MimeType.PDF);
    if (open && UniversalPlatform.isMacOS) {
      await Process.run("open-and-back-to-emacs", [filename]);
    }
  }

  void openAceFile() async {
    final typeGroup = XTypeGroup(label: 'ace', extensions: ['ace', 'json']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    final data = await file?.readAsString();
    print("openAceFile [$file] {$data]");
  }

  void paintOn(CanvasRoot canvas) {
    canvas.draw(Offset.zero & canvas.size / 2, viewport, sample_drawings2.draw, debuggingOutline: Colors.green, clip: true);
    canvas.draw(Offset(canvas.size.width / 2, 0.0) & canvas.size / 2, viewport, sample_drawings2.draw, debuggingOutline: Colors.red, clip: true);
    canvas.draw(Offset(10.0, canvas.size.height / 1.9) & canvas.size / 2.1, viewport, sample_drawings2.draw);
    canvas.draw(Offset(canvas.size.width / 1.9, canvas.size.height / 1.9) & canvas.size / 2.1, viewport, sample_drawings2.draw);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
