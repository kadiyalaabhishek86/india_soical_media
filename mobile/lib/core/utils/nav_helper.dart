import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Safely pops the current route if possible; otherwise navigates cleanly to [fallbackRoute]
/// (avoids `GoError: There is nothing to pop` on root shell routes).
void safePop(BuildContext context, {String fallbackRoute = '/home', Object? result}) {
  if (context.canPop()) {
    context.pop(result);
  } else if (Navigator.canPop(context)) {
    Navigator.of(context).pop(result);
  } else {
    context.go(fallbackRoute);
  }
}

