import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/rooms_provider.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/providers/notifications_provider.dart';

class LiveRoomsScreen extends ConsumerStatefulWidget {
  const LiveRoomsScreen({super.key});

  @override
  ConsumerState<LiveRoomsScreen> createState() => _LiveRoomsScreenState();
}

class _LiveRoomsScreenState extends ConsumerState<LiveRoomsScreen> {
  int _selectedFilter = 0; // 0 = All, 1 = Voice, 2 = Video
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _runningRoomsScrollController = ScrollController();
  String _searchQuery = '';
  Timer? _expiryCheckTimer;
  Timer? _runningRoomsAutoScrollTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(roomsProvider.notifier).fetchRooms();
      ref.read(roomsProvider.notifier).dismantleExpiredRooms();
    });
    _expiryCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        ref.read(roomsProvider.notifier).dismantleExpiredRooms();
      }
    });
    _runningRoomsAutoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_runningRoomsScrollController.hasClients) return;
      final maxExtent = _runningRoomsScrollController.position.maxScrollExtent;
      if (maxExtent <= 0) return;
      final nextOffset = _runningRoomsScrollController.offset + 215.0;
      if (nextOffset >= maxExtent + 10) {
        _runningRoomsScrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      } else {
        _runningRoomsScrollController.animateTo(
          nextOffset.clamp(0.0, maxExtent),
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOut,
        );
      }
    });
    _searchController.addListener(() {
      if (mounted) {
        setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    _expiryCheckTimer?.cancel();
    _runningRoomsAutoScrollTimer?.cancel();
    _runningRoomsScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openFriendsInviteSheet() {
    final friends = ref.read(friendsProvider).friends;
    final Set<String> invitedIds = {};
    final Set<String> joinedIds = {};
    String selectedActivity = 'ludo';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Invite Friends to Room',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: FriendLoopColors.plum),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: FriendLoopColors.textMuted),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const Text(
                      'Invite friends below. Once they join, start your Friends Room (public can view, comment & send gifts).',
                      style: TextStyle(fontSize: 12, color: FriendLoopColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Select Game',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FriendLoopColors.plum),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 3.0,
                      children: [
                        for (final opt in const [
                          {'id': 'ludo', 'emoji': '🎲', 'label': 'Ludo 2v2'},
                          {'id': 'carrom', 'emoji': '🎯', 'label': 'Carrom Clash'},
                          {'id': 'truth_or_dare', 'emoji': '🍾', 'label': 'Truth / Dare'},
                          {'id': 'voice_mimic', 'emoji': '🐱', 'label': 'Voice Mimic'},
                        ])
                          GestureDetector(
                            onTap: () => setSheetState(() => selectedActivity = opt['id']!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: selectedActivity == opt['id']
                                    ? FriendLoopColors.violet
                                    : FriendLoopColors.canvas,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedActivity == opt['id']
                                      ? FriendLoopColors.violet
                                      : FriendLoopColors.border,
                                  width: 1.3,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(opt['emoji']!, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      opt['label']!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: selectedActivity == opt['id']
                                            ? Colors.white
                                            : FriendLoopColors.plum,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: friends.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: FriendLoopColors.border),
                        itemBuilder: (_, idx) {
                          final f = friends[idx];
                          final isInvited = invitedIds.contains(f.friendId);
                          final isJoined = joinedIds.contains(f.friendId);
                          final avatar = f.images.isNotEmpty
                              ? f.images.first
                              : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80';
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(avatar),
                              onBackgroundImageError: (_, __) {},
                            ),
                            title: Text(f.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.plum)),
                            subtitle: Text(
                              isJoined ? '● Joined & ready in lobby' : (isInvited ? 'Invite sent...' : 'Online'),
                              style: TextStyle(
                                fontSize: 12,
                                color: isJoined ? FriendLoopColors.onlineGreen : FriendLoopColors.textSecondary,
                                fontWeight: isJoined ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: isJoined
                                ? const Chip(
                                    label: Text('Joined ✓', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                    backgroundColor: FriendLoopColors.onlineGreen,
                                  )
                                : ElevatedButton(
                                    onPressed: isInvited
                                        ? null
                                        : () {
                                            setSheetState(() => invitedIds.add(f.friendId));
                                            Timer(const Duration(milliseconds: 700), () {
                                              if (sheetCtx.mounted) {
                                                setSheetState(() => joinedIds.add(f.friendId));
                                              }
                                            });
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: FriendLoopColors.violet,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: Text(isInvited ? 'Invited...' : 'Invite', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: joinedIds.isEmpty
                            ? null
                            : () async {
                                final joinedNames = friends
                                    .where((f) => joinedIds.contains(f.friendId))
                                    .map((f) => f.displayName.split(' ').first)
                                    .join(', ');
                                Navigator.pop(sheetCtx);
                                final room = await ref.read(roomsProvider.notifier).createRoom(
                                  title: 'Friends Room • $joinedNames',
                                  roomType: 'voice',
                                  activityType: selectedActivity,
                                  language: 'English',
                                  accessType: 'friends_public',
                                  entryFeeCoins: 0,
                                  maxSeats: 1 + joinedIds.length,
                                  activeCount: 1 + joinedIds.length,
                                  invitedFriendIds: joinedIds.toList(),
                                );
                                ref.read(notificationsProvider.notifier).addFriendRoomOrGameNotification(
                                  friendName: 'You',
                                  roomTitle: room.title,
                                  roomId: room.id,
                                  isGame: true,
                                  roomData: room.toJson(),
                                );
                                if (!mounted) return;
                                await context.push('/room/${room.id}', extra: {
                                  ...room.toJson(),
                                  'is_host': true,
                                  'is_friends_room': true,
                                });
                                ref.read(roomsProvider.notifier).fetchRooms();
                              },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          joinedIds.isEmpty
                              ? 'Invite a friend first to start'
                              : 'Start Friends Room (${1 + joinedIds.length} in room)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FriendLoopColors.violet,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openRandomRoomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Random Room Match',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: FriendLoopColors.plum),
              ),
              const SizedBox(height: 4),
              const Text(
                'Create a random room for Voice, Video, or Party Games:',
                style: TextStyle(fontSize: 12, color: FriendLoopColors.textSecondary),
              ),
              const SizedBox(height: 14),
              _buildRandomOptionTile(
                ctx: ctx,
                icon: Icons.mic_none_rounded,
                title: 'Random Voice Room',
                subtitle: '15-min live audio hangout with a random partner',
                onTap: () => _createAndEnterRandomRoom(ctx, title: 'Random Voice Lounge', roomType: 'voice', activityType: 'voice_lounge'),
              ),
              _buildRandomOptionTile(
                ctx: ctx,
                icon: Icons.videocam_outlined,
                title: 'Random Video Room',
                subtitle: '15-min face-to-face video stage with a random partner',
                onTap: () => _createAndEnterRandomRoom(ctx, title: 'Random Video Stage', roomType: 'video', activityType: 'video_stage'),
              ),
              _buildRandomOptionTile(
                ctx: ctx,
                icon: Icons.sports_esports_outlined,
                title: 'Random Game Room (2 Players Auto-Play)',
                subtitle: 'Instant Carrom or Ludo match — auto-plays with 2 people',
                onTap: () => _createAndEnterRandomRoom(ctx, title: 'Random Carrom Clash', roomType: 'voice', activityType: 'carrom'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRandomOptionTile({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: FriendLoopColors.lavender, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: FriendLoopColors.violet),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: FriendLoopColors.plum, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: FriendLoopColors.textSecondary)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: FriendLoopColors.violet),
      onTap: onTap,
    );
  }

  Future<void> _createAndEnterRandomRoom(
    BuildContext sheetCtx, {
    required String title,
    required String roomType,
    required String activityType,
  }) async {
    Navigator.pop(sheetCtx);
    final room = await ref.read(roomsProvider.notifier).createRoom(
      title: title,
      roomType: roomType,
      activityType: activityType,
      language: 'English',
      accessType: 'public',
      entryFeeCoins: 0,
      maxSeats: 2,
      activeCount: 2,
    );
    if (!mounted) return;
    await context.push('/room/${room.id}', extra: {
      ...room.toJson(),
      'is_host': true,
    });
    ref.read(roomsProvider.notifier).fetchRooms();
  }

  String _getActivityBadge(String act) {
    switch (act) {
      case 'carrom':
        return '🎯 Carrom Clash';
      case 'ludo':
        return '🎲 Ludo 2v2';
      case 'truth_or_dare':
        return '🍾 Truth or Dare';
      case 'voice_mimic':
        return '🐱 Voice Mimic';
      case 'video_stage':
        return '📹 Video Stage';
      default:
        return '🎙️ Voice Lounge';
    }
  }

  Color _getActivityColor(String act) {
    switch (act) {
      case 'carrom':
        return Colors.deepPurple;
      case 'ludo':
        return Colors.indigo;
      case 'truth_or_dare':
        return Colors.pink;
      case 'voice_mimic':
        return Colors.teal;
      default:
        return FriendLoopColors.violet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsState = ref.watch(roomsProvider);
    final filteredRooms = roomsState.rooms.where((r) {
      if (_selectedFilter == 1 && r.roomType != 'voice') return false;
      if (_selectedFilter == 2 && r.roomType != 'video') return false;
      if (_searchQuery.isNotEmpty) {
        final title = r.title.toLowerCase();
        final act = _getActivityBadge(r.activityType).toLowerCase();
        final lang = r.language.toLowerCase();
        if (!title.contains(_searchQuery) && !act.contains(_searchQuery) && !lang.contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: FriendLoopColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/friendloop_logo.png',
                    height: 36,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.all_inclusive_rounded,
                      color: FriendLoopColors.violet,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_isSearchOpen)
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: FriendLoopColors.border),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(fontSize: 13.5, color: FriendLoopColors.plum),
                          decoration: const InputDecoration(
                            hintText: 'Search event or room names...',
                            hintStyle: TextStyle(fontSize: 12.5, color: FriendLoopColors.textMuted),
                            prefixIcon: Icon(Icons.search, size: 18, color: FriendLoopColors.violet),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 9),
                          ),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (!_isSearchOpen)
                    Consumer(
                      builder: (context, ref, _) {
                        final notifCount = ref.watch(totalNotificationsBadgeProvider);
                        return IconButton(
                          icon: Badge(
                            isLabelVisible: notifCount > 0,
                            backgroundColor: FriendLoopColors.rose,
                            label: Text(
                              '$notifCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            child: const Icon(Icons.notifications_none, color: FriendLoopColors.plum),
                          ),
                          onPressed: () => context.push('/notifications'),
                        );
                      },
                    ),
                  IconButton(
                    icon: Icon(_isSearchOpen ? Icons.close : Icons.search, color: FriendLoopColors.plum),
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
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(roomsProvider.notifier).fetchRooms(),
                color: FriendLoopColors.violet,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Rooms & Party Games',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: FriendLoopColors.plum,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quick Action Row (Recent Calls removed)
                      Row(
                        children: [
                          _buildQuickAction(context, icon: Icons.people_outline, label: 'Friends', onTap: _openFriendsInviteSheet),
                          const SizedBox(width: 10),
                          _buildQuickAction(context, icon: Icons.shuffle_rounded, label: 'Random Connect', onTap: _openRandomRoomSheet),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Horizontal Scrolling Running Rooms Strip for Public Viewers
                      if (roomsState.rooms.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Running Now • Public View',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: FriendLoopColors.plum,
                              ),
                            ),
                            Text(
                              '${roomsState.rooms.length} live',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: FriendLoopColors.violet,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 114,
                          child: ListView.separated(
                            controller: _runningRoomsScrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: roomsState.rooms.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (ctx, idx) {
                              final r = roomsState.rooms[idx];
                              final badge = _getActivityBadge(r.activityType);
                              return GestureDetector(
                                onTap: () async {
                                  await context.push('/room/${r.id}', extra: {
                                    ...r.toJson(),
                                    'is_public_viewer': true,
                                  });
                                  ref.read(roomsProvider.notifier).fetchRooms();
                                },
                                child: Container(
                                  width: 205,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: FriendLoopColors.lavender, width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: FriendLoopColors.violet.withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: FriendLoopColors.onlineGreen,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              r.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.5,
                                                color: FriendLoopColors.plum,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        badge,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: FriendLoopColors.violet,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${r.activeCount} watching',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 10.5, color: FriendLoopColors.textSecondary),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: FriendLoopColors.lavender,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Text(
                                              'View 👀',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: FriendLoopColors.violet,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Filter Pills (All, Voice, Video)
                      Row(
                        children: [
                          _buildFilterPill('All', 0),
                          const SizedBox(width: 8),
                          _buildFilterPill('Voice', 1, icon: Icons.mic_none),
                          const SizedBox(width: 8),
                          _buildFilterPill('Video', 2, icon: Icons.videocam_outlined),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Rooms List
                      if (roomsState.isLoading && filteredRooms.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                      else if (filteredRooms.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No active rooms found. Tap below to create your room!', style: TextStyle(color: FriendLoopColors.textMuted)),
                          ),
                        )
                      else
                        ...filteredRooms.map((room) {
                          final isVideo = room.roomType == 'video';
                          final badge = _getActivityBadge(room.activityType);
                          final badgeColor = _getActivityColor(room.activityType);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: FriendLoopColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: FriendLoopColors.lavender,
                                  backgroundImage: room.hostAvatar.isNotEmpty ? NetworkImage(room.hostAvatar) : null,
                                  onBackgroundImageError: (_, __) {},
                                  child: room.hostAvatar.isEmpty
                                      ? const Icon(Icons.groups, color: FriendLoopColors.plum)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        room.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: FriendLoopColors.plum),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              badge,
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(isVideo ? Icons.videocam : Icons.mic, size: 13, color: FriendLoopColors.textSecondary),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${room.activeCount} in room',
                                                style: const TextStyle(fontSize: 11, color: FriendLoopColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    await context.push('/room/${room.id}', extra: room.toJson());
                                    ref.read(roomsProvider.notifier).fetchRooms();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: FriendLoopColors.violet,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text('Join', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        }),

                      const SizedBox(height: 16),
                      // + Create Room Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await context.push('/create-room');
                            ref.read(roomsProvider.notifier).fetchRooms();
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Create Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FriendLoopColors.violet,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, int index, {IconData? icon}) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = index);
        ref.read(roomsProvider.notifier).fetchRooms(
          filter: index == 0 ? 'all' : (index == 1 ? 'voice' : 'video'),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? FriendLoopColors.violet : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? FriendLoopColors.violet : FriendLoopColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : FriendLoopColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : FriendLoopColors.plum,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FriendLoopColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: FriendLoopColors.violet, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: FriendLoopColors.plum),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
