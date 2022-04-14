import 'package:flutter/material.dart';

import "src/body-widget.dart";

// import 'dart:ui';
// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:math' as math;

// import 'package:flutter/cupertino.dart' as cupertino;
// import 'package:flutter/widgets.dart'; // MouseRegion

// import 'package:intl/intl.dart';

// import 'package:file_selector/file_selector.dart';

// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;

// import 'package:path_provider/path_provider.dart';

// import 'src/chart.dart';




// import 'src/resizable_widget_sample.dart';

// import 'src/sample/drawings1.dart' as sample_drawings1;
// import 'src/sample/drawings2.dart' as sample_drawings2;

// ----------------------------------------------------------------------

void main() {
  runApp(const KateriApp());
}

class KateriApp extends StatelessWidget {
  const KateriApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: KateriPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class KateriPage extends StatefulWidget {
  const KateriPage({Key? key}) : super(key: key);
  @override
  _KateriPageState createState() => _KateriPageState();
}

class _KateriPageState extends State<KateriPage> {
  void _updateLocation(PointerEvent details) {
    // print("_updateLocation $details");
  }

  @override
  Widget build(BuildContext context) {
    // final antigenicMapPainter = AntigenicMapPainter(); // Chart(localPath: "/r/h1pdm-hi-turkey-vidrl.chain.ace"));

    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Kateri ${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())}'),
      //   backgroundColor: Colors.green,
      //   actions: <Widget>[
      //     // IconButton(
      //     //   icon: const Icon(Icons.file_open),
      //     //   tooltip: 'Open ace file',
      //     //   onPressed: () {
      //     //     antigenicMapPainter.openAceFile();
      //     //   },
      //     // ),
      //     // IconButton(
      //     //   icon: const Icon(Icons.picture_as_pdf),
      //     //   tooltip: 'Export pdf',
      //     //   onPressed: () {
      //     //     antigenicMapPainter.exportPdf();
      //     //   },
      //     // ),
      //   ],
      // ),
      body: BodyWidget_Singleton(),
      // body: BodyWidget_Grid(),

      // MouseRegion(onHover: _updateLocation, child: AntigenicMapViewer() // Column(children: [SizeBox(width: 300.0, height: 300.0, child: AntigenicMapViewer())]), // AntigenicMapViewer()]),
      // child: CustomPaint(
      //   painter: antigenicMapPainter,
      //   size: const Size(99999, 99999),
      // ),
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
