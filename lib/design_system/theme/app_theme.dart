import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_sizes.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      inputDecorationTheme: _inputDecorationTheme,
      filledButtonTheme: _filledButtonTheme,
      switchTheme: _switchTheme,
      textTheme: _textTheme,
    );
  }

  static InputDecorationTheme get _inputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(color: AppColors.textDisabled),
      errorStyle: const TextStyle(
        color: AppColors.danger,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
      ),
    );
  }

  static FilledButtonThemeData get _filledButtonTheme {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.disabled,
        disabledForegroundColor: AppColors.textDisabled,
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  static SwitchThemeData get _switchTheme {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.onPrimary;
        }

        return AppColors.textDisabled;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }

        return AppColors.disabled;
      }),
    );
  }

  static TextTheme get _textTheme {
    return const TextTheme(
      displaySmall: TextStyle(
        fontSize: 36,
        height: 1.12,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        height: 1.15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
