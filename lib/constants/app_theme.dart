// quest3_webdav_client - A WebDAV client optimized for Meta Quest 3.
// Copyright (C) 2026  Marcel Joachim Kloubert <marcel@kloubert.dev>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';

/// App theme constants optimized for Meta Quest 3 VR display.
///
/// Quest 3 specs:
/// - Display: 2064x2208 pixels per eye
/// - Refresh Rate: 90Hz (up to 120Hz)
/// - Field of View: 110° horizontal, 96° vertical
/// - Apps run as 2D panels floating in front of the user
class AppTheme {
  AppTheme._();

  // ============================================================
  // Colors - High contrast for VR readability
  // ============================================================

  /// Primary brand color.
  static const Color primaryColor = Color(0xFF6366F1);

  /// Primary color variant (darker).
  static const Color primaryColorDark = Color(0xFF4F46E5);

  /// Primary color variant (lighter).
  static const Color primaryColorLight = Color(0xFF818CF8);

  /// Secondary accent color.
  static const Color secondaryColor = Color(0xFF22D3EE);

  /// Background color for dark theme.
  static const Color backgroundColor = Color(0xFF0F172A);

  /// Surface color for cards and dialogs.
  static const Color surfaceColor = Color(0xFF1E293B);

  /// Elevated surface color.
  static const Color surfaceColorElevated = Color(0xFF334155);

  /// Error color.
  static const Color errorColor = Color(0xFFEF4444);

  /// Success color.
  static const Color successColor = Color(0xFF22C55E);

  /// Warning color.
  static const Color warningColor = Color(0xFFF59E0B);

  /// Text color on dark backgrounds.
  static const Color textPrimary = Color(0xFFF8FAFC);

  /// Secondary text color.
  static const Color textSecondary = Color(0xFF94A3B8);

  /// Disabled text color.
  static const Color textDisabled = Color(0xFF64748B);

  /// Divider color.
  static const Color dividerColor = Color(0xFF334155);

  // ============================================================
  // Predefined folder colors
  // ============================================================

  /// Available colors for folder icons.
  static const List<Color> folderColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFF59E0B), // Amber
    Color(0xFF22C55E), // Green
    Color(0xFF14B8A6), // Teal
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
  ];

  // ============================================================
  // Spacing - Larger for VR touch targets
  // ============================================================

  /// Extra small spacing.
  static const double spacingXs = 4.0;

  /// Small spacing.
  static const double spacingSm = 8.0;

  /// Medium spacing.
  static const double spacingMd = 16.0;

  /// Large spacing.
  static const double spacingLg = 24.0;

  /// Extra large spacing.
  static const double spacingXl = 32.0;

  /// Double extra large spacing.
  static const double spacingXxl = 48.0;

  // ============================================================
  // Border radius
  // ============================================================

  /// Small border radius.
  static const double radiusSm = 8.0;

  /// Medium border radius.
  static const double radiusMd = 12.0;

  /// Large border radius.
  static const double radiusLg = 16.0;

  /// Extra large border radius.
  static const double radiusXl = 24.0;

  // ============================================================
  // Typography - Larger for VR readability
  // ============================================================

  /// Display large text style.
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  /// Display medium text style.
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.25,
  );

  /// Headline large text style.
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Headline medium text style.
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Title large text style.
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Title medium text style.
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  /// Body large text style.
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );

  /// Body medium text style.
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );

  /// Body small text style.
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  /// Label large text style.
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  // ============================================================
  // Component sizes - Larger for VR touch targets
  // ============================================================

  /// Minimum touch target size (48dp recommended for VR).
  static const double minTouchTarget = 48.0;

  /// Button height.
  static const double buttonHeight = 56.0;

  /// Input field height.
  static const double inputHeight = 56.0;

  /// Card minimum height.
  static const double cardMinHeight = 80.0;

  /// App bar height.
  static const double appBarHeight = 64.0;

  /// Icon size small.
  static const double iconSizeSm = 20.0;

  /// Icon size medium.
  static const double iconSizeMd = 24.0;

  /// Icon size large.
  static const double iconSizeLg = 32.0;

  /// Icon size extra large.
  static const double iconSizeXl = 48.0;

  // ============================================================
  // Theme Data
  // ============================================================

  /// Creates the dark theme for the app.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: textPrimary,
        onSecondary: backgroundColor,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: appBarHeight,
        titleTextStyle: headlineMedium,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        margin: const EdgeInsets.all(spacingSm),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textPrimary,
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: const BorderSide(color: primaryColor),
          textStyle: labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          textStyle: labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColorElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: bodyMedium.copyWith(color: textSecondary),
        hintStyle: bodyMedium.copyWith(color: textDisabled),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: textPrimary,
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: headlineMedium,
        contentTextStyle: bodyLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceColorElevated,
        contentTextStyle: bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: spacingMd,
      ),
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: iconSizeMd,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingSm,
        ),
        minVerticalPadding: spacingSm,
        iconColor: textSecondary,
        textColor: textPrimary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: surfaceColorElevated,
      ),
    );
  }
}
