import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ======================================================================

class OpenChartIntent extends Intent {
  const OpenChartIntent();
}

class ReloadChartIntent extends Intent {
  const ReloadChartIntent();
}

class PdfIntent extends Intent {
  const PdfIntent();
}

class ResetWindowSizeIntent extends Intent {
  const ResetWindowSizeIntent();
}

abstract class AntigenicMapShortcutCallbacks {
  void openChart();
  void reloadChart();
  void generatePdf();
  void resetWindowSize();
}

// ----------------------------------------------------------------------

class AntigenicMapShortcuts extends StatelessWidget {
  final Widget child;
  final AntigenicMapShortcutCallbacks callbacks;

  const AntigenicMapShortcuts({required this.child, required this.callbacks, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          LogicalKeySet(LogicalKeyboardKey.f3): const OpenChartIntent(),
          LogicalKeySet(LogicalKeyboardKey.f4): const PdfIntent(),
          LogicalKeySet(LogicalKeyboardKey.f5): const ReloadChartIntent(),
          LogicalKeySet(LogicalKeyboardKey.f9): const ResetWindowSizeIntent(),
        },
        child: Actions(
            actions: <Type, Action<Intent>>{
              OpenChartIntent: CallbackAction<OpenChartIntent>(onInvoke: (OpenChartIntent intent) => callbacks.openChart()),
              ReloadChartIntent: CallbackAction<ReloadChartIntent>(onInvoke: (ReloadChartIntent intent) => callbacks.reloadChart()),
              PdfIntent: CallbackAction<PdfIntent>(onInvoke: (PdfIntent intent) => callbacks.generatePdf()),
              ResetWindowSizeIntent: CallbackAction<ResetWindowSizeIntent>(onInvoke: (ResetWindowSizeIntent intent) => callbacks.resetWindowSize()),
            },
            child: Focus(
              autofocus: true,
              onFocusChange: (focused) {
                // print("onFocusChange $focused");
              },
              child: child,
            )));
  }
}

// ======================================================================
