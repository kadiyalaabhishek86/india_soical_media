import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class FriendLoopTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: FriendLoopColors.background,
      colorScheme: const ColorScheme.light(
        primary: FriendLoopColors.primary,
        secondary: FriendLoopColors.lavender,
        surface: FriendLoopColors.surface,
        error: FriendLoopColors.error,
        onPrimary: Colors.white,
        onSecondary: FriendLoopColors.textPrimary,
        onSurface: FriendLoopColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: FriendLoopColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AaraTypography.titleMedium,
        iconTheme: IconThemeData(color: FriendLoopColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: FriendLoopColors.primary,
        unselectedItemColor: FriendLoopColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: FriendLoopColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: FriendLoopColors.border, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: FriendLoopColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: FriendLoopColors.border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: FriendLoopColors.divider,
        thickness: 1,
      ),
    );
  }

  // Alias
  static ThemeData get luxuryDarkTheme => lightTheme;
}

typedef AaraTheme = FriendLoopTheme;
