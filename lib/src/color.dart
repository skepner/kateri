import 'dart:ui';
import 'package:flutter/material.dart';

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
      return _colorNames[src] ?? Colors.pink;
    }
    return Colors.pink;
  }
}

// ----------------------------------------------------------------------

const _colorNames = <String, Color>{
  "transparent": Color(0x00000000),
  "black": Color(0xff000000),
  "white": Color(0xffFFFFFF),
  "red": Color(0xffFF0000),
  "green": Color(0xff00FF00),
  "blue": Color(0xff0000FF),
  "cyan": Color(0xff00FFFF),
  "magenta": Color(0xffFF00FF),
  "yellow": Color(0xffFFFF00),
  "brown": Color(0xffA52A2A),
  "cornflowerblue": Color(0xff6495ED),
  "gold": Color(0xffFFD700),
  "orange": Color(0xffFFA500),
  "pink": Color(0xffFFC0CB),
  "purple": Color(0xffA020F0),
};

// ----------------------------------------------------------------------
