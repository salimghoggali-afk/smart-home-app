import 'package:material_ui/material_ui.dart';

/// Brand colors for the app.
class AppColors {
  static const seed = Color(0xFF0E9F8E); // teal, from the original app
  static const night = Color(0xFF0B1D26); // splash background
  static const nightDeep = Color(0xFF06121A);
  static const glow = Color(0xFF3FE0C5);
  static const warm = Color(0xFFFFC857); // lamp light accent
}

ThemeData buildTheme(Brightness brightness) {
  var scheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: brightness,
  );
  if (brightness == Brightness.light) {
    // v1.7: a little darker than the default Material light tones, still light.
    scheme = scheme.copyWith(
      surface: const Color(0xFFE4EBE9),
      surfaceContainerLowest: const Color(0xFFF4F7F6),
      surfaceContainerLow: const Color(0xFFEDF2F1),
      surfaceContainer: const Color(0xFFE2E9E7),
      surfaceContainerHigh: const Color(0xFFD9E2E0),
      surfaceContainerHighest: const Color(0xFFD0DAD8),
      surfaceDim: const Color(0xFFCCD6D4),
      surfaceBright: const Color(0xFFF1F5F4),
    );
  }
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
  );
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
  );
}
