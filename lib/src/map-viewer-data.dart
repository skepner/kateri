import 'dart:io';
import 'dart:typed_data'; // Uint8List

import 'package:flutter/material.dart';

import 'package:universal_platform/universal_platform.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';

import 'decompress.dart';
import 'chart.dart';
import 'socket-events.dart' as socket_events;
import 'viewport.dart' as vp;
import 'plot_spec.dart';

// ======================================================================

abstract class AntigenicMapViewerCallbacks {
  void updateCallback();
  void showMessage(String text, {Color backgroundColor = Colors.red});
  void hideMessage();
  Future<Uint8List?> exportPdf();
}

// ----------------------------------------------------------------------

class AntigenicMapViewerData {
  final AntigenicMapViewerCallbacks _callbacks;
  String? chartFilename; // for reloadChart()
  Chart? chart;
  Projection? projection;
  vp.Viewport? viewport;
  PlotSpec? plotSpec;
  bool _chartBeingLoaded = false;
  Socket? _socket;
  late bool openExportedPdf;

  AntigenicMapViewerData(this._callbacks);

  void setChart(Chart aChart) {
    chart = aChart;
    projection = chart!.projections[0];
    viewport = projection!.viewport();
    print(viewport);
    plotSpec = null;
    _chartBeingLoaded = false;
    _callbacks.hideMessage();
    _callbacks.updateCallback();
  }

  void setChartFromBytes(Uint8List bytes) {
    setChart(Chart(bytes));
  }

  void resetChart() {
    chart = null;
    projection = null;
    viewport = null;
    plotSpec = null;
    _chartBeingLoaded = false;
    _callbacks.updateCallback();
  }

  void reloadChart() async {
    if (chartFilename != null) {
      print("reloadChart $chartFilename");
      setChart(Chart(await decompressFile(chartFilename!)));
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

  // ----------------------------------------------------------------------

  Future<void> selectAndOpenAceFile() async {
    final file = (await FilePicker.platform.pickFiles())?.files.single;
    if (file != null) {
      try {
        // accesing file?.path on web always reports an error (regardles of using try/catch)
        if (file.bytes != null) {
          setChart(Chart(decompressBytes(file.bytes!)));
        } else if (file.path != null) {
          setChart(Chart(await decompressFile(file.path!)));
          chartFilename = file.path;
        }
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
      _socket = await Socket.connect(InternetAddress(socketName, type: InternetAddressType.unix), 0);
      socket_events.SocketEventHandler(socketStream: _socket!, antigenicMapViewerData: this).handle();
      _socket!.write("Hello from Kateri");
    }
  }

  // ----------------------------------------------------------------------

  void exportPdf() async {
    if (chart != null) {
      final stopwatch = Stopwatch()..start();
      final bytes = await _callbacks.exportPdf(); // antigenicMapPainter.viewer.exportPdf();
      if (bytes != null) {
        final filename = await FileSaver.instance.saveFile(chart!.info.nameForFilename(), bytes, "pdf", mimeType: MimeType.PDF);
        if (openExportedPdf && UniversalPlatform.isMacOS) {
          await Process.run("open", [filename]);
        }
      }
      print("[exportPdf] ${stopwatch.elapsed} -> ${1e6 / stopwatch.elapsedMicroseconds} frames per second");
    }
  }
}

// ----------------------------------------------------------------------
