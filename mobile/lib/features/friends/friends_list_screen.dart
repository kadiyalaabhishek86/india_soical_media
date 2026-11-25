import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/providers/auth_provider.dart';

class FriendsListScreen extends ConsumerStatefulWidget {
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;
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

    // Filter items: isolate per-user data and exclude technical/broadcast channels
    final displayedFriends = friendsState.friends.where((f) {
      if (currentUserId.isNotEmpty && f.friendId == currentUserId) return false;
      if (currentUserName.isNotEmpty && f.displayName.toLowerCase().trim() == currentUserName) return false;
      
      // Exclude legacy technical channels, jobs, or bots
      final name = f.displayName.toLowerCase();
      if (name.contains('technical') ||
          name.contains('walkin') ||
          name.contains('python') ||
          name.contains('job') ||
          name.contains('hub') ||
          name.contains('community') ||
          name.contains('📢') ||
          name.contains('📈')) {
        return false;
      }

      if (_searchQuery.isEmpty) return true;
      final city = (f.city ?? '').toLowerCase();
      return name.contains(_searchQuery) || city.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: FriendLoopColors.canvas, // FriendLoop canvas #F4EBFC
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
          onPressed: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: _isSearchOpen
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FriendLoopColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 14, color: FriendLoopColors.plum),
                  decoration: const InputDecoration(
                    hintText: 'Search friends...',
                    hintStyle: TextStyle(fontSize: 13, color: FriendLoopColors.textMuted),
                    prefixIcon: Icon(Icons.search, size: 18, color: FriendLoopColors.violet),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              )
            : const Text(
                'Friends',
                style: TextStyle(
                  color: FriendLoopColors.plum,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchOpen ? Icons.close : Icons.search,
              color: FriendLoopColors.plum,
            ),
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: FriendLoopColors.violet,
          onRefresh: () => ref.read(friendsProvider.notifier).fetchFriends(),
          child: displayedFriends.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: displayedFriends.length,
                  itemBuilder: (context, index) {
                    final friend = displayedFriends[index];
                    return _buildFriendCard(context, friend);
                  },
                ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: FriendLoopColors.border.withValues(alpha: 0.7))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: FriendLoopColors.violet,
          unselectedItemColor: FriendLoopColors.plum.withValues(alpha: 0.6),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: (index) {
            if (index == 0) context.go('/');
            if (index == 1) context.go('/reels');
            if (index == 2) context.go('/rooms');
            if (index == 3) context.go('/chats');
            if (index == 4) context.go('/profile');
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_display_outlined),
              label: 'Reels',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              label: 'Rooms',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // Matching Screen 5: Friend Card with rounded avatar, Name, Online status, and 📞 📹 💬 actions
  Widget _buildFriendCard(BuildContext context, FriendItem friend) {
    final avatarUrl = friend.images.isNotEmpty
        ? friend.images.first
        : (friend.localAssetImage ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0E5FA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          context.push('/friend-profile/${friend.friendshipId}', extra: friend);
        },
        child: Row(
          children: [
            // Rounded square photo (matching Screen 5)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                avatarUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: FriendLoopColors.lavender,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      friend.displayName.isNotEmpty ? friend.displayName[0] : 'F',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: FriendLoopColors.violet, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Friend Name & Online Status (matching Screen 5)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: FriendLoopColors.plum,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: FriendLoopColors.onlineGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: FriendLoopColors.plum,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right Action Buttons: 📞 Voice, 📹 Video, 💬 Chat (matching Screen 5)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionBtn(
                  icon: Icons.phone_outlined,
                  tooltip: 'Voice Call',
                  onTap: () => context.push('/call', extra: friend),
                ),
                const SizedBox(width: 6),
                _buildActionBtn(
                  icon: Icons.videocam_outlined,
                  tooltip: 'Video Call',
                  onTap: () => context.push('/call/video', extra: friend),
                ),
                const SizedBox(width: 6),
                _buildActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  tooltip: 'Chat',
                  onTap: () => context.push('/chat/${friend.friendshipId}', extra: friend),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F0FD),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEAD8FA), width: 1),
          ),
          child: Center(
            child: Icon(icon, color: FriendLoopColors.violet, size: 18),
          ),
        ),
      ),
    );
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
                color: Colors.white,
              ),
              child: const Icon(Icons.people_outline, color: FriendLoopColors.violet, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Friends Found',
              style: TextStyle(
                color: FriendLoopColors.plum,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Connect with new people on Home or Random Connect!',
              style: TextStyle(color: FriendLoopColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FriendLoopColors.violet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Discover Friends'),
            ),
          ],
        ),
      ),
    );
  }
}
