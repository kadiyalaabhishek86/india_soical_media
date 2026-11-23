import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch and prevent transient web engine ViewInsets assertion errors during browser resize/zoom
  FlutterError.onError = (FlutterErrorDetails details) {
    final str = details.exceptionAsString();
    if (str.contains('ViewInsets cannot be negative') || str.contains('_viewInsets.isNonNegative')) {
      // Handled: transient browser visualViewport subpixel rounding during window resize
      return;
    }
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    final errStr = error.toString();
    if (errStr.contains('ViewInsets cannot be negative') || errStr.contains('_viewInsets.isNonNegative')) {
      // Return true to mark the error as handled so it doesn't crash the web app
      return true;
    }
    return false;
  };

  runApp(
    const ProviderScope(
      child: AaraApp(),
    ),
  );
}
