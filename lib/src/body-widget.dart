import 'package:flutter/material.dart';
import 'map-viewer.dart';

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
