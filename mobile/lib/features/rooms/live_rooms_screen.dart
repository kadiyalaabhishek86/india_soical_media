import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/rooms_provider.dart';

class LiveRoomsScreen extends ConsumerStatefulWidget {
  const LiveRoomsScreen({super.key});

  @override
  ConsumerState<LiveRoomsScreen> createState() => _LiveRoomsScreenState();
}

class _LiveRoomsScreenState extends ConsumerState<LiveRoomsScreen> {
  int _selectedFilter = 0; // 0 = All, 1 = Voice, 2 = Video

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(roomsProvider.notifier).fetchRooms());
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
      if (_selectedFilter == 1) return r.roomType == 'voice';
      if (_selectedFilter == 2) return r.roomType == 'video';
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
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: FriendLoopColors.plum),
                    onPressed: () => context.push('/notifications'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: FriendLoopColors.plum),
                    onPressed: () => context.push('/friends'),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
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

                      // Quick Action Row
                      Row(
                        children: [
                          _buildQuickAction(context, icon: Icons.people_outline, label: 'Friends', onTap: () => context.push('/friends')),
                          const SizedBox(width: 10),
                          _buildQuickAction(context, icon: Icons.shuffle_rounded, label: 'Random Connect', onTap: () => context.push('/random-connect')),
                          const SizedBox(width: 10),
                          _buildQuickAction(context, icon: Icons.phone_outlined, label: 'Recent Calls', onTap: () => context.push('/recent-calls')),
                        ],
                      ),
                      const SizedBox(height: 16),

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
                                  backgroundImage: NetworkImage(room.hostAvatar),
                                  onBackgroundImageError: (_, __) {},
                                  child: const Icon(Icons.groups, color: FriendLoopColors.plum),
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
