import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme.dart';
import 'core/router/app_router.dart';

class FriendLoopApp extends ConsumerWidget {
  const FriendLoopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'FriendLoop',
      debugShowCheckedModeBanner: false,
      theme: FriendLoopTheme.lightTheme,
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: appRouter,
    );
  }
}

typedef AaraApp = FriendLoopApp;
