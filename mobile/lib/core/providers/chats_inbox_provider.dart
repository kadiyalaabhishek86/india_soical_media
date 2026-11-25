import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'friends_provider.dart';

class ChatConversation {
  final String id;
  final String displayName;
  final String avatar;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isOnline;
  final FriendItem? friendItem;

  const ChatConversation({
    required this.id,
    required this.displayName,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    this.isOnline = true,
    this.friendItem,
  });

  ChatConversation copyWith({
    String? id,
    String? displayName,
    String? avatar,
    String? lastMessage,
    String? time,
    int? unread,
    bool? isOnline,
    FriendItem? friendItem,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      unread: unread ?? this.unread,
      isOnline: isOnline ?? this.isOnline,
      friendItem: friendItem ?? this.friendItem,
    );
  }
}

class ChatsInboxNotifier extends StateNotifier<List<ChatConversation>> {
  ChatsInboxNotifier() : super(_initialConversations);

  static const List<ChatConversation> _initialConversations = [
    ChatConversation(
      id: 'chat-priya-sharma',
      displayName: 'Priya Sharma',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      lastMessage: 'Hey! Are you free today?',
      time: '12:18 PM',
      unread: 3,
      isOnline: true,
    ),
    ChatConversation(
      id: 'chat-rohan-verma',
      displayName: 'Rohan Verma',
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
      lastMessage: "Let's catch up on a call?",
      time: '11:05 AM',
      unread: 1,
      isOnline: true,
    ),
    ChatConversation(
      id: 'chat-sneha-iyer',
      displayName: 'Sneha Iyer',
      avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
      lastMessage: 'That was fun! 😊',
      time: 'Yesterday',
      unread: 0,
      isOnline: false,
    ),
  ];

  /// Marks a specific conversation as read (clears unread badge to 0).
  void markAsRead(String id, [String? displayName]) {
    final targetId = id.toLowerCase().trim();
    final targetName = displayName?.toLowerCase().trim();

    state = state.map((c) {
      final cId = c.id.toLowerCase();
      final cName = c.displayName.toLowerCase();

      bool isMatch = (cId == targetId) ||
          (targetName != null && cName == targetName) ||
          (targetName != null && (cName.contains(targetName) || targetName.contains(cName))) ||
          cName.contains(targetId) ||
          targetId.contains(cName);

      if (isMatch && c.unread > 0) {
        return c.copyWith(unread: 0);
      }
      return c;
    }).toList();
  }

  /// Marks all conversations in the inbox as read.
  void markAllAsRead() {
    state = state.map((c) => c.unread > 0 ? c.copyWith(unread: 0) : c).toList();
  }

  /// Updates last message snippet and timestamp for a conversation.
  void updateLastMessage(String idOrName, String message, {bool isOutgoing = true}) {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = "$hour:${now.minute.toString().padLeft(2, '0')} $ampm";
    final target = idOrName.toLowerCase().trim();

    bool found = false;
    final updated = state.map((c) {
      if (c.id.toLowerCase() == target ||
          c.displayName.toLowerCase() == target ||
          c.displayName.toLowerCase().contains(target) ||
          target.contains(c.displayName.toLowerCase())) {
        found = true;
        return c.copyWith(
          lastMessage: message,
          time: timeStr,
          unread: isOutgoing ? 0 : c.unread + 1,
        );
      }
      return c;
    }).toList();

    if (found) {
      state = updated;
    }
  }

  /// Merges friends from friendsProvider into the inbox list.
  void syncWithFriends(List<FriendItem> friends) {
    final currentNames = state.map((c) => c.displayName.toLowerCase()).toSet();
    final toAdd = <ChatConversation>[];

    for (final f in friends) {
      if (!currentNames.contains(f.displayName.toLowerCase())) {
        toAdd.add(ChatConversation(
          id: f.friendshipId,
          displayName: f.displayName,
          avatar: f.images.isNotEmpty
              ? f.images.first
              : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
          lastMessage: f.lastMessage ?? 'Tap to chat with ${f.displayName}',
          time: 'Just now',
          unread: f.unreadCount,
          isOnline: true,
          friendItem: f,
        ));
      }
    }

    if (toAdd.isNotEmpty) {
      state = [...state, ...toAdd];
    }
  }
}

final chatsInboxProvider = StateNotifierProvider<ChatsInboxNotifier, List<ChatConversation>>((ref) {
  return ChatsInboxNotifier();
});

final totalUnreadChatsCountProvider = Provider<int>((ref) {
  final conversations = ref.watch(chatsInboxProvider);
  return conversations.fold<int>(0, (sum, c) => sum + c.unread);
});
