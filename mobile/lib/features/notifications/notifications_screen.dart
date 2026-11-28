import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/chats_inbox_provider.dart';
import '../../core/providers/recent_calls_provider.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/providers/notifications_provider.dart';
import '../../core/utils/nav_helper.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _selectedFilter = 0; // 0 = All, 1 = Messages, 2 = Likes, 3 = Rooms & Games, 4 = Missed Calls

  @override
  Widget build(BuildContext context) {
    final chats = ref.watch(chatsInboxProvider);
    final calls = ref.watch(recentCallsProvider);
    final eventNotifs = ref.watch(notificationsProvider);

    final unreadChats = chats.where((c) => c.unread > 0).toList();
    final missedCalls = calls.where((c) => c.type == 'missed').toList();

    final List<Map<String, dynamic>> items = [];

    if (_selectedFilter == 0 || _selectedFilter == 1) {
      for (final chat in unreadChats) {
        items.add({
          'kind': 'message',
          'title': '${chat.displayName} sent ${chat.unread} unread message${chat.unread > 1 ? 's' : ''}',
          'subtitle': chat.lastMessage,
          'time': chat.time,
          'avatar': chat.avatar,
          'badge': '${chat.unread}',
          'chat': chat,
        });
      }
    }

    if (_selectedFilter == 0 || _selectedFilter == 2) {
      for (final ev in eventNotifs.where((e) => e.category == 'like')) {
        items.add({
          'kind': 'like',
          'title': ev.title,
          'subtitle': ev.subtitle,
          'time': ev.time,
          'avatar': ev.avatar ?? '',
          'isUnread': !ev.isRead,
          'event': ev,
        });
      }
    }

    if (_selectedFilter == 0 || _selectedFilter == 3) {
      for (final ev in eventNotifs.where((e) => e.category == 'room' || e.category == 'game')) {
        items.add({
          'kind': ev.category,
          'title': ev.title,
          'subtitle': ev.subtitle,
          'time': ev.time,
          'avatar': ev.avatar ?? '',
          'isUnread': !ev.isRead,
          'friendsOnly': ev.friendsOnly,
          'event': ev,
        });
      }
    }

    if (_selectedFilter == 0 || _selectedFilter == 4) {
      for (final call in missedCalls) {
        items.add({
          'kind': 'missed_call',
          'title': 'Missed ${call.mode} call from ${call.name}',
          'subtitle': call.isSeen ? 'Tap to view recent calls' : 'New missed call • Tap to call back',
          'time': call.time,
          'avatar': call.avatar,
          'isUnread': !call.isSeen,
          'call': call,
        });
      }
    }

    return Scaffold(
      backgroundColor: FriendLoopColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
          onPressed: () => safePop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: FriendLoopColors.plum),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              ref.read(chatsInboxProvider.notifier).markAllAsRead();
              ref.read(recentCallsProvider.notifier).markMissedCallsSeen();
              ref.read(notificationsProvider.notifier).markAllRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read!'),
                  backgroundColor: FriendLoopColors.success,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text(
              'Mark Read',
              style: TextStyle(color: FriendLoopColors.violet, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterTab('All', 0),
                  const SizedBox(width: 8),
                  _buildFilterTab('Messages', 1),
                  const SizedBox(width: 8),
                  _buildFilterTab('Likes', 2),
                  const SizedBox(width: 8),
                  _buildFilterTab('Rooms & Games', 3),
                  const SizedBox(width: 8),
                  _buildFilterTab('Missed Calls', 4),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_rounded, size: 54, color: FriendLoopColors.violet),
                          SizedBox(height: 10),
                          Text(
                            'You are all caught up!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FriendLoopColors.plum),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'No unread messages, likes, friend rooms, or missed calls.',
                            style: TextStyle(fontSize: 13, color: FriendLoopColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 64, color: FriendLoopColors.border),
                      itemBuilder: (ctx, idx) {
                        final item = items[idx];
                        final kind = item['kind'] as String;
                        final isMsg = kind == 'message';
                        final isMissed = kind == 'missed_call';
                        final isLike = kind == 'like';
                        final isRoomOrGame = kind == 'room' || kind == 'game';
                        final avatar = item['avatar'] as String? ?? '';

                        final badgeColor = isMissed
                            ? FriendLoopColors.rose
                            : (isLike ? Colors.pink : FriendLoopColors.violet);
                        final badgeIcon = isMissed
                            ? Icons.call_missed
                            : (isLike
                                ? Icons.favorite
                                : (isRoomOrGame ? Icons.sports_esports : Icons.mark_chat_unread));

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          leading: Stack(
                            children: [
                              ClipOval(
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: avatar.isNotEmpty
                                      ? Image.network(
                                          avatar,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: FriendLoopColors.lavender,
                                            child: Icon(badgeIcon, color: badgeColor),
                                          ),
                                        )
                                      : Container(
                                          color: FriendLoopColors.lavender,
                                          child: Icon(badgeIcon, color: badgeColor),
                                        ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: Icon(badgeIcon, size: 10, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['title'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isMissed ? FriendLoopColors.rose : FriendLoopColors.plum,
                                  ),
                                ),
                              ),
                              if (item['friendsOnly'] == true)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: FriendLoopColors.lavender,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Friends',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: FriendLoopColors.violet),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${item['subtitle']} • ${item['time']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: FriendLoopColors.textSecondary),
                          ),
                          trailing: isMsg
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: const BoxDecoration(
                                    color: FriendLoopColors.violet,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    item['badge'] as String,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                )
                              : const Icon(Icons.chevron_right, color: FriendLoopColors.textMuted),
                          onTap: () {
                            if (isMsg) {
                              final chat = item['chat'] as ChatConversation;
                              ref.read(chatsInboxProvider.notifier).markAsRead(chat.id, chat.displayName);
                              final friend = chat.friendItem ??
                                  FriendItem(
                                    friendshipId: chat.id,
                                    friendId: chat.id,
                                    displayName: chat.displayName,
                                    state: 'India',
                                    images: [chat.avatar],
                                  );
                              context.push('/chat/${friend.friendshipId}', extra: friend);
                            } else if (isMissed) {
                              ref.read(recentCallsProvider.notifier).markMissedCallsSeen();
                              context.push('/recent-calls');
                            } else {
                              final ev = item['event'] as AppNotificationItem;
                              ref.read(notificationsProvider.notifier).markRead(ev.id);
                              if (ev.routePath != null) {
                                context.push(ev.routePath!, extra: ev.routeExtra);
                              }
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, int index) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? FriendLoopColors.violet : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? FriendLoopColors.violet : FriendLoopColors.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
            color: isSelected ? Colors.white : FriendLoopColors.plum,
          ),
        ),
      ),
    );
  }
}
