import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/chats_inbox_provider.dart';
import 'discover_friends_screen.dart';
import '../reels/reels_screen.dart';
import '../rooms/live_rooms_screen.dart';
import '../chats/chats_inbox_screen.dart';
import '../profile/profile_screen.dart';

final activeShellTabProvider = StateProvider<int>((ref) => 0);

class MainShellScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final unreadChats = ref.watch(totalUnreadChatsCountProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DiscoverFriendsScreen(),
          ReelsScreen(),
          LiveRoomsScreen(),
          ChatsInboxScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: FriendLoopColors.border, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            ref.read(activeShellTabProvider.notifier).state = index;
          },
          backgroundColor: Colors.white,
          selectedItemColor: FriendLoopColors.violet,
          unselectedItemColor: FriendLoopColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.movie_outlined),
              activeIcon: Icon(Icons.movie_rounded),
              label: 'Reels',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups_rounded),
              label: 'Rooms',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: unreadChats > 0,
                backgroundColor: FriendLoopColors.violet,
                label: Text(
                  '$unreadChats',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded),
              ),
              activeIcon: Badge(
                isLabelVisible: unreadChats > 0,
                backgroundColor: FriendLoopColors.violet,
                label: Text(
                  '$unreadChats',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                child: const Icon(Icons.chat_bubble_rounded),
              ),
              label: 'Chats',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
