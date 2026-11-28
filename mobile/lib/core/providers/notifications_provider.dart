import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chats_inbox_provider.dart';
import 'recent_calls_provider.dart';

class AppNotificationItem {
  final String id;
  final String category; // 'like', 'room', 'game'
  final String title;
  final String subtitle;
  final String time;
  final String? avatar;
  final String? routePath;
  final Object? routeExtra;
  final bool isRead;
  final bool friendsOnly;

  const AppNotificationItem({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.time,
    this.avatar,
    this.routePath,
    this.routeExtra,
    this.isRead = false,
    this.friendsOnly = false,
  });

  AppNotificationItem copyWith({bool? isRead}) {
    return AppNotificationItem(
      id: id,
      category: category,
      title: title,
      subtitle: subtitle,
      time: time,
      avatar: avatar,
      routePath: routePath,
      routeExtra: routeExtra,
      isRead: isRead ?? this.isRead,
      friendsOnly: friendsOnly,
    );
  }
}

class NotificationsNotifier extends StateNotifier<List<AppNotificationItem>> {
  NotificationsNotifier() : super(_initialEvents);

  static const List<AppNotificationItem> _initialEvents = [
    AppNotificationItem(
      id: 'notif-like-1',
      category: 'like',
      title: 'Ananya Reddy liked your profile 💜',
      subtitle: 'Someone nearby liked your profile on Discover',
      time: '12 min ago',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      isRead: false,
    ),
    AppNotificationItem(
      id: 'notif-room-1',
      category: 'game',
      title: 'Priya started Ludo 2v2 Party 🎲',
      subtitle: 'Friends-only game invite • Join now to play together',
      time: '18 min ago',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      routePath: '/rooms',
      isRead: false,
      friendsOnly: true,
    ),
  ];

  void addProfileLike({
    required String fromName,
    String? avatar,
    bool isStranger = true,
  }) {
    final item = AppNotificationItem(
      id: 'notif-like-${DateTime.now().millisecondsSinceEpoch}',
      category: 'like',
      title: '$fromName liked your profile 💜',
      subtitle: isStranger ? 'New profile like from Discover' : 'Your friend liked your profile',
      time: 'Just now',
      avatar: avatar,
      isRead: false,
    );
    state = [item, ...state];
  }

  void addFriendRoomOrGameNotification({
    required String friendName,
    required String roomTitle,
    required String roomId,
    required bool isGame,
    Map<String, dynamic>? roomData,
  }) {
    final item = AppNotificationItem(
      id: 'notif-room-${DateTime.now().millisecondsSinceEpoch}',
      category: isGame ? 'game' : 'room',
      title: isGame
          ? '$friendName is playing in "$roomTitle" 🎮'
          : '$friendName created room "$roomTitle" 🎙️',
      subtitle: 'Friends notification • Tap to join or watch',
      time: 'Just now',
      routePath: '/room/$roomId',
      routeExtra: roomData,
      isRead: false,
      friendsOnly: true,
    );
    state = [item, ...state];
  }

  void markRead(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
  }

  void markAllRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<AppNotificationItem>>((ref) {
  return NotificationsNotifier();
});

final totalNotificationsBadgeProvider = Provider<int>((ref) {
  final unreadChats = ref.watch(totalUnreadChatsCountProvider);
  final missedCalls = ref.watch(unreadMissedCallsCountProvider);
  final eventNotifs = ref.watch(notificationsProvider).where((n) => !n.isRead).length;
  return unreadChats + missedCalls + eventNotifs;
});

