import 'dart:io';
import 'dart:ui';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert'; // json

import 'package:vector_math/vector_math_64.dart';
import 'package:flutter/foundation.dart';

import 'decompress.dart';
import 'viewport.dart';
import 'plot_spec.dart';

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

  /// List of reference antigen indexes
  Iterable<int> referenceAntigens() {
    bool hasSerum(String name) => sera.where((serum) => serum.name == name).isNotEmpty;
    return Iterable<int>.generate(antigens.length).where((agNo) => hasSerum(antigens[agNo].name));
  }

  // ----------------------------------------------------------------------

  PlotSpecDefault plotSpecDefault([Projection? projection]) => PlotSpecDefault(this, projection ?? projections[0]);

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
    info = Info(data["c"]["i"]);
    antigens = (data["c"]["a"] ?? []).map<Antigen>((pdata) => Antigen(pdata)).toList();
    sera = (data["c"]["s"] ?? []).map<Serum>((pdata) => Serum(pdata)).toList();
    projections = (data["c"]["P"] ?? []).map<Projection>((pdata) => Projection(pdata)).toList();
  }

  // ----------------------------------------------------------------------

  Info info = Info.empty();
  Projections projections = [];
  Antigens antigens = [];
  Sera sera = [];
}

// ----------------------------------------------------------------------

class Info extends _JsonAccess {
  Info(_JsonData data) : super(data);
  Info.empty() : super.empty();

  String name() {
    final fields = [
      data['V'],
      if (data['A'] != "HI") data['A'],
      data['r'],
      data['l'],
      _makeDate(),
      if (data["S"] != null) "(tables: ${data['S']?.length})",
    ];
    return fields.where((field) => field != null).cast<String>().join(" ");
  }

  String nameForFilename() {
    final fields = [
      _subtypeShort(),
      if (data['A'] != "HI") data['A'],
      data['r'],
      data['l'],
      _makeDate(),
    ];
    return fields.where((field) => field != null).cast<String>().join("-")..replaceAll(RegExp(r'[\(\)/\s]'), "-").toLowerCase();
  }

  String? _makeDate() {
    if (data['D'] != null) {
      return data['D'];
    }
    final d1 = data['S']?.first["D"] ?? "", d2 = data['S']?.last["D"] ?? "";
    return "$d1-$d2";
  }

  String? _subtypeShort() {
    final subtype = data["V"];
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
}

// ----------------------------------------------------------------------

class _AntigenSerum extends _JsonAccess {
  _AntigenSerum(_JsonData data) : super(data);

  String get name => data["N"] ?? "";
  List<String> get annotations => data["a"] ?? [];
  String get lineage => data["L"] ?? "";
  String get passage => data["P"] ?? "";
  String get reassortant => data["R"] ?? "";
  String get aa => data["A"] ?? "";
  String get nuc => data["B"] ?? "";
  bool get isReassortant => reassortant.isNotEmpty;
  bool get isEgg => passage.contains(RegExp(r"(?:E(?:GG))[\dX\?]*$"));
  Map<String, dynamic> get semantic => data["T"] ?? {};
}

class Antigen extends _AntigenSerum {
  Antigen(_JsonData data) : super(data);

  String get date => data["D"] ?? "";
  List<String> get labIds => data["l"] ?? [];
}

typedef Antigens = List<Antigen>;

class Serum extends _AntigenSerum {
  Serum(_JsonData data) : super(data);

  String get species => data["s"] ?? "";
  String get serumId => data["I"] ?? "";
}

typedef Sera = List<Serum>;

// ----------------------------------------------------------------------

class Projection extends _JsonAccess {
  Projection(_JsonData data)
      : layout = data["l"].map<Vector3?>(_layoutElement).toList(),
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
    _transformedLayout = layout.map((element) => element != null ? _transformation.transform3(element) : null).toList();
    _viewport = Viewport.hullLayout(_transformedLayout)..roundAndRecenter(_transformedLayout);
  }

  // ----------------------------------------------------------------------

  final Layout layout;
  final Matrix4 _transformation;
  late Layout _transformedLayout;
  late Viewport _viewport;
}

typedef Projections = List<Projection>;

// ----------------------------------------------------------------------
