import 'dart:io';
import 'dart:async';
import 'dart:typed_data'; // Uint8List
import 'dart:math';
import 'dart:convert'; // json
import 'package:flutter/services.dart';

import 'error.dart';
import 'map-viewer-data.dart';

// ----------------------------------------------------------------------

class SocketEventHandler {
  final AntigenicMapViewerData antigenicMapViewerData;
  final Stream<Event> _transformed;
  final Socket socket;
  var _processing = 0;

  SocketEventHandler({required this.socket, required this.antigenicMapViewerData}) : _transformed = socket.transform(const _Transformer());

  void handle() async {
    await for (final event in _transformed) {
      event.act(socket, antigenicMapViewerData, this);
    }
  }

  void startProcessing() {
    ++_processing;
  }

  void endProcessing() {
    --_processing;
  }

  Future quit() async {
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 10));
      return _processing > 0;
    });
    socket.add(Uint8List.fromList("QUIT".codeUnits));
    // info("quitting");
  }
}

// ----------------------------------------------------------------------

abstract class Event {
  Event();

  /// Called when the whole even is stored in data
  void prepare();

  void act(Socket socket, AntigenicMapViewerData antigenicMapViewerData, SocketEventHandler handler);

  /// source starts with 4 bytes of code followed by 4 bytes of data size followed by data
  factory Event.create(Uint8List source, int sourceStart) {
    final eventCode = String.fromCharCodes(source, sourceStart, sourceStart + 4);
    switch (eventCode) {
      case "CHRT":
        return ChartEvent();
      case "COMD":
        return CommandEvent();
      default:
        throw FormatError("unrecognized socket event (${source.length - sourceStart}): \"$eventCode\"");
    }
  }

  /// Consume few or all bytes from the source, return number of bytes consumed, store read bytes into _data
  int consume(Uint8List source, int sourceStart) {
    final sourceStartInit = sourceStart;
    if (_data == null) {
      if ((source.length - sourceStart) < 4) throw FormatError("Event: cannot read data size: too few bytes available (${source.length - sourceStart})");
      _data = Uint8List(source.buffer.asUint32List(sourceStart, 1)[0]);
      sourceStart += 4;
      if ((source.length - sourceStart) <= 4) return sourceStart - sourceStartInit;
    }
    final copyCount = min(source.length - sourceStart, _data!.length - _stored);
    _data!.setRange(_stored, _stored + copyCount, Uint8List.view(source.buffer, sourceStart));
    _stored += copyCount;
    var consumed = sourceStart - sourceStartInit + copyCount;
    if (finished()) {
      // consume padding to make sure next event starts at 4-byte boundary
      final remainder = copyCount.remainder(4);
      if (remainder > 0) consumed += 4 - remainder;
    }
    return consumed;
  }

  /// Returns if event cannot consume more bytes and ready to be sent further
  bool finished() {
    return _data != null && _data!.length == _stored;
  }

  void send(Socket socket, String command, Uint8List data) {
    final remainder = data.length.remainder(4);
    final padding = remainder != 0 ? Uint8List(4 - remainder) : Uint8List(0);
    final payloadLength = Uint8List(4);
    payloadLength.buffer.asUint32List(0, 1)[0] = data.length;
    // info("[socket] sending $command ${data.length} bytes with padding ${padding.length}");
    socket.add(Uint8List.fromList(command.codeUnits));
    socket.add(payloadLength);
    socket.add(data);
    socket.add(padding);
  }

  Uint8List? _data;
  int _stored = 0; // number of bytes already in _data
}

// ----------------------------------------------------------------------

class ChartEvent extends Event {
  @override
  void prepare() {
    info("receiving chart (${_data!.length} bytes)");
  }

  @override
  void act(Socket socket, AntigenicMapViewerData antigenicMapViewerData, SocketEventHandler handler) {
    if (_data == null) return;
    antigenicMapViewerData.setChartFromBytes(_data!);
  }

  @override
  String toString() {
    if (_data == null) {
      return "ChartEvent(empty)";
    } else {
      return "ChartEvent(${_data!.length} $_stored bytes)";
    }
  }
}

// ----------------------------------------------------------------------

typedef _JsonData = Map<String, dynamic>;

class CommandEvent extends Event {
  late final _JsonData data;

  @override
  void prepare() {
    if (_data == null) return;

    // debug("receiving command (${_data!.length} bytes)");

    late final String utf8Decoded;
    try {
      utf8Decoded = utf8.decode(_data!);
    } catch (err) {
      throw FormatError("utf8 decoding failed: $err");
    }
    // debug(utf8Decoded);
    try {
      data = jsonDecode(utf8Decoded);
    } catch (err) {
      throw FormatError("json decoding failed: $err");
    }
  }

  @override
  void act(Socket socket, AntigenicMapViewerData antigenicMapViewerData, SocketEventHandler handler) async {
    // info("CommandEvent.act ${data['C']}");
    switch (data["C"]) {
      case "set_style":
        antigenicMapViewerData.setPlotSpecByName(data["style"] ?? "*unknown*");
        break;
      case "export_to_legacy": // export current style to legacy plot spec
        antigenicMapViewerData.exportCurrentPlotStyleToLegacy();
        break;
      case "get_chart": // send chart (json) back to server
        handler.startProcessing();
        final json = antigenicMapViewerData.chart?.exportToJson();
        if (json != null) {
          send(socket, "CHRT", utf8.encoder.convert(json));
        }
        handler.endProcessing();
        break;
      case "pdf":
        handler.startProcessing();
        final pdfData = await antigenicMapViewerData.exportPdfToBytes(width: data["width"]?.toDouble());
        if (pdfData != null) {
          send(socket, "PDFB", pdfData);
          // final remainder = pdfData.length.remainder(4);
          // final padding = remainder != 0 ? Uint8List(4 - remainder) : Uint8List(0);
          // final payloadLength = Uint8List(4);
          // payloadLength.buffer.asUint32List(0, 1)[0] = pdfData.length;
          // info("[socket] sending pdf ${pdfData.length} bytes with padding ${padding.length}");
          // socket.add(Uint8List.fromList("PDFB".codeUnits));
          // socket.add(payloadLength);
          // socket.add(pdfData);
          // socket.add(padding);
        }
        handler.endProcessing();
        break;
      case "quit":
        await handler.quit();
        break;
      default:
        error("unrecognized command: $data");
        break;
    }
  }

  @override
  String toString() {
    return "CommandEvent $data";
  }
}

// ----------------------------------------------------------------------

class _Transformer extends StreamTransformerBase<Uint8List, Event> {
  const _Transformer();

  Stream<Event> bind(Stream<Uint8List> stream) {
    return Stream<Event>.eventTransformed(stream, (EventSink<Event> sink) => _EventSink(sink));
  }
}

// ----------------------------------------------------------------------

class _EventSink implements EventSink<Uint8List> {
  final EventSink<Event> _output;
  Event? _current;

  _EventSink(this._output);

  @override
  void add(Uint8List source) {
    var sourceStart = 0;
    // print("_EventSink.add ${source.length} \"${String.fromCharCodes(Uint8List.view(source.buffer, sourceStart, 4))}\" sourceStart:$sourceStart");
    while (sourceStart < source.length) {
      if (_current == null) {
        _current = Event.create(source, sourceStart);
        sourceStart += 4;
      }
      sourceStart += _current!.consume(source, sourceStart);
      if (_current!.finished()) {
        _current!.prepare();
        _output.add(_current!);
        _current = null;
      }
    }
  }

  @override
  void addError(Object err, [StackTrace? stackTrace]) {
    error("_EventSink.addError $err");
  }

  @override
  void close() {
    // info("_EventSink.close");
    SystemNavigator.pop(animated: true);
  }
}

// ----------------------------------------------------------------------
