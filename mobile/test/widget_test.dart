import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app.dart';
import 'package:mobile/features/chats/chats_inbox_screen.dart';
import 'package:mobile/features/friends/private_chat_screen.dart';
import 'package:mobile/features/friends/friend_profile_screen.dart';
import 'package:mobile/features/friends/friends_list_screen.dart';
import 'package:mobile/features/home/discover_friends_screen.dart';
import 'package:mobile/features/match/random_connect_screen.dart';
import 'package:mobile/features/call/recent_calls_screen.dart';
import 'package:mobile/features/wallet/wallet_screen.dart';
import 'package:mobile/features/reels/create_reel_screen.dart';

import 'package:mobile/core/providers/chat_provider.dart';
import 'package:mobile/core/providers/match_provider.dart';

class _NoOpHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

class TestChatNotifier extends StateNotifier<ChatState> implements ChatNotifier {
  TestChatNotifier() : super(ChatState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestMatchNotifier extends StateNotifier<MatchState> implements MatchNotifier {
  TestMatchNotifier() : super(MatchState());

  @override
  Future<void> joinQueue({String callMode = 'voice', bool allowAnyLanguage = false}) async {}

  @override
  Future<void> cancelQueue() async {}

  @override
  Future<void> broadenLanguages() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _NoOpHttpOverrides();
  });

  testWidgets('FriendLoop Welcome Screen renders with Welcome and Phone Login', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FriendLoopApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Make real friends\nacross India'), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('India +91'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Admin Sign In'), findsOneWidget);
  });

  testWidgets('Chats Inbox Screen renders contacts and quick actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ChatsInboxScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);
    expect(find.text('Random Connect'), findsOneWidget);
    expect(find.text('Recent Calls'), findsOneWidget);
    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text('Rohan Verma'), findsOneWidget);
    expect(find.text('Sneha Iyer'), findsOneWidget);

    await tester.pump(const Duration(seconds: 35));
  });

  testWidgets('One-to-One Private Chat renders FriendLoop bubbles and coin banner', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatProviderFamily('chat-priya-sharma').overrideWith((ref) => TestChatNotifier()),
        ],
        child: const MaterialApp(
          home: PrivateChatScreen(friendshipId: 'chat-priya-sharma'),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Calls use coins from your balance.'), findsOneWidget);
    expect(find.text('Hey! Are you free today?'), findsOneWidget);
    expect(find.text('Yes! Want to have a quick call?'), findsOneWidget);
    expect(find.text('Sure! Video call?'), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
    expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);

    await tester.pump(const Duration(seconds: 35));
  });

  testWidgets('Recent Calls Screen renders tabs and call log entries', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RecentCallsScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Recent Calls'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Incoming'), findsOneWidget);
    expect(find.text('Outgoing'), findsOneWidget);
    expect(find.text('Missed'), findsOneWidget);
    expect(find.text('Rohan Verma'), findsOneWidget);
    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text('Sneha Iyer'), findsOneWidget);

    await tester.pump(const Duration(seconds: 35));
  });

  testWidgets('User Profile Screen renders FriendLoop card, Bio, Looking for, Add Friend and actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FriendProfileScreen(
            friendshipId: 'test-friendship-id',
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('User Profile'), findsOneWidget);
    expect(find.text('Ananya Reddy'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Bio'), findsOneWidget);
    expect(find.text('Looking for'), findsOneWidget);
    expect(find.text('+ Add Friend'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);

    await tester.pump(const Duration(seconds: 35));
  });

  testWidgets('Discover Friends Screen renders Filters button and opens filter sheet', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DiscoverFriendsScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Discover Friends'), findsOneWidget);
    expect(find.text('Find and connect with friendly people across India'), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);

    // Open filter bottom sheet to verify filter options
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();

    expect(find.text('Filter Profiles'), findsOneWidget);
    expect(find.text('All Cities'), findsOneWidget);
    expect(find.text('All Languages'), findsOneWidget);

    await tester.pump(const Duration(seconds: 35));
  });

  testWidgets('Random Connect Screen renders modes and toggles to Searching view', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchProvider.overrideWith((ref) => TestMatchNotifier()),
        ],
        child: const MaterialApp(
          home: RandomConnectScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Random Connect'), findsOneWidget);
    expect(find.text('Meet a new friend across India'), findsOneWidget);
    expect(find.text('Online now'), findsOneWidget);
    expect(find.text('Voice Call'), findsOneWidget);
    expect(find.text('Video Call'), findsOneWidget);
    expect(find.text('Text Chat'), findsOneWidget);
    expect(find.text('Find a voice match'), findsOneWidget);
    expect(find.text('Any language'), findsOneWidget);

    // Tap Find a voice match to enter searching view
    await tester.tap(find.text('Find a voice match'));
    await tester.pump();

    expect(find.text('Finding a friend...'), findsOneWidget);
    expect(find.text('Looking for someone to talk with'), findsOneWidget);
    expect(find.text('Cancel search'), findsOneWidget);

    // Cancel search
    await tester.tap(find.text('Cancel search'));
    await tester.pump();

    expect(find.text('Random Connect'), findsOneWidget);

    await tester.pump(const Duration(seconds: 35));
  });

  testWidgets('Friends List Screen renders Friends title, Priya, Rahul, Neha, Vikram and actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FriendsListScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Friends'), findsOneWidget);
    expect(find.text('Priya'), findsOneWidget);
    expect(find.text('Rahul'), findsOneWidget);
    expect(find.text('Neha'), findsOneWidget);
    expect(find.text('Vikram'), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsWidgets);
    expect(find.byIcon(Icons.videocam_outlined), findsWidgets);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsWidgets);

    await tester.pump(const Duration(seconds: 35));
  });

  testWidgets('Coin Wallet Screen renders balance, packs and expands on Show more / Show less', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WalletScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Coin Wallet'), findsOneWidget);
    expect(find.text('Available balance'), findsOneWidget);
    expect(find.text('Buy Coins'), findsOneWidget);
    expect(find.text('Show more'), findsOneWidget);
    expect(find.text('40 coins'), findsOneWidget);

    // Tap Show more
    await tester.tap(find.text('Show more'));
    await tester.pump();

    expect(find.text('Show less'), findsOneWidget);
    expect(find.text('3,300 coins'), findsOneWidget);
    expect(find.text('Best value'), findsOneWidget);

    // Scroll to Show less and tap to collapse back
    await tester.ensureVisible(find.text('Show less'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();

    expect(find.text('Show more'), findsOneWidget);

    await tester.pump(const Duration(seconds: 35));
  });

  testWidgets('Create Reel Screen renders gallery upload option, sample presets, and caption field', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CreateReelScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Upload Reel'), findsOneWidget);
    expect(find.text('Upload Video from Gallery'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
    expect(find.text('Or test with a sample reel:'), findsOneWidget);
    expect(find.text('Mountain Trek'), findsOneWidget);
    expect(find.text('Sunset Vibes'), findsOneWidget);
    expect(find.text('Bengaluru Chai'), findsOneWidget);
    expect(find.text('Cover Photo (Optional)'), findsOneWidget);
    expect(find.text('Choose cover from gallery'), findsOneWidget);
    expect(find.text('Caption'), findsOneWidget);
    expect(find.text('#friends'), findsOneWidget);

    await tester.pump(const Duration(seconds: 35));
  });
}
