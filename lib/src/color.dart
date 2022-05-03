import 'dart:ui';
import 'package:flutter/material.dart';

// ----------------------------------------------------------------------

const black = Color(0xFF000000);
const gray = Color(0xFFBEBEBE);
const gray50 = Color(0xFF7F7F7F);
const gray80 = Color(0xFFCCCCCC);
const gray97 = Color(0xFFF7F7F7);
const white = Color(0xFFFFFFFF);
const transparent = Color(0x00000000);
const red = Color(0xFFFF0000);
const green = Color(0xFF00FF00);
const blue = Color(0xFF0000FF);
const cyan = Color(0xff00FFFF);
const orange = Color(0xFFFFA500);
const magenta = Color(0xffFF00FF);
const purple = Color(0xffA020F0);
const pink = Color(0xffFFC0CB);
const yellow = Color(0xffFFFF00);
const brown = Color(0xffA52A2A);
const cornflowerblue = Color(0xff6495ED);
const gold = Color(0xffFFD700);

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
  "transparent": transparent,
  "black": black,
  "gray": gray,
  "white": white,
  "red": red,
  "green": green,
  "blue": blue,
  "cyan": cyan,
  "magenta": magenta,
  "yellow": yellow,
  "brown": brown,
  "cornflowerblue": cornflowerblue,
  "gold": gold,
  "orange": orange,
  "pink": pink,
  "purple": purple,
};

// ----------------------------------------------------------------------
