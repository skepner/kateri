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
    return "${info['V']} ${info['A']} ${info['D']} sources: ${info['S']?.length}";
  }

  // ----------------------------------------------------------------------

  final Map<String, dynamic> _data;
}

// ----------------------------------------------------------------------
