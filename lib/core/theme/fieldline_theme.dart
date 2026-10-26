import 'package:flutter/material.dart';

/// Bảng màu Fieldline lấy từ file Figma "Field Inventory - Wireframe".
abstract final class FlColors {
  // Nền & bề mặt
  static const background = Color(0xFFF4F7F9);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFF7F9FA);
  static const border = Color(0xFFE1E8EC);
  static const track = Color(0xFFEDF2F4);

  // Chữ
  static const ink = Color(0xFF182F3C);
  static const muted = Color(0xFF6D808B);

  // Màu nhấn chính (teal)
  static const primary = Color(0xFF087F78);
  static const primarySoft = Color(0xFFE3F4EE);
  static const primaryTint = Color(0xFFE0ECEE);
  static const online = Color(0xFF11A886);

  // Trạng thái
  static const warning = Color(0xFF926313);
  static const warningStrong = Color(0xFFB67B27);
  static const warningSoft = Color(0xFFFFF2D6);
  static const info = Color(0xFF476AB1);
  static const infoSoft = Color(0xFFE8EFFB);
  static const danger = Color(0xFFB6443F);
  static const dangerSoft = Color(0xFFFDECEA);
  static const neutralSoft = Color(0xFFEDF1F4);
  static const notification = Color(0xFFDF835E);

  // Sidebar tối
  static const sidebar = Color(0xFF102A36);
  static const sidebarCard = Color(0xFF1C3945);
  static const sidebarActive = Color(0xFF214D56);
  static const sidebarAccent = Color(0xFF35D5BA);
  static const sidebarOffline = Color(0xFF173E46);
  static const sidebarOfflineDot = Color(0xFF41D4B3);
  static const sidebarText = Color(0xFFB5C8D1);
  static const sidebarLabel = Color(0xFF7E9AA8);
  static const sidebarSubtle = Color(0xFF8EA9B4);
  static const sidebarBadge = Color(0xFF4C4939);
  static const sidebarBadgeText = Color(0xFFF4CE78);
  static const logoTile = Color(0xFF0BA899);
  static const avatar = Color(0xFF476671);

  // Camera
  static const camera = Color(0xFF173238);
  static const cameraGrid = Color(0xFF22424A);
  static const cameraHighlight = Color(0xFF45D6B5);
}

/// Bán kính bo góc dùng chung.
abstract final class FlRadius {
  static const card = 12.0;
  static const control = 8.0;
}

ThemeData buildFieldlineTheme() {
  final base = ThemeData(
    useMaterial3: true,
    // Inter được đóng gói trong assets/fonts để dùng được khi ngoại tuyến.
    fontFamily: 'Inter',
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: FlColors.primary,
      primary: FlColors.primary,
      onPrimary: Colors.white,
      surface: FlColors.surface,
      onSurface: FlColors.ink,
      onSurfaceVariant: FlColors.muted,
      outline: FlColors.border,
      outlineVariant: FlColors.border,
      error: FlColors.danger,
    ),
    scaffoldBackgroundColor: FlColors.background,
  );

  final textTheme = base.textTheme.apply(
    bodyColor: FlColors.ink,
    displayColor: FlColors.ink,
  );

  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(FlRadius.control),
  );

  return base.copyWith(
    textTheme: textTheme,
    dividerTheme: const DividerThemeData(
      color: FlColors.border,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: FlColors.background,
      foregroundColor: FlColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: FlColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: controlShape,
        textStyle: textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FlColors.ink,
        backgroundColor: FlColors.surface,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        side: const BorderSide(color: FlColors.border),
        shape: controlShape,
        textStyle: textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: FlColors.primary,
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FlColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: FlColors.muted, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(FlRadius.control),
        borderSide: const BorderSide(color: FlColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(FlRadius.control),
        borderSide: const BorderSide(color: FlColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(FlRadius.control),
        borderSide: const BorderSide(color: FlColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(FlRadius.control),
        borderSide: const BorderSide(color: FlColors.danger),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? FlColors.primary
            : Colors.transparent,
      ),
      side: const BorderSide(color: FlColors.border, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? FlColors.primary
            : FlColors.border,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: FlColors.ink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FlRadius.control),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: FlColors.primary,
    ),
  );
}
