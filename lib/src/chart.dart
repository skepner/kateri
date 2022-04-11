import 'dart:io';
import 'dart:typed_data';
import 'dart:convert'; // json
import 'decompress.dart'; // json

// ----------------------------------------------------------------------

class Chart {
  static Future<Chart?> fromBytes(Uint8List? bytes) async {
    if (bytes == null) {
      return null;
    }
    final data = json.decoder.convert(utf8.decoder.convert(bytes));
    print(data);
    return Chart();
  }

  static Future<Chart?> fromPath(String? path) async {
    if (path == null) {
      return null;
    }
    final data = await File(path).openRead().transform(utf8.decoder).transform(json.decoder).toList();
    print(data);
    return Chart();
  }

  static Future<Chart?> fromServer(String? path) async {
    if (path == null) {
      return null;
    }
    // ajax
    return null;
  }

}

// ----------------------------------------------------------------------
