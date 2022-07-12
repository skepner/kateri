import 'dart:io';
import 'dart:typed_data'; // Uint8List

import 'package:flutter/material.dart';

import 'package:universal_platform/universal_platform.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';

import 'error.dart';
import 'decompress.dart';
import 'chart.dart';
import 'socket-events.dart' as socket_events;
import 'viewport.dart' as vp;
import 'plot_spec.dart';

// ======================================================================

abstract class AntigenicMapViewerCallbacks {
  void updateCallback({int? plotSpecIndex});
  void showMessage(String text, {Color backgroundColor = Colors.red});
  void hideMessage();
  Future<Uint8List?> exportPdf({double canvasPdfWidth = 800.0});
}

// ----------------------------------------------------------------------

class AntigenicMapViewerData {
  final AntigenicMapViewerCallbacks _callbacks;
  String? chartFilename; // for reloadChart()
  Chart? chart;
  Projection? projection;
  vp.Viewport? viewport;
  bool _chartBeingLoaded = false;
  Socket? _socket;
  late bool openExportedPdf;
  Size antigenicMapPainterSize = Size.zero; // to auto-resize window
  List<PlotSpec> plotSpecs = <PlotSpec>[];
  int currentPlotSpecIndex = -1;

  AntigenicMapViewerData(this._callbacks);

  void setChart(Chart aChart) {
    chart = aChart;
    projection = chart!.projections[0];
    plotSpecs = chart!.plotSpecs(projection);
    _chartBeingLoaded = false;
    _callbacks.hideMessage();
    currentPlotSpecIndex = -1;
    _callbacks.updateCallback(plotSpecIndex: 0);
  }

  void setChartFromBytes(Uint8List bytes) {
    setChart(Chart(bytes));
  }

  void resetChart() {
    chart = null;
    projection = null;
    viewport = null;
    _chartBeingLoaded = false;
    currentPlotSpecIndex = -1;
    _callbacks.updateCallback();
  }

  void reloadChart() async {
    if (chartFilename != null) {
      final stopwatch = Stopwatch()..start();
      setChart(Chart(await decompressFile(chartFilename!)));
      debug("$chartFilename re-loaded in ${stopwatch.elapsed}");
    }
  }

  void setPlotSpecByName(String name) {
    final index = plotSpecs.indexWhere((spec) => spec.name() == name);
    if (index >= 0) {
      setPlotSpec(index);
    } else {
      warning("plot style \"$name\" not found");
    }
  }

  void setPlotSpec(int index) {
    if (chart != null && index < plotSpecs.length) {
      if (currentPlotSpecIndex != index) {
        currentPlotSpecIndex = index;
        currentPlotSpec.activate();
      }
      viewport = plotSpecs[index].viewport() ?? projection!.viewport();
      info("projection ${projection!.viewport()}");
      info("used       $viewport  aspect:${viewport!.aspectRatio()}");
    }
  }

  PlotSpec get currentPlotSpec => plotSpecs[currentPlotSpecIndex];

  PlotSpecLegacy plotSpecLegacy() {
    final index = plotSpecs.indexWhere((spec) => spec.name() == PlotSpecLegacy.myName());
    if (index >= 0) {
      return plotSpecs[index] as PlotSpecLegacy;
    } else {
      final ps = chart!.plotSpecLegacy();
      plotSpecs.add(ps);
      return ps;
    }
  }

  bool empty() => chart != null;

  void buildStarted() {
    if (UniversalPlatform.isMacOS && chart == null && !_chartBeingLoaded && _socket == null) {
      // forcing open dialog here does not work in web and eventually leads to problems
      selectAndOpenAceFile();
    }
  }

  void didChangeDependencies({required String? fileToOpen, required String? socketToConnect}) {
    openLocalAceFile(fileToOpen);
    connectToServer(socketToConnect);
  }

  void exportCurrentPlotStyleToLegacy() {
    if (chart != null && currentPlotSpec.name() != PlotSpecLegacy.myName()) {
      plotSpecLegacy().setFrom(currentPlotSpec);
    }
  }

  // ----------------------------------------------------------------------

  Future<void> selectAndOpenAceFile() async {
    final file = (await FilePicker.platform.pickFiles())?.files.single;
    if (file != null) {
      try {
        final stopwatch = Stopwatch()..start();
        // accesing file?.path on web always reports an error (regardles of using try/catch)
        if (file.bytes != null) {
          setChart(Chart(decompressBytes(file.bytes!)));
        } else if (file.path != null) {
          setChart(Chart(await decompressFile(file.path!)));
          chartFilename = file.path;
        }
        debug("chart loaded in ${stopwatch.elapsed}");
      } on Exception catch (err) {
        // cannot import chart from a file
        _callbacks.showMessage(err.toString());
        if (chart == null) {
          resetChart();
        }
      }
    }
    // else {
    //   resetChart();
    // }
  }

  Future<void> openLocalAceFile(String? path) async {
    // print("openLocalAceFile path:$path chart:$chart");
    if (chart == null && path != null) {
      try {
        _chartBeingLoaded = true;
        if (path == "-") {
          setChart(Chart(await decompressStdin()));
        } else {
          setChart(Chart(await decompressFile(path)));
        }
      } on Exception catch (err) {
        // cannot import chart from a file
        _callbacks.showMessage(err.toString());
        resetChart();
      }
    }
  }

  // ----------------------------------------------------------------------

  void connectToServer(String? socketName) async {
    if (socketName != null) {
      _chartBeingLoaded = true;
      while (true) {
        try {
          _socket = await Socket.connect(InternetAddress(socketName, type: InternetAddressType.unix), 0);
          break; // connected
        } on SocketException {
          // socket not available yet, wait
          sleep(const Duration(milliseconds: 100));
        }
      }

      socket_events.SocketEventHandler(socket: _socket!, antigenicMapViewerData: this).handle();
      _socket!.write("HELO");
    }
  }

  // ----------------------------------------------------------------------

  void exportPdf({String? filename, bool? open, double width = 800.0}) async {
    if (chart != null) {
      final stopwatch = Stopwatch()..start();
      final bytes = await _callbacks.exportPdf(canvasPdfWidth: width); // antigenicMapPainter.viewer.exportPdf();
      if (bytes != null) {
        final generatedFilename = await FileSaver.instance.saveFile(filename ?? chart!.info.nameForFilename(), bytes, "pdf", mimeType: MimeType.PDF);
        debug("generatedFilename $generatedFilename");
        if ((open ?? openExportedPdf) && UniversalPlatform.isMacOS) {
          await Process.run("open", [generatedFilename]);
        }
      }
      debug("[exportPdf] ${stopwatch.elapsed} -> ${(1e6 / stopwatch.elapsedMicroseconds).toStringAsFixed(2)} frames per second");
    }
  }

  Future<Uint8List?> exportPdfToBytes({double width = 800.0}) async {
    return _callbacks.exportPdf(canvasPdfWidth: width);
  }
}

// ----------------------------------------------------------------------
