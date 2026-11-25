import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/providers/chats_inbox_provider.dart';

class ChatsInboxScreen extends ConsumerStatefulWidget {
  const ChatsInboxScreen({super.key});

  @override
  ConsumerState<ChatsInboxScreen> createState() => _ChatsInboxScreenState();
}

class _ChatsInboxScreenState extends ConsumerState<ChatsInboxScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsState = ref.watch(friendsProvider);
    final friends = friendsState.friends;

    // Sync friends into shared inbox state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(chatsInboxProvider.notifier).syncWithFriends(friends);
      }
    });

    final allChats = ref.watch(chatsInboxProvider);

    final filtered = allChats.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: FriendLoopColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/images/friendloop_logo.png',
          height: 28,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.all_inclusive_rounded,
            size: 28,
            color: FriendLoopColors.violet,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: FriendLoopColors.violet),
            tooltip: 'Mark all as read',
            onPressed: () {
              ref.read(chatsInboxProvider.notifier).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All messages marked as read! ✓'),
                  backgroundColor: FriendLoopColors.success,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: FriendLoopColors.plum),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Title: Chats
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Text(
                'Chats',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  color: FriendLoopColors.plum,
                ),
              ),
            ),

            // Quick Action Shortcuts: Friends, Random Connect, Recent Calls (matching mockup)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  _buildQuickAction(
                    icon: Icons.people_alt_outlined,
                    label: 'Friends',
                    onTap: () => context.push('/friends'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    icon: Icons.shuffle_rounded,
                    label: 'Random Connect',
                    onTap: () => context.push('/random-connect'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAction(
                    icon: Icons.phone_outlined,
                    label: 'Recent Calls',
                    onTap: () => context.push('/recent-calls'),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: FriendLoopColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search chats',
                    hintStyle: TextStyle(color: FriendLoopColors.textMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: FriendLoopColors.textMuted, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Chats List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 64, color: FriendLoopColors.border),
                itemBuilder: (ctx, idx) {
                  final chat = filtered[idx];
                  final friend = chat.friendItem ??
                      FriendItem(
                        friendshipId: chat.id,
                        friendId: chat.id,
                        displayName: chat.displayName,
                        state: 'Karnataka',
                        city: 'Bengaluru',
                        age: 24,
                        languages: const ['Hindi', 'English'],
                        lookingFor: 'Conversations & friendship',
                        images: [chat.avatar],
                        lastMessage: chat.lastMessage,
                      );

                  final unread = chat.unread;
                  final isOnline = chat.isOnline;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    onTap: () async {
                      // 1. Clear unread message alert immediately upon opening
                      ref.read(chatsInboxProvider.notifier).markAsRead(chat.id, chat.displayName);

                      await context.push(
                        '/chat/${friend.friendshipId}',
                        extra: friend,
                      );

                      // 2. Ensure unread count remains cleared upon returning to inbox
                      if (mounted) {
                        ref.read(chatsInboxProvider.notifier).markAsRead(chat.id, chat.displayName);
                      }
                    },
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(chat.avatar),
                          onBackgroundImageError: (_, __) {},
                          child: const Icon(Icons.person, color: FriendLoopColors.plum),
                        ),
                        if (isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: FriendLoopColors.onlineGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      chat.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: FriendLoopColors.plum),
                    ),
                    subtitle: Text(
                      chat.lastMessage,
                      style: const TextStyle(fontSize: 13, color: FriendLoopColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          chat.time,
                          style: const TextStyle(fontSize: 11, color: FriendLoopColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        if (unread > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: const BoxDecoration(
                              color: FriendLoopColors.violet,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          const SizedBox(height: 18),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: FriendLoopColors.lavender.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FriendLoopColors.lavender),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: FriendLoopColors.violet),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: FriendLoopColors.plum,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
