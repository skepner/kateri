// import 'dart:ui';
// import 'dart:io';
// import 'dart:math' as math;

// import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

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
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kateri ${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())}'),
        backgroundColor: Colors.green,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Pdf',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This is a snackbar')));
            },
          ),
        ],
      ),
      body: CustomPaint(
        painter: AntigenicMapPainter(const Offset(-5.0, -5.0) & const Size.square(10.0)),
        size: const Size(99999, 99999),
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
  Rect viewport;

  AntigenicMapPainter(this.viewport);

  @override
  void paint(Canvas canvas, Size size) {
    paintOn(CanvasFlutter(canvas, size));

    // DrawOnPdf(viewport: viewport)
    //   ..draw(sample_drawings2.draw)
    //   ..write("/r/a.pdf", open: true);
  }

  void paintOn(CanvasRoot canvas) {
    canvas.draw(Offset.zero & canvas.size / 2, viewport, sample_drawings2.draw);
    canvas.draw(Offset(canvas.size.width / 2, 0.0) & canvas.size / 2, viewport, sample_drawings2.draw);
    canvas.draw(Offset(0.0, canvas.size.height / 2) & canvas.size / 2, viewport, sample_drawings2.draw);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
