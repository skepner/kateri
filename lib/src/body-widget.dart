import 'package:flutter/material.dart';

// ----------------------------------------------------------------------

class BodyWidget_Singleton extends StatelessWidget {
  const BodyWidget_Singleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AntigenicMapViewer(width: 500);
  }
}

// ----------------------------------------------------------------------

class BodyWidget_Grid extends StatelessWidget {
  const BodyWidget_Grid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, children: [
      AntigenicMapViewer(),
      // AntigenicMapViewer(),
      // AntigenicMapViewer(width: 400.0),
      // AntigenicMapViewer(aspectRatio: 1.5),
      // Container(
      //     margin: const EdgeInsets.all(10.0),
      //     decoration: BoxDecoration(border: Border.all(color: Colors.orange, width: 8)),
      //     width: 400.0,
      //     child: AspectRatio(aspectRatio: 1.0, child: AntigenicMapViewer())),
      // Container(
      //     margin: const EdgeInsets.all(10.0),
      //     decoration: BoxDecoration(border: Border.all(color: Colors.green, width: 8)),
      //     width: 300.0,
      //     child: AspectRatio(aspectRatio: 1.0, child: AntigenicMapViewer())),
      // Container(
      //     margin: const EdgeInsets.all(10.0),
      //     decoration: BoxDecoration(border: Border.all(color: Colors.green, width: 8)),
      //     width: 300.0,
      //     child: AspectRatio(aspectRatio: 1.0, child: AntigenicMapViewer()))
    ]);
  }
}

// ----------------------------------------------------------------------

// ======================================================================

class AntigenicMapViewer extends StatefulWidget {
  AntigenicMapViewer({Key? key, this.width = 500.0, this.aspectRatio = 1.0, this.borderWidth = 5.0, this.borderColor = const Color(0xFF000000)}) : super(key: key);

  // setup
  final double width;
  final double aspectRatio;
  final double borderWidth;
  final Color borderColor;

  @override
  State<AntigenicMapViewer> createState() => _AntigenicMapViewerState();
}

class _AntigenicMapViewerState extends State<AntigenicMapViewer> {
  var scaffoldKey = GlobalKey<ScaffoldState>();
  // Chart? chart;
  String path = "*nothing*";
  // double _size = 100;
  late double width;
  late double aspectRatio;
  late double borderWidth;
  late Color borderColor;

  void setColor(Color color) {
    setState(() {
      borderColor = color;
      print("borderColor $borderColor");
    });
  }

@override
  void initState() {
    super.initState();
    width = widget.width;
    aspectRatio = widget.aspectRatio;
    borderWidth = widget.borderWidth;
    borderColor = widget.borderColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        // margin: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(border: Border.all(color: borderColor, width: borderWidth)),
        // width: width,
        child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Scaffold(
                key: scaffoldKey,
                // appBar: AppBar(), //title: Text("Kateri")),
                drawer: Drawer(
                    child: ListView(padding: EdgeInsets.zero, children: [
                  ListTile(
                      title: Text("AAA"),
                      onTap: () {
                        setColor(Colors.red);
                        Navigator.pop(context);
                      }),
                  ListTile(
                      title: Text("BBB"),
                      onTap: () {
                        Navigator.pop(context);
                      }),
                  ListTile(
                      title: Text("3"),
                      onTap: () {
                        Navigator.pop(context);
                      }),
                  ListTile(
                      title: Text("4"),
                      onTap: () {
                        Navigator.pop(context);
                      }),
                  ListTile(
                      title: Text("5"),
                      onTap: () {
                        Navigator.pop(context);
                      }),
                  ListTile(
                      title: Text("6"),
                      onTap: () {
                        Navigator.pop(context);
                      }),
                  ListTile(
                      title: Text("7"),
                      onTap: () {
                        Navigator.pop(context);
                      }),
                  ListTile(
                      title: Text("8"),
                      onTap: () {
                        Navigator.pop(context);
                      }),
                ])),
                body: Stack(children: <Widget>[
                  // Column(children: [Container(color: orange, child: Text("path: $path")), Container(color: Colors.green, child: Text("path: $path"))]),
                  Center(child: Container(color: borderColor /*  Colors.orange */, child: Text("path: $path $borderColor"))),
                  Positioned(
                      left: 10,
                      top: 20,
                      child: IconButton(
                        icon: Icon(Icons.menu),
                        onPressed: () => scaffoldKey.currentState?.openDrawer(),
                      ))
                ]))));
  }
}

// ----------------------------------------------------------------------
