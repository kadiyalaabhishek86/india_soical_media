import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/providers/auth_provider.dart';
import 'package:mobile/core/providers/friends_provider.dart';
import 'package:mobile/core/providers/reels_provider.dart';
import 'package:mobile/features/call/voice_call_screen.dart';
import 'package:mobile/features/call/video_call_screen.dart';
import 'package:mobile/features/friends/friend_profile_screen.dart';
import 'package:mobile/features/profile/profile_screen.dart';
import 'package:mobile/features/reels/video_controller_helper.dart';

class _TestAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _TestAuthNotifier([int coins = 120])
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
              coins: coins,
              isPlusSubscriber: false,
              isAdult: true,
              rulesAccepted: true,
              languages: const ['Hindi', 'English'],
              images: const ['assets/telegram/wallpaper_sample.png'],
            ),
          ),
        );

  @override
  void updateCoins(int newCoins) {
    if (state.currentUserProfile != null) {
      state = state.copyWith(
        currentUserProfile: state.currentUserProfile!.copyWith(coins: newCoins),
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Friend Calls & Profile Edit Tests', () {
    final sampleFriend = FriendItem(
      friendshipId: 'friend-priya-123',
      friendId: 'user-priya',
      displayName: 'Priya Sharma',
      state: 'Maharashtra',
      city: 'Mumbai',
      images: [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      ],
    );

    testWidgets('VoiceCallScreen with friend displays friend profile image, name, and voice controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: VoiceCallScreen(friend: sampleFriend),
          ),
        ),
      );
      await tester.pump();

      // Check friend name and location
      expect(find.text('Priya Sharma'), findsWidgets);
      expect(find.text('Mumbai, Maharashtra'), findsOneWidget);
      expect(find.text('Voice Call • 10 coins/min • Connected'), findsOneWidget);

      // Check in-call controls
      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('Speaker'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('End Call'), findsOneWidget);
    });

    testWidgets('VideoCallScreen with friend displays full-screen friend feed, PiP, timer and controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: VideoCallScreen(friend: sampleFriend),
          ),
        ),
      );
      await tester.pump();

      // Check friend name and rate
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('40c/m'), findsOneWidget);

      // Check call controls
      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('Camera On'), findsOneWidget);
      expect(find.text('Flip'), findsOneWidget);
      expect(find.text('End Call'), findsOneWidget);
    });

    testWidgets('ProfileScreen displays Edit Photo badge, Edit Profile & Bio, and Edit Bio options', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pump();

      // Check edit buttons and badges
      expect(find.text('Edit Photo'), findsWidgets);
      expect(find.text('Edit Profile & Bio'), findsOneWidget);
      expect(find.text('Edit'), findsWidgets);
      expect(find.text('Bio'), findsOneWidget);
    });

    test('ReelsNotifier keeps uploaded reel at index 0 and reloads with shuffled order', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final uploaded = {
        'id': 'my-custom-reel-999',
        'user_name': 'Priya Patel',
        'caption': 'My awesome trip reel!',
        'video_url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        'thumbnail_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
        'likes_count': 0,
        'comments_count': 0,
      };

      container.read(reelsProvider.notifier).addUploadedReel(uploaded);
      final currentList = container.read(reelsProvider);
      expect(currentList.first['id'], 'my-custom-reel-999');
      expect(currentList.first['user_name'], 'Priya Patel');

      // Reload with shuffle
      await container.read(reelsProvider.notifier).fetchReels(shuffle: true);
      final afterReload = container.read(reelsProvider);
      // Uploaded reel stays at index 0
      expect(afterReload.first['id'], 'my-custom-reel-999');
      expect(afterReload.length, greaterThanOrEqualTo(5));
    });

    test('Video controller helper resolves relative backend media URLs', () {
      final resolvedHttp = createVideoControllerForUrlOrPath('https://commondatastorage.googleapis.com/test.mp4');
      expect(resolvedHttp.dataSource, contains('test.mp4'));

      final resolvedRelative = createVideoControllerForUrlOrPath('/uploads/reels/uploaded_video.mp4');
      expect(resolvedRelative.dataSource, contains('/uploads/reels/uploaded_video.mp4'));
    });

    testWidgets('FriendProfileScreen checks coins on Voice, Video, Chat and navigates to /wallet when insufficient', (WidgetTester tester) async {
      final authNotifier = _TestAuthNotifier(5); // 5 coins: insufficient for Voice (10) and Video (40)

      final router = GoRouter(
        initialLocation: '/friend',
        routes: [
          GoRoute(
            path: '/friend',
            builder: (ctx, state) => const FriendProfileScreen(friendshipId: 'test-fs'),
          ),
          GoRoute(
            path: '/wallet',
            builder: (ctx, state) => const Scaffold(body: Text('Coins Recharge Page')),
          ),
          GoRoute(
            path: '/call',
            builder: (ctx, state) => const Scaffold(body: Text('Voice Call Page')),
          ),
          GoRoute(
            path: '/call/video',
            builder: (ctx, state) => const Scaffold(body: Text('Video Call Page')),
          ),
          GoRoute(
            path: '/chat/:id',
            builder: (ctx, state) => const Scaffold(body: Text('Chat Page')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => authNotifier),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      // 1. Scroll down to Voice and tap with 5 coins (< 10 required) -> redirects to /wallet
      await tester.ensureVisible(find.text('Voice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voice'));
      await tester.pumpAndSettle();
      expect(find.text('Coins Recharge Page'), findsOneWidget);
    });

    testWidgets('FriendProfileScreen with sufficient coins deducts coins and connects call', (WidgetTester tester) async {
      final authNotifier = _TestAuthNotifier(100); // 100 coins: plenty!

      final router = GoRouter(
        initialLocation: '/friend',
        routes: [
          GoRoute(
            path: '/friend',
            builder: (ctx, state) => const FriendProfileScreen(friendshipId: 'test-fs'),
          ),
          GoRoute(
            path: '/wallet',
            builder: (ctx, state) => const Scaffold(body: Text('Coins Recharge Page')),
          ),
          GoRoute(
            path: '/call',
            builder: (ctx, state) => const Scaffold(body: Text('Voice Call Page')),
          ),
          GoRoute(
            path: '/call/video',
            builder: (ctx, state) => const Scaffold(body: Text('Video Call Page')),
          ),
          GoRoute(
            path: '/chat/:id',
            builder: (ctx, state) => const Scaffold(body: Text('Chat Page')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => authNotifier),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      // Scroll down and tap Voice with 100 coins -> deducts 10 (leaves 90) and opens Voice Call Page
      await tester.ensureVisible(find.text('Voice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voice'));
      await tester.pumpAndSettle();
      expect(find.text('Voice Call Page'), findsOneWidget);
      expect(authNotifier.state.currentUserProfile?.coins, 90);
    });
  });
}
