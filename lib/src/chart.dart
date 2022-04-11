import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'dart:convert'; // json
import 'decompress.dart'; // json

// ----------------------------------------------------------------------

class Chart {
  Chart(List<int> source) : _data = json.decode(utf8.decode(source));

  static Chart? fromBytes(Uint8List? bytes) {
    if (bytes == null) {
      return null;
    }
    return Chart(decompress(bytes));
  }

  static Chart? fromPath(String? path) {
    if (path == null) {
      return null;
    }
    return Chart(decompress(File(path).readAsBytesSync()));
  }

  static Future<Chart?> fromServer(String? path) async {
    if (path == null) {
      return null;
    }
    // ajax
    return null;
  }

  // ----------------------------------------------------------------------

  String name() {
    final info = _data["c"]["i"];
    final fields = [
      info['V'],
      if (info['A'] != "HI") info['A'],
      info['r'],
      info['l'],
      _makeDate(),
      if (info["S"] != null) "(tables: ${info['S']?.length})",
    ];
    return fields.where((field) => field != null).cast<String>().join(" ");
  }

  String nameForFilename() {
    final info = _data["c"]["i"];
    final fields = [
      _subtypeShort(),
      if (info['A'] != "HI") info['A'],
      info['r'],
      info['l'],
      _makeDate(),
    ];
    return fields.where((field) => field != null).cast<String>().join("-")..replaceAll(RegExp(r'[\(\)/\s]'), "-").toLowerCase();
  }

  String? _makeDate() {
    final info = _data["c"]["i"];
    if (info['D'] != null) {
      return info['D'];
    }
    final d1 = info['S']?.first["D"] ?? "", d2 = info['S']?.last["D"] ?? "";
    return "$d1-$d2";
  }

  String? _subtypeShort() {
    final subtype = _data["c"]["i"]["V"];
    switch (subtype) {
      case "A(H1N1)":
        return "h1";
      case "A(H3N2)":
        return "h3";
      case "B":
        return "b";
      case null:
        return null;
      default:
        return subtype;
    }
  }

  int numberOfProjections() {
    return _data["c"]["P"]?.length ?? 0;
  }

  Projection projection(int projectionNo) {
    assert(_data["c"]["P"] != null);
    assert(_data["c"]["P"]!.length > projectionNo);
    return Projection(_data["c"]["P"][projectionNo]);
  }

  // ----------------------------------------------------------------------

  final Map<String, dynamic> _data;
}

// ----------------------------------------------------------------------

class Projection {
  Projection(this._data);

  Rect viewport() {
    return const Offset(-5, -5) & const Size(10, 10);
  }

  List<dynamic> layout() {
    return _data["l"];
  }

  final Map<String, dynamic> _data;
}

// ----------------------------------------------------------------------
