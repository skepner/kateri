import 'dart:async';
import 'dart:typed_data'; // Uint8List
import 'dart:math';

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
  const Event();

  void act(AntigenicMapViewerData antigenicMapViewerData);

  /// 4 first bytes of source is a event type code
  factory Event.create(Uint8List source) {
    switch (String.fromCharCodes(source, 0, 4)) {
      case "CHRT":
        return ChartEvent();
      default:
        throw FormatError("unrecognized socket event (${source.length}): \"${String.fromCharCodes(source)}\"");
    }
  }

  /// Consumes few or all bytes from the source, returns number of bytes consumed
  int consume(Uint8List source, int sourceStart);

  /// Returns if event cannot consume more bytes and ready to be sent further
  bool finished();
}

class ChartEvent extends Event {
  Uint8List? _data;
  int _stored = 0; // number of bytes already in _data

  ChartEvent() {
    info("receiving chart");
  }

  @override
  void act(AntigenicMapViewerData antigenicMapViewerData) {
    if (_data == null) return;
    antigenicMapViewerData.setChartFromBytes(_data!);
  }

  /// returns number of bytes consumed
  @override
  int consume(Uint8List source, int sourceStart) {
    final sourceStartInit = sourceStart;
    if (_data == null) {
      if ((source.length - sourceStart) < 4) throw FormatError("ChartEvent: cannot read data size: too few bytes available (${source.length - sourceStart})");
      _data = Uint8List(source.buffer.asUint32List(sourceStart, 1)[0]);
      sourceStart += 4;
      if ((source.length - sourceStart) <= 4) return 0;
    }
    final copyCount = min(source.length - sourceStart, _data!.length - _stored);
    _data!.setRange(_stored, _stored + copyCount, Uint8List.view(source.buffer, sourceStart));
    _stored += copyCount;
    return sourceStart - sourceStartInit + copyCount;
  }

  @override
  bool finished() {
    return _data != null && _data!.length == _stored;
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
        _current = Event.create(source);
        sourceStart += 4;
      }
      sourceStart += _current!.consume(source, sourceStart);
      if (_current!.finished()) {
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
