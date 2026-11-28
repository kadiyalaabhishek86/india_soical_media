import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/providers/auth_provider.dart';
import 'package:mobile/core/providers/favorites_provider.dart';
import 'package:mobile/core/providers/notifications_provider.dart';
import 'package:mobile/core/providers/reels_provider.dart';
import 'package:mobile/core/providers/rooms_provider.dart';
import 'package:mobile/features/home/discover_friends_screen.dart';
import 'package:mobile/features/friends/friend_profile_screen.dart';
import 'package:mobile/features/match/random_connect_screen.dart';
import 'package:mobile/features/profile/profile_screen.dart';
import 'package:mobile/features/reels/reels_screen.dart';
import 'package:mobile/features/rooms/create_room_screen.dart';
import 'package:mobile/features/rooms/live_rooms_screen.dart';
import 'package:mobile/features/notifications/notifications_screen.dart';

class _NoOpHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

class _GenderAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _GenderAuthNotifier(String gender)
      : super(
          AuthState(
            isAuthenticated: true,
            currentUserProfile: UserProfile(
              id: 'gender-test-id',
              phone: '+919876543210',
              displayName: gender == 'Male' ? 'Aarav' : 'Priya',
              gender: gender,
              state: 'Maharashtra',
              languages: const ['Hindi', 'English'],
              freeCallsRemaining: 5,
              isAdult: true,
              rulesAccepted: true,
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

  group('Bug Fixes Verification Tests', () {
    testWidgets('Tapping Like on Discover Friends also adds profile to Favorites', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DiscoverFriendsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(container.read(favoritesProvider), isEmpty);

      await tester.tap(find.text('Like'));
      await tester.pump();

      final favs = container.read(favoritesProvider);
      expect(favs.length, 1);
      expect(favs.first.displayName, 'Ananya Reddy');

      // Dispose tree and advance past timers cleanly
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 35));
    });

    testWidgets('FriendProfileScreen updates button to Friend Request Sent when + Add Friend is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FriendProfileScreen(friendshipId: 'test-fs-1'),
          ),
        ),
      );
      await tester.pump();

      await tester.ensureVisible(find.text('+ Add Friend'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Add Friend'));
      await tester.pump();

      expect(find.text('Friend Request Sent'), findsOneWidget);
      await tester.pump(const Duration(seconds: 35));
    });

    testWidgets('CreateRoomScreen removes Room Type and shows only games', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateRoomScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Select Game to Play'), findsOneWidget);
      expect(find.text('Room Type'), findsNothing);
      expect(find.text('Voice Lounge'), findsNothing);
      expect(find.text('Video Stage'), findsNothing);
      expect(find.text('Ludo 2v2 Arena'), findsOneWidget);
      expect(find.text('Carrom Clash'), findsOneWidget);
    });

    testWidgets('LiveRoomsScreen removes Recent Calls and supports inline event search', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LiveRoomsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Recent Calls'), findsNothing);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Random Connect'), findsOneWidget);

      // Tap search icon to filter rooms by event name
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Carrom');
      await tester.pump();

      expect(find.text('Carrom Clash Match #408 🎯'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Telugu Hangout'), findsNothing);

      await tester.pump(const Duration(seconds: 35));
    });

    testWidgets('NotificationsScreen shows unread messages and missed calls', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.textContaining('Priya Sharma sent 3 unread messages'), findsOneWidget);
      expect(find.textContaining('Missed video call from Priya Sharma'), findsOneWidget);
      expect(find.textContaining('Ananya Reddy liked your profile'), findsOneWidget);
      expect(find.textContaining('Priya started Ludo 2v2 Party'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
    });

    testWidgets('RandomConnectScreen includes Country (optional) selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RandomConnectScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Country (optional)'), findsOneWidget);
      expect(find.text('Any country'), findsOneWidget);
      expect(find.text('Language (optional)'), findsOneWidget);

      await tester.pump(const Duration(seconds: 35));
    });

    testWidgets('ReelsScreen removes search icon and ReelsNotifier increments comment count', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final firstReel = container.read(reelsProvider).first;
      final initialCount = firstReel['comments_count'] as int;
      container.read(reelsProvider.notifier).incrementCommentCount(firstReel['id'].toString());
      expect(container.read(reelsProvider).first['comments_count'], initialCount + 1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ReelsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.search), findsNothing);
      expect(find.text('Friends Reels'), findsOneWidget);

      await tester.pump(const Duration(seconds: 35));
    });

    testWidgets('LiveRoomsScreen shows running rooms strip and closed/expired rooms stay removed', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialRooms = container.read(roomsProvider).rooms;
      expect(initialRooms, isNotEmpty);
      final removedId = initialRooms.first.id;
      container.read(roomsProvider.notifier).closeRoom(removedId);
      expect(container.read(roomsProvider).rooms.any((r) => r.id == removedId), isFalse);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LiveRoomsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Running Now • Public View'), findsOneWidget);

      await tester.pump(const Duration(seconds: 35));
    });

    testWidgets('ProfileScreen Edit buttons open full-item sheets for Essentials, Lifestyle, Basics', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pump();

      // Scroll down to Essentials/Lifestyle/Basics cards and tap each section's Edit button
      await tester.scrollUntilVisible(
        find.text('Basics'),
        300.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      final editButtons = find.text('Edit');
      expect(editButtons, findsAtLeastNWidgets(5));

      await tester.ensureVisible(editButtons.at(2));
      await tester.tap(editButtons.at(2));
      await tester.pumpAndSettle();
      expect(find.text('Edit Essentials'), findsOneWidget);
      expect(find.text('Save Essentials'), findsOneWidget);
      await tester.ensureVisible(find.text('Save Essentials'));
      await tester.tap(find.text('Save Essentials'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(editButtons.at(3));
      await tester.tap(editButtons.at(3));
      await tester.pumpAndSettle();
      expect(find.text('Edit Lifestyle'), findsOneWidget);
      expect(find.text('Save Lifestyle'), findsOneWidget);
      await tester.ensureVisible(find.text('Save Lifestyle'));
      await tester.tap(find.text('Save Lifestyle'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(editButtons.at(4));
      await tester.tap(editButtons.at(4));
      await tester.pumpAndSettle();
      expect(find.text('Edit Basics'), findsOneWidget);
      expect(find.text('Save Basics'), findsOneWidget);
      await tester.ensureVisible(find.text('Save Basics'));
      await tester.tap(find.text('Save Basics'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 35));
    });

    testWidgets('DiscoverFriendsScreen hides DemoModeBanner and filters opposite gender profiles', (WidgetTester tester) async {
      // 1. Male user should see Female profiles (Ananya Reddy) and NOT Male profiles (Aman Gupta)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _GenderAuthNotifier('Male')),
          ],
          child: const MaterialApp(
            home: DiscoverFriendsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('DEMO MODE'), findsNothing);
      expect(find.text('Ananya Reddy, 26'), findsOneWidget);

      await tester.tap(find.text('Pass'));
      await tester.pump();
      expect(find.text('Aman Gupta, 27'), findsNothing);
      expect(find.text('Priya Nair, 25'), findsOneWidget);

      // 2. Female user should see Male profiles (Aman Gupta) and NOT Female profiles (Ananya Reddy)
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('female-scope'),
          overrides: [
            authProvider.overrideWith((ref) => _GenderAuthNotifier('Female')),
          ],
          child: const MaterialApp(
            home: DiscoverFriendsScreen(key: ValueKey('female-view')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Ananya Reddy, 26'), findsNothing);
      expect(find.text('Aman Gupta, 27'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 35));
    });

    testWidgets('ProfileScreen back button uses safePop without GoError when nothing to pop', (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const Scaffold(body: Text('Home Target'))),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Home Target'), findsOneWidget);
      await tester.pump(const Duration(seconds: 35));
    });

    test('ApiEndpoints.isValidUuid skips non-UUID demo IDs like user-ananya', () {
      expect(ApiEndpoints.isValidUuid('user-ananya'), isFalse);
      expect(ApiEndpoints.isValidUuid('room-1'), isFalse);
      expect(ApiEndpoints.isValidUuid('11111111-1111-1111-1111-111111111111'), isTrue);
    });
  });
}

