import 'package:flutter/material.dart';

class AC {
  static const primary  = Color(0xFF7C4DFF);
  static const pLight   = Color(0xFF9E6FFF);
  static const success  = Color(0xFF00C896);
  static const warning  = Color(0xFFFFB830);
  static const danger   = Color(0xFFFF4757);
  static const info     = Color(0xFF4FC3F7);
  static const pink     = Color(0xFFFF6B9D);

  // Dark
  static const dBg      = Color(0xFF0D0D1A);
  static const dSurface = Color(0xFF13131F);
  static const dCard    = Color(0xFF1C1C2E);
  static const dCardAlt = Color(0xFF252538);
  static const dBorder  = Color(0xFF2E2E45);
  static const dText    = Color(0xFFFFFFFF);
  static const dTextSub = Color(0xFFAAAAAC);
  static const dMuted   = Color(0xFF5A5A7A);

  // Light
  static const lBg      = Color(0xFFF4F2FF);
  static const lSurface = Color(0xFFFFFFFF);
  static const lCard    = Color(0xFFFFFFFF);
  static const lCardAlt = Color(0xFFEEEBFF);
  static const lBorder  = Color(0xFFDDD8FF);
  static const lText    = Color(0xFF13131F);
  static const lTextSub = Color(0xFF4A4A6A);
  static const lMuted   = Color(0xFF9090B0);

  static const List<Color> palette = [
    Color(0xFF7C4DFF), Color(0xFFFF6B6B), Color(0xFF00C896),
    Color(0xFFFFB830), Color(0xFF4FC3F7), Color(0xFFFF79A8),
    Color(0xFFA29BFE), Color(0xFF55EFC4), Color(0xFFFF7675),
    Color(0xFF74B9FF), Color(0xFFFDCB6E), Color(0xFFE17055),
  ];

  static const grad      = LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF9E6FFF)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const fireGrad  = LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFFB830)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const greenGrad = LinearGradient(colors: [Color(0xFF00C896), Color(0xFF55EFC4)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const pinkGrad  = LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)], begin: Alignment.topLeft, end: Alignment.bottomRight);
}
