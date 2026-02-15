import 'package:flutter/material.dart';

class AppShadows {
  static const BoxShadow shadow1 = BoxShadow(
    color: Color(0x0F000000),
    offset: Offset(0, 1),
    blurRadius: 2,
  );

  static const BoxShadow shadow2 = BoxShadow(
    color: Color(0x14000000),
    offset: Offset(0, 2),
    blurRadius: 8,
  );

  static const BoxShadow shadow3 = BoxShadow(
    color: Color(0x1F000000),
    offset: Offset(0, 4),
    blurRadius: 16,
  );

  static const BoxShadow shadow4 = BoxShadow(
    color: Color(0x29000000),
    offset: Offset(0, 8),
    blurRadius: 24,
  );
}
