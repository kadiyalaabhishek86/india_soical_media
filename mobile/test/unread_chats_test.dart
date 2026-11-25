import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/providers/chats_inbox_provider.dart';
import 'package:mobile/features/chats/chats_inbox_screen.dart';

void main() {
  group('Chats Inbox & Unread Message Alert Tests', () {
    test('ChatsInboxNotifier correctly manages unread alerts and marks them as read', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 1. Initial State: Priya Sharma has 3, Rohan Verma has 1, Sneha has 0. Total = 4.
      final initialConversations = container.read(chatsInboxProvider);
      expect(initialConversations.length, 3);
      final priya = initialConversations.firstWhere((c) => c.displayName == 'Priya Sharma');
      final rohan = initialConversations.firstWhere((c) => c.displayName == 'Rohan Verma');
      expect(priya.unread, 3);
      expect(rohan.unread, 1);
      expect(container.read(totalUnreadChatsCountProvider), 4);

      // 2. Mark Priya Sharma as read (opening her chat)
      container.read(chatsInboxProvider.notifier).markAsRead('chat-priya-sharma', 'Priya Sharma');
      final afterPriyaRead = container.read(chatsInboxProvider);
      final priyaAfter = afterPriyaRead.firstWhere((c) => c.displayName == 'Priya Sharma');
      expect(priyaAfter.unread, 0); // Alert is now GONE!
      expect(container.read(totalUnreadChatsCountProvider), 1);

      // 3. Mark Rohan Verma as read (opening his chat)
      container.read(chatsInboxProvider.notifier).markAsRead('chat-rohan-verma', 'Rohan Verma');
      final afterRohanRead = container.read(chatsInboxProvider);
      final rohanAfter = afterRohanRead.firstWhere((c) => c.displayName == 'Rohan Verma');
      expect(rohanAfter.unread, 0); // Alert is now GONE!
      expect(container.read(totalUnreadChatsCountProvider), 0); // All unread cleared!
    });

    test('markAllAsRead clears all unread message alerts at once', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(totalUnreadChatsCountProvider), 4);
      container.read(chatsInboxProvider.notifier).markAllAsRead();

      expect(container.read(totalUnreadChatsCountProvider), 0);
      final convos = container.read(chatsInboxProvider);
      for (final c in convos) {
        expect(c.unread, 0);
      }
    });

    testWidgets('ChatsInboxScreen displays unread badges and removes them on mark read / tap', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ChatsInboxScreen(),
          ),
        ),
      );
      await tester.pump();

      // Initially badges '3' and '1' are present
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Mark Priya Sharma as read
      container.read(chatsInboxProvider.notifier).markAsRead('chat-priya-sharma', 'Priya Sharma');
      await tester.pump();

      // Badge '3' must be gone!
      expect(find.text('3'), findsNothing);
      expect(find.text('1'), findsOneWidget);

      // Tap Mark all as read icon
      await tester.tap(find.byIcon(Icons.done_all_rounded));
      await tester.pump();

      // Badge '1' must also be gone!
      expect(find.text('1'), findsNothing);

      await tester.pump(const Duration(seconds: 2));
    });
  });
}
