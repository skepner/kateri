import 'package:flutter/material.dart';
import 'package:args/args.dart';

import 'map-viewer.dart';

// ----------------------------------------------------------------------

class App extends StatelessWidget {
  final List<String> commandLineArgs;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  App(this.commandLineArgs, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommandLineData(commandLineArgs,
        errorReportingKey: _scaffoldKey,
        child: MaterialApp(
          home: Scaffold(key: _scaffoldKey, body: const SingleMap()
              // body: GridOfMaps(),
              ),
          debugShowCheckedModeBanner: false,
        ));
  }
}

// ----------------------------------------------------------------------

class CommandLineData extends InheritedWidget {
  late final String? fileToOpen;
  final GlobalKey<ScaffoldState> errorReportingKey;

  CommandLineData(List<String> args, {required this.errorReportingKey, required Widget child, Key? key}) : super(key: key, child: child) {
    final parser = ArgParser();
    parser.addOption("chart", abbr: "c", callback: (arg) {
      fileToOpen = arg;
    });
    parser.parse(args);
  }

  static CommandLineData of(BuildContext context) {
    final CommandLineData? result = context.dependOnInheritedWidgetOfExactType<CommandLineData>();
    assert(result != null, 'No CommandLineData found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(CommandLineData oldWidget) => fileToOpen != oldWidget.fileToOpen;
}

// ----------------------------------------------------------------------

class SingleMap extends StatelessWidget {
  const SingleMap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AntigenicMapViewWidget(width: 500);
  }
}

// ----------------------------------------------------------------------

class GridOfMaps extends StatelessWidget {
  const GridOfMaps({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, children: const [
      AntigenicMapViewWidget(),
      // AntigenicMapViewWidget(),
      // AntigenicMapViewWidget(width: 400.0),
      // AntigenicMapViewWidget(aspectRatio: 1.5),
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
