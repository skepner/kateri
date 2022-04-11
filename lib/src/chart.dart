import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'dart:convert'; // json

import 'package:vector_math/vector_math_64.dart';

import 'decompress.dart';

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

  List<Vector3?> layout() {
    Vector3? fromList(dynamic src) {
      switch (src.length) {
        case 0:
        case 1:
          return null;
        case 2:
          return Vector3(src[0], src[1], 0.0);
        case 3:
          return Vector3(src[0], src[1], src[2]);
        default:
          return null;
      }
    }

    return _data["l"].map<Vector3?>(fromList).toList();
  }

  double? stress() {
    return _data["s"];
  }

  String minimumColumnBasis() {
    return _data["m"] ?? "none";
  }

  List<double> forcedColumnBases() {
    return _data["C"]?.cast<double>().toList();
  }

  Matrix4 transformation() {
    if (_data["t"] != null) {
      switch (_data["t"].length) {
        case 4:
          return Matrix4.identity()..setUpper2x2(Matrix2.fromList(_data["t"].cast<double>()));
        case 6:
          return Matrix4.identity()..copyRotation(Matrix3.fromList(_data["t"].cast<double>()));
      }
    }
    return Matrix4.identity();
  }

  final Map<String, dynamic> _data;
}

// ----------------------------------------------------------------------
