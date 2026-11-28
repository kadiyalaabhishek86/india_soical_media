import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/recent_calls_provider.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/utils/coin_billing.dart';
import '../../core/utils/nav_helper.dart';

class RecentCallsScreen extends ConsumerStatefulWidget {
  const RecentCallsScreen({super.key});

  @override
  ConsumerState<RecentCallsScreen> createState() => _RecentCallsScreenState();
}

class _RecentCallsScreenState extends ConsumerState<RecentCallsScreen> {
  int _selectedTab = 0; // 0 = All, 1 = Incoming, 2 = Outgoing, 3 = Missed

  @override
  Widget build(BuildContext context) {
    final allCalls = ref.watch(recentCallsProvider);
    final filtered = allCalls.where((c) {
      if (_selectedTab == 0) return true;
      if (_selectedTab == 1) return c.type == 'incoming';
      if (_selectedTab == 2) return c.type == 'outgoing';
      if (_selectedTab == 3) return c.type == 'missed';
      return true;
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
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Title: Recent Calls
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: Text(
                'Recent Calls',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  color: FriendLoopColors.plum,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Tabs row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  _buildTab('All', 0),
                  const SizedBox(width: 8),
                  _buildTab('Incoming', 1),
                  const SizedBox(width: 8),
                  _buildTab('Outgoing', 2),
                  const SizedBox(width: 8),
                  _buildTab('Missed', 3),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No call history', style: TextStyle(color: FriendLoopColors.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 64, color: FriendLoopColors.border),
                      itemBuilder: (ctx, idx) {
                        final call = filtered[idx];
                        final isMissed = call.type == 'missed';
                        final isOutgoing = call.type == 'outgoing';
                        final typeLabel = isMissed ? 'Missed' : (isOutgoing ? 'Outgoing' : 'Incoming');
                        final coinText = call.coins > 0 ? ' (${call.coins} 🪙)' : '';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                          leading: ClipOval(
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Image.network(
                                call.avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: FriendLoopColors.lavender,
                                  child: const Icon(Icons.person, color: FriendLoopColors.plum),
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            call.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isMissed ? FriendLoopColors.rose : FriendLoopColors.plum,
                            ),
                          ),
                          subtitle: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isMissed
                                    ? Icons.call_missed
                                    : (isOutgoing ? Icons.arrow_outward_rounded : Icons.call_received),
                                size: 14,
                                color: isMissed ? FriendLoopColors.rose : FriendLoopColors.onlineGreen,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '$typeLabel • ${call.time}$coinText',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isMissed ? FriendLoopColors.rose : FriendLoopColors.textSecondary,
                                    fontWeight: isMissed ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              call.mode == 'video' ? Icons.videocam_outlined : Icons.phone_outlined,
                              color: FriendLoopColors.violet,
                              size: 22,
                            ),
                            onPressed: () {
                              final friend = FriendItem(
                                friendshipId: call.id,
                                friendId: call.id,
                                displayName: call.name,
                                state: 'India',
                                images: [call.avatar],
                              );
                              final actionType = call.mode == 'video' ? CoinActionType.video : CoinActionType.voice;
                              if (!CoinBilling.checkAndDeductForAction(
                                context: context,
                                ref: ref,
                                actionType: actionType,
                                friend: friend,
                              )) {
                                return;
                              }
                              context.push(call.mode == 'video' ? '/call/video' : '/call', extra: friend);
                            },
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

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          if (index == 3) {
            ref.read(recentCallsProvider.notifier).markMissedCallsSeen();
          }
        },
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
}
