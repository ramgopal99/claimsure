import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  // Calm, clinical hospital palette with teal accent.
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.teal,
    brightness: Brightness.light,
  );

  final base = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );

  final roundedShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  final pillShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(100),
  );

  return base.copyWith(
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      shape: roundedShape,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: colorScheme.surfaceTint,
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      space: 24,
      thickness: 1,
    ),
    tabBarTheme: base.tabBarTheme.copyWith(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorColor: colorScheme.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: base.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      labelStyle: base.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      helperStyle: base.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: pillShape,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: pillShape,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: pillShape,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: BorderSide(color: colorScheme.outline),
        textStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: pillShape,
      extendedTextStyle: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onPrimary,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: roundedShape,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
      actionTextColor: colorScheme.secondary,
    ),
    dialogTheme: DialogThemeData(
      shape: roundedShape,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      contentTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      showDragHandle: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
    ),
    listTileTheme: ListTileThemeData(
      shape: roundedShape,
      iconColor: colorScheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide(color: colorScheme.outlineVariant),
      selectedColor: colorScheme.primaryContainer,
      labelStyle: base.textTheme.labelMedium,
    ),
    textTheme: base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        height: 1.4,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        height: 1.4,
      ),
    ),
  );
}

