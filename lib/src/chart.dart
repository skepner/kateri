import 'dart:io';
import 'dart:ui';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert'; // json

import 'package:vector_math/vector_math_64.dart';
import 'package:flutter/foundation.dart';

import 'decompress.dart';
import 'viewport.dart';

// ----------------------------------------------------------------------

typedef _JsonData = Map<String, dynamic>;

class _JsonAccess {
  _JsonAccess(this.data);
  _JsonAccess.empty();

  late final _JsonData data;
}

// ----------------------------------------------------------------------

class Chart extends _JsonAccess {
  Chart({Uint8List? bytes, String? localPath, String? serverPath}) : super.empty() {
    //compute(_load, bytes: bytes, localPath: localPath, serverPath: serverPath);
    _load(bytes: bytes, localPath: localPath, serverPath: serverPath);
  }

  // ----------------------------------------------------------------------

  String name() {
    final fields = [
      _info['V'],
      if (_info['A'] != "HI") _info['A'],
      _info['r'],
      _info['l'],
      _makeDate(),
      if (_info["S"] != null) "(tables: ${_info['S']?.length})",
    ];
    return fields.where((field) => field != null).cast<String>().join(" ");
  }

  String nameForFilename() {
    final fields = [
      _subtypeShort(),
      if (_info['A'] != "HI") _info['A'],
      _info['r'],
      _info['l'],
      _makeDate(),
    ];
    return fields.where((field) => field != null).cast<String>().join("-")..replaceAll(RegExp(r'[\(\)/\s]'), "-").toLowerCase();
  }

  String? _makeDate() {
    if (_info['D'] != null) {
      return _info['D'];
    }
    final d1 = _info['S']?.first["D"] ?? "", d2 = _info['S']?.last["D"] ?? "";
    return "$d1-$d2";
  }

  String? _subtypeShort() {
    final subtype = _info["V"];
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

  int numberOfProjections() => _projections.length;

  Projection projection(int projectionNo) => _projections[projectionNo];

  // ----------------------------------------------------------------------
  // parse ace

  void _load({Uint8List? bytes, String? localPath, String? serverPath}) {
    if (bytes != null) {
      _parseJson(decompress(bytes));
    } else if (localPath != null) {
      _parseJson(decompress(File(localPath).readAsBytesSync()));
    } else if (serverPath != null) {
      // _parseJson(loadFromServer(serverPath));
    }
  }

  void _parseJson(List<int> source) {
    data = jsonDecode(utf8.decode(source));
    _info = data["c"]["i"];
    _projections = (data["c"]["P"] ?? []).map<Projection>((pdata) => Projection(pdata)).toList();
  }

  // ----------------------------------------------------------------------

  _JsonData _info = {};
  List<Projection> _projections = [];
}

// ----------------------------------------------------------------------

class _AntigenSerum extends _JsonAccess {
  _AntigenSerum(_JsonData data) : super(data);
}

class Antigen extends _AntigenSerum {
  Antigen(_JsonData data) : super(data);
}

typedef Antigens = List<Antigen>;

class Serum extends _AntigenSerum {
  Serum(_JsonData data) : super(data);
}

typedef Sera = List<Serum>;

// ----------------------------------------------------------------------

class Projection extends _JsonAccess {
  Projection(_JsonData data)
      : _layout = data["l"].map<Vector3?>(_layoutElement).toList(),
        _transformation = _makeTransformation(data["t"]),
        super(data) {
    _makeTransformedLayout();
  }

  String comment() => data["c"] ?? "";

  Viewport viewport() => _viewport;

  Layout transformedLayout() => _transformedLayout;

  // Layout layout() => _layout;

  double? stress() => data["s"];

  String minimumColumnBasis() => data["m"] ?? "none";

  List<double> forcedColumnBases() => data["C"]?.cast<double>().toList();

  List<int> disconnectedPoints() => data["D"]?.cast<int>().toList() ?? [];
  List<int> unmovablePoints() => data["U"]?.cast<int>().toList() ?? [];
  List<int> unmovableInLastDimensionPoints() => data["u"]?.cast<int>().toList() ?? [];

  // ----------------------------------------------------------------------

  static Vector3? _layoutElement(dynamic src) {
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

  static Matrix4 _makeTransformation(List<dynamic>? source) {
    if (source != null) {
      switch (source.length) {
        case 4:
          return Matrix4.identity()..setUpper2x2(Matrix2.fromList(source.cast<double>()));
        case 6:
          return Matrix4.identity()..copyRotation(Matrix3.fromList(source.cast<double>()));
      }
    }
    return Matrix4.identity();
  }

  void _makeTransformedLayout() {
    _transformedLayout = _layout.map((element) => element != null ? _transformation.transform3(element) : null).toList();
    _viewport = Viewport.hullLayout(_transformedLayout)..roundAndRecenter(_transformedLayout);
  }

  // ----------------------------------------------------------------------

  final Layout _layout;
  final Matrix4 _transformation;
  late Layout _transformedLayout;
  late Viewport _viewport;
}

// ----------------------------------------------------------------------
