import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/coin_billing.dart';
import '../../core/utils/nav_helper.dart';

class FriendsListScreen extends ConsumerStatefulWidget {
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;
  String _searchQuery = '';
  int _selectedTab = 0; // 0 = All, 1 = Online, 2 = Unread

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

    final displayedFriends = friendsState.friends.where((f) {
      if (currentUserId.isNotEmpty && f.friendId == currentUserId) return false;
      if (currentUserName.isNotEmpty && f.displayName.toLowerCase().trim() == currentUserName) return false;

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

      if (_selectedTab == 1 && (f.statusText ?? 'online').toLowerCase() != 'online') {
        return false;
      }
      if (_selectedTab == 2 && f.unreadCount <= 0) {
        return false;
      }

      if (_searchQuery.isEmpty) return true;
      final city = (f.city ?? '').toLowerCase();
      return name.contains(_searchQuery) || city.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: FriendLoopColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
          onPressed: () => safePop(context),
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
            : Image.asset(
                'assets/images/friendloop_logo.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.all_inclusive_rounded,
                  size: 28,
                  color: FriendLoopColors.violet,
                ),
              ),
        centerTitle: true,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Title: Friends (matching Recent Calls layout)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Text(
                'Friends',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  color: FriendLoopColors.plum,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Tabs row (matching Recent Calls)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  _buildTab('All', 0),
                  const SizedBox(width: 8),
                  _buildTab('Online', 1),
                  const SizedBox(width: 8),
                  _buildTab('Unread', 2),
                ],
              ),
            ),
            const SizedBox(height: 4),

            Expanded(
              child: RefreshIndicator(
                color: FriendLoopColors.violet,
                onRefresh: () => ref.read(friendsProvider.notifier).fetchFriends(),
                child: displayedFriends.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: displayedFriends.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 64, color: FriendLoopColors.border),
                        itemBuilder: (context, index) {
                          final friend = displayedFriends[index];
                          return _buildFriendRow(context, friend);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
      ),
    );
  }

  Widget _buildFriendRow(BuildContext context, FriendItem friend) {
    final avatarUrl = friend.images.isNotEmpty
        ? friend.images.first
        : (friend.localAssetImage ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80');
    final isOnline = (friend.statusText ?? 'online').toLowerCase() == 'online';
    final location = (friend.city != null && friend.city!.isNotEmpty) ? friend.city! : friend.state;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      onTap: () => context.push('/friend-profile/${friend.friendshipId}', extra: friend),
      leading: Stack(
        children: [
          ClipOval(
            child: SizedBox(
              width: 44,
              height: 44,
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: FriendLoopColors.lavender,
                  child: Center(
                    child: Text(
                      friend.displayName.isNotEmpty ? friend.displayName[0] : 'F',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: FriendLoopColors.violet, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: FriendLoopColors.onlineGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.8),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        friend.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: FriendLoopColors.plum,
        ),
      ),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.circle : Icons.schedule,
            size: isOnline ? 8 : 13,
            color: isOnline ? FriendLoopColors.onlineGreen : FriendLoopColors.textMuted,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '${isOnline ? "Online" : (friend.statusText ?? "Offline")} • $location',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: FriendLoopColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            icon: const Icon(Icons.phone_outlined, color: FriendLoopColors.violet, size: 21),
            tooltip: 'Voice Call',
            onPressed: () {
              if (!CoinBilling.checkAndDeductForAction(
                context: context,
                ref: ref,
                actionType: CoinActionType.voice,
                friend: friend,
              )) {
                return;
              }
              context.push('/call', extra: friend);
            },
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            icon: const Icon(Icons.videocam_outlined, color: FriendLoopColors.violet, size: 21),
            tooltip: 'Video Call',
            onPressed: () {
              if (!CoinBilling.checkAndDeductForAction(
                context: context,
                ref: ref,
                actionType: CoinActionType.video,
                friend: friend,
              )) {
                return;
              }
              context.push('/call/video', extra: friend);
            },
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: FriendLoopColors.violet, size: 20),
            tooltip: 'Chat',
            onPressed: () {
              if (!CoinBilling.checkAndDeductForAction(
                context: context,
                ref: ref,
                actionType: CoinActionType.chat,
                friend: friend,
                chatRouteId: friend.friendshipId,
              )) {
                return;
              }
              context.push('/chat/${friend.friendshipId}', extra: friend);
            },
          ),
        ],
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
