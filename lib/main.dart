import 'package:flutter/material.dart';
import 'package:args/args.dart';

import "src/body-widget.dart";

// ----------------------------------------------------------------------

void main(List<String> args) {
  runApp(KateriApp(args));
}

// ----------------------------------------------------------------------

class CommandLineData extends InheritedWidget {
  late final String? fileToOpen;

  CommandLineData(List<String> args, {required Widget child, Key? key}) : super(key: key, child: child) {
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
  bool updateShouldNotify(CommandLineData old) => fileToOpen != old.fileToOpen;
}

// ----------------------------------------------------------------------

class KateriApp extends StatelessWidget {
  final List<String> commandLineArgs;

  const KateriApp(this.commandLineArgs, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommandLineData(commandLineArgs,
        child: const MaterialApp(
          home: Scaffold(
            body: BodyWidget_Singleton()
            // body: BodyWidget_Grid(),
          ),
          debugShowCheckedModeBanner: false,
        ));
  }
}
