import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app.dart';
import 'package:mobile/features/chats/chats_inbox_screen.dart';
import 'package:mobile/features/friends/private_chat_screen.dart';
import 'package:mobile/features/friends/friend_profile_screen.dart';
import 'package:mobile/features/home/discover_friends_screen.dart';
import 'package:mobile/features/call/recent_calls_screen.dart';

import 'package:mobile/core/providers/chat_provider.dart';

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

    await tester.pump(const Duration(seconds: 15));
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

    await tester.pump(const Duration(seconds: 15));
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

    await tester.pump(const Duration(seconds: 15));
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

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('Discover Friends Screen renders All Cities and Enter City/Language fields', (WidgetTester tester) async {
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
    expect(find.text('All Cities'), findsOneWidget);
    expect(find.text('All Languages'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.pump(const Duration(seconds: 15));
  });
}
