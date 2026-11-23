import 'package:flutter/material.dart';
import 'colors.dart';

class AaraTypography {
  // Playfair Display for the Aara wordmark and headline branding
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Playfair Display',
    fontFamilyFallback: ['Georgia', 'serif'],
    fontSize: 34,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AaraColors.textPrimary, // Deep aubergine
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Playfair Display',
    fontFamilyFallback: ['Georgia', 'serif'],
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AaraColors.textPrimary, // Deep aubergine
  );

  // Inter for titles, buttons, messages, controls, and timer
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: ['-apple-system', 'Segoe UI', 'Roboto', 'sans-serif'],
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    color: AaraColors.textPrimary, // Deep aubergine
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: ['-apple-system', 'Segoe UI', 'Roboto', 'sans-serif'],
    fontSize: 17,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AaraColors.textPrimary, // Deep aubergine
  );

  // Crisp Inter body text for messages and readouts
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: ['-apple-system', 'Segoe UI', 'Roboto', 'sans-serif'],
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: AaraColors.textPrimary, // Deep aubergine
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: ['-apple-system', 'Segoe UI', 'Roboto', 'sans-serif'],
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: AaraColors.textSecondary, // Muted purple-grey
    height: 1.4,
  );

  // Inter label for buttons
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: ['-apple-system', 'Segoe UI', 'Roboto', 'sans-serif'],
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: Colors.white, // White text on solid plum buttons
  );

  // Inter label for timestamps and small badges
  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: ['-apple-system', 'Segoe UI', 'Roboto', 'sans-serif'],
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: AaraColors.textSecondary, // Muted purple-grey
  );

  // Inter large numerical countdown timer
  static const TextStyle timerCountdown = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: ['-apple-system', 'Segoe UI', 'monospace'],
    fontSize: 54,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AaraColors.primary, // Large plum countdown
  );
}
