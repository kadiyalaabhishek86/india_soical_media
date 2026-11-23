import 'package:flutter/material.dart';

/// Central Design Palette for FriendLoop
/// Canvas #F4EBFC, Surface #FFFBFF, Lavender #EAD8FA, Violet #6E13D8,
/// Bright Violet #AC36EE, Plum #350D4D, Gold #FFC34D, Online Green #16834B, Rose #A52043
class FriendLoopColors {
  // 1. App canvas background
  static const Color canvas = Color(0xFFF4EBFC);
  static const Color background = Color(0xFFF4EBFC);

  // 2. Cards and chat surface
  static const Color surface = Color(0xFFFFFBFF);
  static const Color surfaceCard = Color(0xFFFFFBFF);
  static const Color surfaceLight = Color(0xFFFAF5FE);

  // 3. Violet brand tokens
  static const Color violet = Color(0xFF6E13D8);
  static const Color primary = Color(0xFF6E13D8);
  static const Color brightViolet = Color(0xFFAC36EE);
  static const Color plum = Color(0xFF350D4D);
  static const Color plumDark = Color(0xFF260838);
  static const Color plumLight = Color(0xFF8B2DE2);

  // 4. Accent tokens
  static const Color lavender = Color(0xFFEAD8FA);
  static const Color softLavender = Color(0xFFEAD8FA);
  static const Color selectedChip = Color(0xFFEAD8FA);
  static const Color bubbleOutgoing = Color(0xFFEAD8FA);
  static const Color bubbleIncoming = Color(0xFFFFFBFF);

  static const Color gold = Color(0xFFFFC34D);
  static const Color goldAccent = Color(0xFFFFC34D);
  static const Color peachBlush = Color(0xFFFFE8DD);

  // 5. Headings and body text
  static const Color textPrimary = Color(0xFF350D4D);
  static const Color textSecondary = Color(0xFF675677);
  static const Color textMuted = Color(0xFF9080A0);

  // 6. Card borders and dividers
  static const Color border = Color(0xFFE5D5F2);
  static const Color cardBorder = Color(0xFFE5D5F2);
  static const Color borderFocus = Color(0xFF6E13D8);
  static const Color divider = Color(0xFFE5D5F2);

  // 7. Status & Feedback
  static const Color onlineGreen = Color(0xFF16834B);
  static const Color success = Color(0xFF16834B);
  static const Color rose = Color(0xFFA52043);
  static const Color error = Color(0xFFA52043);
  static const Color warning = Color(0xFFE65100);
  static const Color pulseGlow = Color(0x336E13D8);

  // Backward-compatibility aliases
  static const Color plumViolet = Color(0xFF6E13D8);
  static const Color champagne = Color(0xFF6E13D8);
  static const Color champagneLight = Color(0xFFAC36EE);
  static const Color champagneDark = Color(0xFF350D4D);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6E13D8), Color(0xFFAC36EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient matchCardGradient = LinearGradient(
    colors: [Color(0xFFEAD8FA), Color(0xFFFFE8DD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient plumGradient = LinearGradient(
    colors: [Color(0xFF6E13D8), Color(0xFF350D4D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFC34D), Color(0xFFFF9E00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFFFFBFF), Color(0xFFF4EBFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

typedef AaraColors = FriendLoopColors;
