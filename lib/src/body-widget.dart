import 'package:flutter/material.dart';

// ----------------------------------------------------------------------

class BodyWidget_Singleton extends StatelessWidget {
  const BodyWidget_Singleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AntigenicMapViewer();
  }
}

// ----------------------------------------------------------------------

class BodyWidget_Grid extends StatelessWidget {
  const BodyWidget_Grid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, children: [
        Container(
                margin: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(border: Border.all(color: Colors.orange, width: 8)),
                width: 400.0,
                child: AspectRatio(aspectRatio: 1.0, child: AntigenicMapViewer())),
        Container(
            margin: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(border: Border.all(color: Colors.green, width: 8)),
            width: 300.0,
            child: AspectRatio(aspectRatio: 1.0, child: AntigenicMapViewer())),
        Container(
            margin: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(border: Border.all(color: Colors.green, width: 8)),
            width: 300.0,
            child: AspectRatio(aspectRatio: 1.0, child: AntigenicMapViewer()))
      ]);
  }
}

// ----------------------------------------------------------------------

// ======================================================================

class AntigenicMapViewer extends StatefulWidget {
  AntigenicMapViewer({Key? key}) : super(key: key);

  @override
  State<AntigenicMapViewer> createState() => _AntigenicMapViewerState();
}

class _AntigenicMapViewerState extends State<AntigenicMapViewer> {
  var scaffoldKey = GlobalKey<ScaffoldState>();
  // Chart? chart;
  String path = "*nothing*";
  // double _size = 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        // appBar: AppBar(), //title: Text("Kateri")),
        drawer: Drawer(
            child: ListView(padding: EdgeInsets.zero, children: [
          ListTile(
              title: Text("AAA"),
              onTap: () {
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
          Center(child: Container(color: Colors.orange, child: Text("path: $path"))),
          Positioned(
              left: 10,
              top: 20,
              child: IconButton(
                icon: Icon(Icons.menu),
                onPressed: () => scaffoldKey.currentState?.openDrawer(),
              ))
        ]));
  }
}

// ----------------------------------------------------------------------
