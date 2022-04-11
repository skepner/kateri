import 'dart:io';
import 'dart:typed_data';
import 'dart:convert'; // json
import 'decompress.dart'; // json

// ----------------------------------------------------------------------

class Chart {
  static Chart? fromBytes(Uint8List? bytes) {
    if (bytes == null) {
      return null;
    }
    // final text = decompress(bytes);
    // print(text);
    // final data = json.decoder.convert(utf8.decoder.convert(bytes));
    // print(data);
    return Chart();
  }

  static Chart? fromPath(String? path) {
    if (path == null) {
      return null;
    }
    final text = decompress(File(path).readAsBytesSync());
    print(text.length);
    // final data = await File(path).openRead().transform(utf8.decoder).transform(json.decoder).toList();
    // print(data);
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
