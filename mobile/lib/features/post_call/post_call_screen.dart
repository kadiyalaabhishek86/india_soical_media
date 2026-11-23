import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/aara_button.dart';
import '../../shared/widgets/aara_card.dart';
import '../../core/providers/call_provider.dart';
import '../../core/providers/friends_provider.dart';

class PostCallScreen extends ConsumerStatefulWidget {
  const PostCallScreen({super.key});

  @override
  ConsumerState<PostCallScreen> createState() => _PostCallScreenState();
}

class _PostCallScreenState extends ConsumerState<PostCallScreen> {
  bool _requestSent = false;
  bool _isMutual = false;

  Future<void> _handleAddFriend() async {
    final call = ref.read(callProvider).session;
    if (call == null || call.partner == null) return;

    final isMutual = await ref.read(friendsProvider.notifier).chooseAddFriend(
      callId: call.id,
      targetId: call.partner!.id,
    );

    setState(() {
      _requestSent = true;
      _isMutual = isMutual;
    });
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    final partner = callState.session?.partner;
    final friendsState = ref.watch(friendsProvider);

    return Scaffold(
      backgroundColor: AaraColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Celebratory / Call Completed Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AaraColors.surfaceCard,
                  border: Border.all(color: AaraColors.champagneLight, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AaraColors.champagne.withOpacity(0.2),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    partner != null && partner.displayName.isNotEmpty
                        ? partner.displayName[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: AaraColors.champagneLight,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'Call Completed',
                style: AaraTypography.labelSmall.copyWith(
                  letterSpacing: 2,
                  color: AaraColors.champagneLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                partner?.displayName ?? 'Your Match',
                style: AaraTypography.displayMedium,
              ),
              const SizedBox(height: 4),
              Text(
                partner != null ? '${partner.state} • ${partner.languages.join(", ")}' : 'India',
                style: AaraTypography.bodyMedium,
              ),

              const SizedBox(height: 28),

              // Mutual Feedback Card
              if (_requestSent)
                AaraCard(
                  hasGlow: _isMutual,
                  child: Column(
                    children: [
                      Icon(
                        _isMutual ? Icons.celebration : Icons.check_circle_outline,
                        color: _isMutual ? AaraColors.champagneLight : AaraColors.success,
                        size: 32,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isMutual
                            ? "It's a Mutual Friendship!"
                            : 'Friend Request Recorded',
                        style: AaraTypography.titleMedium.copyWith(
                          color: _isMutual ? AaraColors.champagneLight : AaraColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isMutual
                            ? 'You can now exchange free private text messages anytime.'
                            : 'Your choice remains strictly private. If they also choose Add Friend, you will be connected.',
                        style: AaraTypography.bodyMedium.copyWith(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                AaraCard(
                  child: Text(
                    'Would you like to keep in touch with ${partner?.displayName ?? "them"}? When both people choose Add Friend, a private chat opens.',
                    style: AaraTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),

              const Spacer(),

              // Primary: Add Friend
              if (!_requestSent)
                AaraButton(
                  text: 'Add Friend',
                  icon: Icons.person_add_alt_1,
                  isLoading: friendsState.isLoading,
                  onPressed: _handleAddFriend,
                )
              else if (_isMutual)
                AaraButton(
                  text: 'Open Private Chat',
                  icon: Icons.chat_bubble_outline,
                  onPressed: () {
                    context.go('/friends');
                  },
                ),

              const SizedBox(height: 14),

              // Secondary: Next Match
              AaraButton(
                text: 'Next Match',
                variant: AaraButtonVariant.secondary,
                onPressed: () {
                  context.go('/match');
                },
              ),

              const SizedBox(height: 14),

              // Tertiary: Report
              TextButton(
                onPressed: () => _showReportDialog(context),
                child: const Text('Report Call Experience', style: TextStyle(color: AaraColors.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Call'),
        content: const Text('Reports are reviewed confidentially by our moderation team.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AaraColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(callProvider.notifier).reportParticipant('harassment', 'Reported on post-call screen');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted.')),
              );
            },
            child: const Text('Submit Report', style: TextStyle(color: AaraColors.champagneLight)),
          ),
        ],
      ),
    );
  }
}
