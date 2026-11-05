import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// EPay brand palette — professional blue.
class AppColors {
  static const navy = Color(0xFF0A2A5E);
  static const navyDeep = Color(0xFF071E45);
  static const primary = Color(0xFF1557D6);
  static const primaryDark = Color(0xFF0E3C9B);
  static const sky = Color(0xFF2E9BF0);
  static const cyan = Color(0xFF5CC8F5);
  static const iceTop = Color(0xFFDDF0FF);
  static const ice = Color(0xFFE9F2FE);

  static const bg = Color(0xFFEFF4FC);
  static const card = Colors.white;
  static const text = Color(0xFF0F1B33);
  static const subText = Color(0xFF42506B);
  static const muted = Color(0xFF7A89A6);
  static const line = Color(0xFFE4EBF6);

  static const gold = Color(0xFFF2A516);
  static const amber = Color(0xFFFFB84D);
  static const green = Color(0xFF12B981);
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFFF7A1A);
  static const purple = Color(0xFF7C5CFC);
  static const pink = Color(0xFFEC4899);

  /// Main header / hero gradient.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDeep, primary, sky],
  );

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B6BEA), Color(0xFF0E3C9B)],
  );

  static const ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF2E9BF0), Color(0xFF1240A8)],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFFB020), Color(0xFFFF7A1A)],
  );

  static const screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [iceTop, bg, Color(0xFFF5F8FD)],
    stops: [0.0, 0.45, 1.0],
  );
}

class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.navy.withValues(alpha: 0.07),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];
  static List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.navy.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];
  static List<BoxShadow> raised = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.28),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.card,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.navy),
      titleTextStyle: TextStyle(
        color: AppColors.navy,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
