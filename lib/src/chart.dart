import 'dart:convert'; // json
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'error.dart';
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
  Chart(List<int> source) : super.empty() {
    _parseJson(source);
  }

  // ----------------------------------------------------------------------

  /// List of reference antigen indexes
  Iterable<int> referenceAntigens() {
    bool hasSerum(String name) => sera.where((serum) => serum.name == name).isNotEmpty;
    return Iterable<int>.generate(antigens.length).where((agNo) => hasSerum(antigens[agNo].name));
  }

  // ----------------------------------------------------------------------

  PlotSpec plotSpecDefault([Projection? projection]) => PlotSpecDefault(this, projection ?? projections[0]);
  PlotSpec plotSpecLegacy([Projection? projection]) => _hasPlotSpecLegacy ? PlotSpecLegacy(this) : plotSpecDefault(projection);

  List<PlotSpec> plotSpecs([Projection? projection]) {
    final specs = <PlotSpec>[];
    if (_hasPlotSpecSemantic) {
      data["c"]["R"].forEach((name, plotSpecData) {
        specs.add(PlotSpecSemantic(this, projection ?? projections[0], name, plotSpecData));
      });
    }
    if (_hasPlotSpecLegacy) {
      specs.add(PlotSpecLegacy(this));
    }
    if (specs.isEmpty) {
      specs.add(plotSpecDefault(projection));
    }
    specs.sort((e1, e2) => e1.priority().compareTo(e2.priority()));
    return specs;
  }

  // ----------------------------------------------------------------------
  // parse ace

  void _parseJson(List<int> source) {
    late final String utf8Decoded;
    try {
      utf8Decoded = utf8.decode(source);
    } catch (err) {
      throw FormatError("utf8 decoding failed: $err");
    }
    try {
      data = jsonDecode(utf8Decoded);
    } catch (err) {
      throw FormatError("json decoding failed: $err");
    }
    info = Info(data["c"]["i"]);
    titers = Titers(data["c"]["t"]);
    antigens = (data["c"]["a"] ?? []).map<Antigen>((pdata) => Antigen(pdata)).toList();
    sera = (data["c"]["s"] ?? []).map<Serum>((pdata) => Serum(pdata)).toList();
    projections = (data["c"]["P"] ?? []).map<Projection>((pdata) => Projection(pdata)).toList();
  }

  bool get _hasPlotSpecLegacy => data["c"]["p"] != null;
  bool get _hasPlotSpecSemantic => data["c"]["R"] != null;

  // ----------------------------------------------------------------------

  Titer homologousTiterForSerum(int serumNo) {
    final serum = sera[serumNo];
    var bestRank = 1024;
    var bestTiter = Titer("*");
    // debug("SR $serumNo ${serum.name} ${serum.annotations} ${serum.reassortant} ${serum.passage}");
    for (int antigenNo = 0; antigenNo < antigens.length; ++antigenNo) {
      final antigen = antigens[antigenNo];
      if (serum.name == antigen.name) {
        int rank = 0;
        if (!listEquals(serum.annotations, antigen.annotations)) rank += 16;
        if (serum.reassortant != antigen.reassortant) rank += 8;
        if (serum.passage != antigen.passage) {
          rank += 4;
          if (serum.semantic["p"] != antigen.semantic["p"]) rank += 2;
        }
        final titer = titers.titer(antigenNo, serumNo);
        if (!titer.isDontCare && rank < bestRank) {
          bestRank = rank;
          bestTiter = titer;
        }
        //debug("  AG $antigenNo rank: $rank titer: $titer ${antigen.name} ${antigen.annotations} ${antigen.reassortant} ${antigen.passage}");
      }
    }
    return bestTiter;
  }

  // ----------------------------------------------------------------------

  Info info = Info.empty();
  Titers titers = Titers.empty();
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
  bool get isEgg => passage.contains(RegExp(r"(?:E(?:GG)?)[0-9X\?]*$"));
  Map<String, dynamic> get semantic => data["T"] ?? {};
}

class Antigen extends _AntigenSerum {
  Antigen(_JsonData data) : super(data);

  String get date => data["D"] ?? "";
  List<String> get labIds => data["l"] ?? [];

  bool withinDateRange(String first, String last) {
    final dat = date;
    if (dat.isEmpty) return first.isEmpty; // antigen without date is within range if first is empty, i.e. it is kinda at the beginning of all dates
    return (first.isEmpty || first.compareTo(dat) <= 0) && (last.isEmpty || last.compareTo(dat) > 0);
  }
}

typedef Antigens = List<Antigen>;

class Serum extends _AntigenSerum {
  Serum(_JsonData data) : super(data);

  String get species => data["s"] ?? "";
  String get serumId => data["I"] ?? "";
}

typedef Sera = List<Serum>;

// ----------------------------------------------------------------------

class Titers extends _JsonAccess {
  Titers(_JsonData data)
      : _dense = data["l"] != null,
        super(data);
  Titers.empty()
      : _dense = false,
        super.empty();

  Titer titer(int antigenNo, int serumNo) {
    if (_dense) {
      return Titer(data["l"][antigenNo]?[serumNo] ?? "*");
    } else {
      return Titer(data["d"][antigenNo]?["$serumNo"] ?? "*");
    }
  }

  bool _dense;
}

class Titer {
  Titer(this._titer);

  bool get isDontCare => _titer == "*";
  bool get isLessThan => _titer[0] == "<";
  bool get isMoreThan => _titer[0] == ">";
  bool get isThresholded => isLessThan || isMoreThan;

  double get value {
    if (isDontCare) return 0.0;
    if (isThresholded) return double.parse(_titer.substring(1));
    return double.parse(_titer);
  }

  double get logged => math.log(value / 10.0) / math.ln2;
  double get loggedForColumnBases {
    if (isMoreThan) return logged + 1.0;
    return logged;
  }

  String toString() => _titer;

  String _titer;
}

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
      final data = List<double>.from(source.map<double>((value) => value.toDouble())); // using map, some values may represented as int and then source.cast<double>() fails
      switch (source.length) {
        case 4:
          return Matrix4.identity()..setUpper2x2(Matrix2.fromList(data));
        case 6:
          return Matrix4.identity()..copyRotation(Matrix3.fromList(data));
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

bool semanticMatch(String semanticKey, dynamic semanticValue, Map<String, dynamic> attributes) {
  // if (semanticKey == "R") print("semanticMatch key:$semanticKey value:$semanticValue attrs:$attributes");
  final attrVal = attributes[semanticKey];
  if (semanticValue is bool) return semanticValue == (attrVal != null);
  if (attrVal == null) return false;
  if (attrVal is List) return attrVal.contains(semanticValue);
  return attrVal == semanticValue;
}

// bool semanticMatch(Map<String, dynamic> selector, Map<String, dynamic> attributes) {
//   // print(attributes);
//   return selector.entries.fold(true, (result, en) {
//       if (!result) return false;
//       if (en.value is bool) return en.value && attributes.containsKey(en.key);

//       final attrVal = attributes[en.key];
//       if (attrVal == null) return false;
//       if (attrVal is List) return attrVal.contains(en.value);
//       return attrVal == en.value;
//   });
// }

// ----------------------------------------------------------------------
