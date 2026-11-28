import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/reels/reels_screen.dart';
import 'package:mobile/core/providers/reels_provider.dart';

final List<Map<String, dynamic>> testSeedReels = [
  {
    'id': '11111111-aaaa-bbbb-cccc-111111111111',
    'user_name': 'Priya Patel',
    'user_avatar': null,
    'video_url': 'assets/sample.mp4',
    'thumbnail_url': 'assets/telegram/wallpaper_sample.png',
    'caption': 'Friendship trips hit different! 💜',
    'likes_count': 3401,
    'comments_count': 287,
    'is_liked': false,
  },
  {
    'id': '22222222-aaaa-bbbb-cccc-222222222222',
    'user_name': 'Rohit Verma',
    'user_avatar': null,
    'video_url': 'assets/sample2.mp4',
    'thumbnail_url': 'assets/telegram/wallpaper_sample.png',
    'caption': 'Weekend trek with friends! ⛰️',
    'likes_count': 1820,
    'comments_count': 94,
    'is_liked': false,
  },
];

class MockReelsNotifier extends StateNotifier<List<Map<String, dynamic>>> implements ReelsNotifier {
  MockReelsNotifier([List<Map<String, dynamic>>? initial]) : super(initial ?? testSeedReels);

  @override
  void addUploadedReel(Map<String, dynamic> reel) {
    state = [reel, ...state];
  }

  @override
  Future<void> fetchReels({String feed = 'discover', bool shuffle = false}) async {}

  @override
  Future<void> toggleLike(String reelId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Reels Playback & Smooth Scroll Tests', () {
    testWidgets('Reels screen renders feed, tabs, and snap scroll PageView', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reelsProvider.overrideWith((ref) => MockReelsNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ReelsScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify header tabs (Discover & Friends Reels, no refresh or notification buttons)
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Friends Reels'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsNothing);
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);

      // Verify initial reel content
      expect(find.text('Priya Patel'), findsOneWidget);
      expect(find.text('Friendship trips hit different! 💜'), findsOneWidget);

      // Verify PageView exists with vertical scroll and page snapping physics
      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);

      final PageView pageView = tester.widget(pageViewFinder);
      expect(pageView.scrollDirection, Axis.vertical);
      expect(pageView.physics, isA<PageScrollPhysics>());
    });

    testWidgets('Vertical swipe scrolls to next reel smoothly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reelsProvider.overrideWith((ref) => MockReelsNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ReelsScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Priya Patel'), findsOneWidget);

      // Swipe up vertically to advance to the next reel
      await tester.drag(find.byType(PageView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Second reel should now be visible
      expect(find.text('Rohit Verma'), findsOneWidget);
      expect(find.text('Weekend trek with friends! ⛰️'), findsOneWidget);
    });

    testWidgets('Upload Reel button renders on screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reelsProvider.overrideWith((ref) => MockReelsNotifier()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ReelsScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      final uploadButton = find.text('Upload\nReel');
      expect(uploadButton, findsOneWidget);
    });

    testWidgets('Adding newly uploaded reel places it at the very top of feed', (WidgetTester tester) async {
      final mockNotifier = MockReelsNotifier();
      final newReel = {
        'id': 'my-custom-test-reel-999',
        'user_name': 'My Uploaded Star',
        'caption': 'Check out my brand new live reel! 🚀',
        'video_url': 'assets/sample.mp4',
        'thumbnail_url': 'assets/telegram/wallpaper_sample.png',
        'likes_count': 0,
        'comments_count': 0,
        'is_liked': false,
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reelsProvider.overrideWith((ref) => mockNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ReelsScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Add uploaded reel
      mockNotifier.addUploadedReel(newReel);
      await tester.pumpAndSettle();

      // The new reel should now be at the very top and immediately visible!
      expect(find.text('My Uploaded Star'), findsOneWidget);
      expect(find.text('Check out my brand new live reel! 🚀'), findsOneWidget);
    });
  });
}
