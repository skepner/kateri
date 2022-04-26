import 'dart:async';
import 'dart:typed_data'; // Uint8List
import 'dart:math';

// ----------------------------------------------------------------------

class SocketEventHandler {
  final Stream<_Event> _transformed;
  SocketEventHandler(Stream<Uint8List> source) : _transformed = source.transform(const _Transformer());

  void handle() async {
    await for (final event in _transformed) {
      print(event);
    }
  }
}

// ----------------------------------------------------------------------

abstract class _Event {
  const _Event();

  /// 4 first bytes of source is a event type code
  factory _Event.create(Uint8List source) {
    switch (String.fromCharCodes(source, 0, 4)) {
      case "CHRT":
        return ChartEvent();
      default:
        throw FormatException("unrecognized socket event (${source.length}): \"${String.fromCharCodes(source)}\"");
    }
  }

  /// Consumes few or all bytes from the source, returns number of bytes consumed
  int consume(Uint8List source, int sourceStart);

  /// Returns if event cannot consume more bytes and ready to be sent further
  bool finished();
}

class ChartEvent extends _Event {
  Uint8List? _data;
  int _stored = 0; // number of bytes already in _data

  ChartEvent();

  /// returns number of bytes consumed
  @override
  int consume(Uint8List source, int sourceStart) {
    print("consume ${source.length} 0x${source.buffer.asUint32List(sourceStart, 1)[0].toRadixString(16)} \"${String.fromCharCodes(Uint8List.view(source.buffer, sourceStart, 4))}\"");
    var rest = source.length - sourceStart;
    if (rest <= 0) return 0;
    final sourceStartInit = sourceStart;
    if (_data == null) {
      if (rest < 4) throw FormatException("ChartEvent: cannot read data size: too few bytes available ($rest)");
      _data = Uint8List(source.buffer.asUint32List(sourceStart, 1)[0]);
      if (rest <= 4) return 0;
      sourceStart += 4;
      rest -= 4;
      print("receiving chart ${_data!.length} 0x${_data!.length.toRadixString(16)}");
    }
    final copyCount = min(rest, _data!.length - _stored);
    _data!.setRange(_stored, _stored + copyCount, Uint8List.view(source.buffer, sourceStart));
    _stored += copyCount;
    print("received $rest -> $_stored");
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

class _Transformer extends StreamTransformerBase<Uint8List, _Event> {
  const _Transformer();

  Stream<_Event> bind(Stream<Uint8List> stream) {
    return Stream<_Event>.eventTransformed(stream, (EventSink<_Event> sink) => _EventSink(sink));
  }
}

// ----------------------------------------------------------------------

class _EventSink implements EventSink<Uint8List> {
  final EventSink<_Event> _output;
  _Event? _current;

  _EventSink(this._output);

  @override
  void add(Uint8List source) {
    var sourceStart = 0;
    print("_EventSink.add ${source.length} \"${String.fromCharCodes(Uint8List.view(source.buffer, sourceStart, 4))}\" sourceStart:$sourceStart");
    while (sourceStart < source.length) {
      if (_current == null) {
        _current = _Event.create(source);
        sourceStart += 4;
      }
      sourceStart += _current!.consume(source, sourceStart);
      print("event consumed ${source.length - sourceStart} start:$sourceStart");
      if (_current!.finished()) {
        _output.add(_current!);
        _current = null;
      }
    }
    print("add done sourceStart:$sourceStart");
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    print("_EventSink.addError $error");
  }

  @override
  void close() {
    print("_EventSink.close");
  }
}

// ----------------------------------------------------------------------
