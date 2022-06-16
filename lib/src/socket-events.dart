import 'dart:async';
import 'dart:typed_data'; // Uint8List
import 'dart:math';
import 'dart:convert'; // json

import 'error.dart';
import 'map-viewer-data.dart';

// ----------------------------------------------------------------------

class SocketEventHandler {
  final AntigenicMapViewerData antigenicMapViewerData;
  final Stream<Event> _transformed;

  SocketEventHandler({required Stream<Uint8List> socketStream, required this.antigenicMapViewerData}) : _transformed = socketStream.transform(const _Transformer());

  void handle() async {
    await for (final event in _transformed) {
      event.act(antigenicMapViewerData);
    }
  }
}

// ----------------------------------------------------------------------

abstract class Event {
  Event();

  /// Called when the whole even is stored in data
  void prepare();

  void act(AntigenicMapViewerData antigenicMapViewerData);

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
      if ((source.length - sourceStart) <= 4) return 0;
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
  void act(AntigenicMapViewerData antigenicMapViewerData) {
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

    info("receiving command (${_data!.length} bytes)");

    late final String utf8Decoded;
    try {
      utf8Decoded = utf8.decode(_data!);
    } catch (err) {
      throw FormatError("utf8 decoding failed: $err");
    }
    try {
      data = jsonDecode(utf8Decoded);
    } catch (err) {
      throw FormatError("json decoding failed: $err");
    }
  }

  @override
  void act(AntigenicMapViewerData antigenicMapViewerData) {
    // info("CommandEvent.act $data");
    switch (data["C"]) {
      case "set_style":
        antigenicMapViewerData.setPlotSpecByName(data["style"] ?? "*unknown*");
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
    info("_EventSink.close");
  }
}

// ----------------------------------------------------------------------
