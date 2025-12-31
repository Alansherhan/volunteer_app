import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors - Soft Teal/Mint inspired palette
  static const Color primaryColor = Color(0xFF4ECDC4);
  static const Color primaryColorLight = Color(0xFF7EDDD6);
  static const Color primaryColorDark = Color(0xFF3BA99F);

  // Secondary Colors - Soft Lavender
  static const Color secondaryColor = Color(0xFF9B8CDB);
  static const Color secondaryColorLight = Color(0xFFB8ACE8);

  // Neutral Colors
  static const Color backgroundColor = Color(0xFFFAF6F1);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Gradient Colors
  static const Color gradientStart = Color(0xFFFAE5D3);
  static const Color gradientEnd = Color(0xFFFAF6F1);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Status Colors - Softer versions
  static const Color successColor = Color(0xFF5AAC6E);
  static const Color warningColor = Color(0xFFF5A862);
  static const Color errorColor = Color(0xFFE57373);
  static const Color infoColor = Color(0xFF64B5F6);

  // Gradient for backgrounds
  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientStart, gradientEnd],
  );

  // Gradient for cards/headers
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryColorLight],
  );

  static TextStyle mainFont({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return GoogleFonts.plusJakartaSans(
      textStyle: textStyle,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }

  // Modern Text Theme
  static TextTheme textTheme = TextTheme(
    displayLarge: mainFont(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: textPrimary,
    ),
    displayMedium: mainFont(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    displaySmall: mainFont(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    headlineLarge: mainFont(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: textPrimary,
    ),
    headlineMedium: mainFont(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    headlineSmall: mainFont(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    titleLarge: mainFont(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: textPrimary,
    ),
    titleMedium: mainFont(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: textPrimary,
    ),
    titleSmall: mainFont(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textSecondary,
    ),
    bodyLarge: mainFont(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: textPrimary,
    ),
    bodyMedium: mainFont(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: textSecondary,
    ),
    bodySmall: mainFont(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: textMuted,
    ),
    labelLarge: mainFont(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    labelMedium: mainFont(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: textSecondary,
    ),
  );

  // Input Decoration Theme - Softer styling
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: surfaceColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: errorColor),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: errorColor, width: 2),
    ),
    labelStyle: mainFont(color: textSecondary),
    hintStyle: mainFont(color: textMuted),
    prefixIconColor: textSecondary,
    suffixIconColor: textSecondary,
  );

  // Button Theme - Pill-shaped buttons
  static ElevatedButtonThemeData elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: primaryColor.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      textStyle: mainFont(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );

  static TextButtonThemeData textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColor,
      textStyle: mainFont(fontSize: 14, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  static OutlinedButtonThemeData outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primaryColor,
      side: const BorderSide(color: primaryColor, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      textStyle: mainFont(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );

  // Card Theme - Softer shadows
  static CardThemeData cardTheme = CardThemeData(
    color: surfaceColor,
    elevation: 0,
    shadowColor: Colors.black.withOpacity(0.08),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
  );

  // Soft box shadow for cards
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 25,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  // Bottom Navigation Bar Theme
  static BottomNavigationBarThemeData bottomNavTheme =
      BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: mainFont(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: mainFont(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      );

  // The Main ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      inputDecorationTheme: inputDecorationTheme,
      elevatedButtonTheme: elevatedButtonTheme,
      textButtonTheme: textButtonTheme,
      outlinedButtonTheme: outlinedButtonTheme,
      cardTheme: cardTheme,
      bottomNavigationBarTheme: bottomNavTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: mainFont(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withOpacity(0.1),
        labelStyle: mainFont(color: primaryColor, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
    );
  }
}
