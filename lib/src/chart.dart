import 'dart:io';
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

  String? _makeDate() {
    final info = _data["c"]["i"];
    if (info['D'] != null) {
      return info['D'];
    }
    final d1 = info['S']?.first["D"] ?? "", d2 = info['S']?.last["D"] ?? "";
    return "$d1-$d2";
  }

  int numberOfProjections() {
    return _data["c"]["P"]?.length ?? 0;
  }

  // ----------------------------------------------------------------------

  final Map<String, dynamic> _data;
}

// ----------------------------------------------------------------------
