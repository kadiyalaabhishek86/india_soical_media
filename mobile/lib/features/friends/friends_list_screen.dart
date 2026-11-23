import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../shared/widgets/demo_banner.dart';

class FriendsListScreen extends ConsumerStatefulWidget {
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsState = ref.watch(friendsProvider);
    final currentUser = ref.watch(authProvider).currentUserProfile;
    final currentUserId = currentUser?.id ?? '';
    final currentUserName = (currentUser?.displayName ?? '').toLowerCase().trim();

    // Filter items: isolate per-user data (never show oneself in friends list)
    final displayedFriends = friendsState.friends.where((f) {
      if (currentUserId.isNotEmpty && f.friendId == currentUserId) return false;
      if (currentUserName.isNotEmpty && f.displayName.toLowerCase().trim() == currentUserName) return false;
      if (_searchQuery.isEmpty) return true;
      final name = f.displayName.toLowerCase();
      final msg = (f.lastMessage ?? '').toLowerCase();
      return name.contains(_searchQuery) || msg.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7), // Warm ivory
      body: SafeArea(
        child: Column(
          children: [
            const DemoModeBanner(),
            // Top Search Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Color(0xFF62586B), size: 26),
                    onPressed: () => _showSideMenu(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE8DFEB), width: 1.2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Color(0xFF62586B), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                color: Color(0xFF261D30),
                                fontSize: 15,
                              ),
                              cursorColor: const Color(0xFF6844A6),
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                hintStyle: TextStyle(
                                  color: Color(0xFF62586B),
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () => _searchController.clear(),
                              child: const Icon(Icons.close, color: Color(0xFF62586B), size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Friends / Chats list
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF6844A6),
                onRefresh: () => ref.read(friendsProvider.notifier).fetchFriends(),
                child: displayedFriends.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: displayedFriends.length,
                        itemBuilder: (context, index) {
                          final friend = displayedFriends[index];
                          return _buildChatTile(context, friend);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF6844A6), // Plum violet
        unselectedItemColor: const Color(0xFF62586B), // Muted purple-grey
        elevation: 8,
        onTap: (index) {
          if (index == 0) context.go('/match');
          if (index == 2) context.go('/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'Match'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, FriendItem friend) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          // Navigates directly to PrivateChatScreen matching Image 2
          context.push('/chat/${friend.friendshipId}', extra: friend);
        },
        onLongPress: () => _showFriendOptionsModal(context, friend),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 9.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              _buildAvatar(friend),
              const SizedBox(width: 13),

              // Title & Subtitle column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            friend.displayName,
                            style: const TextStyle(
                              color: Color(0xFF261D30), // Deep aubergine
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (friend.isMuted) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.volume_off, color: Color(0xFF8E8E93), size: 15),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Subtitle / message snippet
                    Text(
                      friend.lastMessage ?? 'No messages yet',
                      style: const TextStyle(
                        color: Color(0xFF62586B), // Muted purple-grey
                        fontSize: 13.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Trailing column: date/time & badges/pins
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date or time
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (friend.isOutgoingSent) ...[
                        const Icon(Icons.done_all, color: Color(0xFF4CAF50), size: 16),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        friend.customDate ?? _formatTime(friend.lastMessageTime),
                        style: TextStyle(
                          color: friend.isOutgoingSent ? const Color(0xFF4CAF50) : const Color(0xFF8E8E93),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Pin icon or Unread pill badge
                  if (friend.isPinned)
                    Transform.rotate(
                      angle: 0.6,
                      child: const Icon(Icons.push_pin, color: Color(0xFF8E8E93), size: 16),
                    )
                  else if (friend.badgeText != null || friend.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: friend.isMuted ? const Color(0xFFE8DFEB) : const Color(0xFF6844A6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(minWidth: 20),
                      alignment: Alignment.center,
                      child: Text(
                        friend.badgeText ?? '${friend.unreadCount}',
                        style: TextStyle(
                          color: friend.isMuted ? const Color(0xFF62586B) : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(FriendItem friend) {
    const double size = 48;

    if (friend.localAssetImage != null && friend.localAssetImage!.isNotEmpty) {
      return ClipOval(
        child: Image.asset(
          friend.localAssetImage!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackAvatar(friend, size),
        ),
      );
    }

    if (friend.images.isNotEmpty && friend.images.first.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          friend.images.first,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackAvatar(friend, size),
        ),
      );
    }

    return _fallbackAvatar(friend, size);
  }

  Widget _fallbackAvatar(FriendItem friend, double size) {
    final letter = friend.displayName.isNotEmpty ? friend.displayName[0].toUpperCase() : 'A';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF2481CC),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'Today';
    return timeStr.length > 5 ? timeStr.substring(0, 5) : timeStr;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF1F3F4),
              ),
              child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF8E8E93), size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Chats Found',
              style: TextStyle(
                color: Color(0xFF1E232A),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try searching with a different keyword.',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSideMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.flash_on, color: Color(0xFF2481CC)),
                title: const Text('New Voice Match (60s)', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/match');
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Color(0xFF707579)),
                title: const Text('Refresh Friends List'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(friendsProvider.notifier).fetchFriends();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF707579)),
                title: const Text('My Profile'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go('/profile');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFriendOptionsModal(BuildContext context, FriendItem friend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                friend.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF2481CC)),
              title: const Text('Open Chat'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/chat/${friend.friendshipId}', extra: friend);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Color(0xFF707579)),
              title: const Text('View Full Profile'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/friend-profile/${friend.friendshipId}', extra: friend);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(friendsProvider.notifier).unfriend(friend.friendshipId);
              },
            ),
          ],
        ),
      ),
    );
  }
}
