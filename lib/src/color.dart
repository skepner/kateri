import 'dart:ui';
import 'package:flutter/material.dart';

// ----------------------------------------------------------------------

// const black = Color(0xFF000000);
// const gray = Color(0xFFBEBEBE);
// const gray50 = Color(0xFF7F7F7F);
// const gray80 = Color(0xFFCCCCCC);
// const gray97 = Color(0xFFF7F7F7);
// const white = Color(0xFFFFFFFF);
// const transparent = Color(0x00000000);
// const red = Color(0xFFFF0000);
// const green = Color(0xFF00FF00);
// const blue = Color(0xFF0000FF);
// const cyan = Color(0xff00FFFF);
// const orange = Color(0xFFFFA500);
// const magenta = Color(0xffFF00FF);
// const purple = Color(0xffA020F0);
// const pink = Color(0xffFFC0CB);
// const yellow = Color(0xffFFFF00);
// const brown = Color(0xffA52A2A);
// const cornflowerblue = Color(0xff6495ED);
// const gold = Color(0xffFFD700);

// ----------------------------------------------------------------------

extension NamedColor on Color {
  static Color fromString(String src) {
    if (src[0] == "#") {
      switch (src.length) {
        case 7:
          return Color(int.parse(src.replaceFirst('#', 'ff'), radix: 16));
        case 9:
          return Color(int.parse(src.replaceFirst('#', ''), radix: 16));
      }
    } else {
      return _colorNames[src.toLowerCase()] ?? Colors.pink;
    }
    return Colors.pink;
  }

  static Color fromStringOr(String? src, String dflt) {
    if (src != null && src.isNotEmpty) return fromString(src);
    return fromString(dflt);
  }
}

// ----------------------------------------------------------------------

class ColorAndModifier {
  String _color;
  String? _modifier;

  ColorAndModifier(this._color);
  ColorAndModifier.copy(ColorAndModifier src)
      : _color = src._color,
        _modifier = src._modifier;

  ColorAndModifier copy() => ColorAndModifier.copy(this);

  void modify(String toAdd) {
    if (toAdd.isNotEmpty) {
      if (toAdd[0] == ":") {
        if (_modifier == ":pale" && toAdd == ":bright") {
          _modifier = null;
        } else if (toAdd == ":pale") {
          _modifier = toAdd;
        }
      } else {
        _color = toAdd;
      }
    }
  }

  Color get color {
    var clr = NamedColor.fromString(_color);
    if (_modifier == ":pale") {
      final hsv = HSVColor.fromColor(clr);
      clr = hsv.withSaturation(hsv.saturation * 0.2).withValue(_paleValue(hsv.value)).toColor();
    }
    return clr;
  }

  double _paleValue(double source) {
    if (source > 0.5) {
      return 1.0;
    } else if (source == 0.0) {
      return 0.7;
    } else {
      return source * 2.0;
    }
  }
}

// ----------------------------------------------------------------------

const _colorNames = <String, Color>{
  "t": Color(0x00000000),
  "transparent": Color(0x00000000),
  "black": Color(0xFF000000),
  "gray": Color(0xFFBEBEBE),
  "grey": Color(0xFFBEBEBE),
  "grey80": Color(0xFFCCCCCC),
  "white": Color(0xFFFFFFFF),
  "red": Color(0xFFFF0000),
  "green": Color(0xFF00FF00),
  "blue": Color(0xFF0000FF),
  "cyan": Color(0xff00FFFF),
  "magenta": Color(0xffFF00FF),
  "yellow": Color(0xffFFFF00),
  "brown": Color(0xffA52A2A),
  "cornflowerblue": Color(0xff6495ED),
  "gold": Color(0xffFFD700),
  "orange": Color(0xFFFFA500),
  "pink": Color(0xffFFC0CB),
  "purple": Color(0xffA020F0),
};

// ----------------------------------------------------------------------
