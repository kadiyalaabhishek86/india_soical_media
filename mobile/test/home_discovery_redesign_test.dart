import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/providers/auth_provider.dart';
import 'package:mobile/features/home/discover_friends_screen.dart';

class _NoOpHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

class TestAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  TestAuthNotifier()
      : super(
          AuthState(
            isAuthenticated: true,
            currentUserProfile: UserProfile(
              id: 'test-user-id',
              phone: '+919876543210',
              displayName: 'Aarav Sharma',
              dob: '1998-05-15',
              state: 'Maharashtra',
              city: 'Mumbai',
              freeCallsRemaining: 5,
              coins: 120,
              isPlusSubscriber: false,
              isAdult: true,
              rulesAccepted: true,
              languages: ['Hindi', 'English'],
              images: ['assets/telegram/wallpaper_sample.png'],
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _NoOpHttpOverrides();
  });

  group('Home Discovery Redesign Tests', () {
    testWidgets('Header displays FriendLoop branding, Coin balance, and Filters button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DiscoverFriendsScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('FriendLoop'), findsOneWidget);
      expect(find.text('Filters'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.text('Discover Friends'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('Profile card renders photo carousel, online status, looking for row, and view profile label', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DiscoverFriendsScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Check first profile details
      expect(find.text('Ananya Reddy, 26'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Looking for: Long-term relationship'), findsOneWidget);
      expect(find.text('View profile'), findsOneWidget);

      // Check the 4 action buttons
      expect(find.text('Pass'), findsOneWidget);
      expect(find.text('Like'), findsOneWidget);
      expect(find.text('Favorite'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('Action buttons: Pass advances to next profile, Favorite toggles with snackbar feedback', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DiscoverFriendsScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Ananya Reddy, 26'), findsOneWidget);

      // Tap Pass button
      await tester.tap(find.text('Pass'));
      await tester.pump();

      // Next profile should now be visible (Aman Gupta)
      expect(find.text('Aman Gupta, 27'), findsOneWidget);

      // Tap Favorite button
      await tester.tap(find.text('Favorite'));
      await tester.pump();

      // SnackBar feedback with Undo action should appear
      expect(find.text('Added Aman Gupta to Favorites! ⭐'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('Filters button opens bottom sheet with Location, Language, and Looking for options', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => TestAuthNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DiscoverFriendsScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap Filters button
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();

      // Verify bottom sheet title and sections
      expect(find.text('Filter Profiles'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Looking for'), findsWidgets);
      expect(find.text('Long-term relationship'), findsWidgets);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Apply Filters'), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
    });
  });
}
