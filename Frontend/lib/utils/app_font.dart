import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';

const List<Map<String, String>> kArabicFonts = [
  {'name': 'الماراي',  'family': 'Almarai'},
  {'name': 'القاهرة', 'family': 'Cairo'},
  {'name': 'تجوّل',   'family': 'Tajawal'},
  {'name': 'أميري',   'family': 'Amiri'},
];

TextStyle appFont({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
  TextDecoration? decoration,
  Color? decorationColor,
}) {
  return GoogleFonts.getFont(
    SettingsProvider.currentFont,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    decoration: decoration,
    decorationColor: decorationColor,
  );
}

TextTheme appTextTheme(String family, TextTheme base) =>
    GoogleFonts.getTextTheme(family, base);
