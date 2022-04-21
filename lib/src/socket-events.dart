import 'dart:async';
import 'dart:typed_data'; // Uint8List

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
        return const ChartEvent();
      default:
        throw FormatException("unrecognized socket event (${source.length}): \"${String.fromCharCodes(source)}\"");
    }
  }

  /// Consumes few or all bytes from the source, returns not consumed part
  Uint8List consume(Uint8List source);

  /// Returns if event cannot consume more bytes and ready to be sent further
  bool finished();
}

class ChartEvent extends _Event {
  const ChartEvent();

  @override
  Uint8List consume(Uint8List source) {
    print("chart data ${source.length}");
    return Uint8List(0);
  }

  @override
  bool finished() {
    return false;
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
    while (source.isNotEmpty) {
      if (_current == null) {
        _current = _Event.create(source);
        source = Uint8List.view(source.buffer, 4);
      }
      source = _current!.consume(source);
      if (_current!.finished()) {
        _output.add(_current!);
        _current = null;
      }
    }
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
