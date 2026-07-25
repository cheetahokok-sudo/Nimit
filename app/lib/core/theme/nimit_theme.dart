import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens lifted from the v2 UI board (see the private Nimit-docs repo).
abstract final class NimitColors {
  // Base
  static const cream = Color(0xFFF6F0E4); // page background
  static const creamDeep = Color(0xFFEFE7D8); // outer canvas / wells
  static const surface = Color(0xFFFFFCF5); // cards
  static const border = Color(0xFFE7DECB);

  // Brand
  static const aubergine = Color(0xFF3B1E33); // dark cards, primary buttons
  static const aubergineDeep = Color(0xFF2C1626);
  static const gold = Color(0xFFE9C878); // number pills, CTA
  static const goldDeep = Color(0xFFD9B45C);

  // Text
  static const ink = Color(0xFF2B1B27);
  static const inkSoft = Color(0xFF877880);
  static const onDark = Color(0xFFF8F2E7);
  static const onDarkSoft = Color(0xFFCDBFC7);

  // Pastel chips
  static const pastelGreen = Color(0xFFDCE9D5);
  static const pastelPink = Color(0xFFF5DBE0);
  static const pastelLavender = Color(0xFFE6DDF0);
  static const pastelBlue = Color(0xFFDAE4F2);
  static const pastelCream = Color(0xFFF3EBDC);

  // Semantic
  static const successBg = Color(0xFFDFEBD9);
  static const successInk = Color(0xFF3E6242);
  static const warnBg = Color(0xFFF7E3E0);
  static const warnInk = Color(0xFFA05548);
}

ThemeData buildNimitTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: NimitColors.aubergine,
      primary: NimitColors.aubergine,
      secondary: NimitColors.goldDeep,
      surface: NimitColors.surface,
      onSurface: NimitColors.ink,
    ),
    scaffoldBackgroundColor: NimitColors.cream,
  );

  final textTheme = GoogleFonts.notoSansThaiTextTheme(base.textTheme).apply(
    bodyColor: NimitColors.ink,
    displayColor: NimitColors.ink,
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: NimitColors.cream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: NimitColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
        side: BorderSide(color: NimitColors.border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: NimitColors.cream,
      surfaceTintColor: Colors.transparent,
      indicatorColor: NimitColors.pastelPink,
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w600),
      ),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(color: NimitColors.ink, size: 22),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: NimitColors.aubergine,
        foregroundColor: NimitColors.onDark,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: NimitColors.ink,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: NimitColors.border, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: NimitColors.surface,
      side: const BorderSide(color: NimitColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: textTheme.labelMedium,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NimitColors.surface,
      hintStyle: textTheme.bodyMedium!.copyWith(color: NimitColors.inkSoft),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: NimitColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: NimitColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: NimitColors.aubergine, width: 1.6),
      ),
    ),
    dividerTheme: const DividerThemeData(color: NimitColors.border),
  );
}
