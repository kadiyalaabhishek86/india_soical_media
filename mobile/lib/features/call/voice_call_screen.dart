import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/aara_card.dart';
import '../../shared/widgets/aara_timer.dart';
import '../../core/providers/call_provider.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/coin_billing.dart';

class VoiceCallScreen extends ConsumerStatefulWidget {
  final FriendItem? friend;

  const VoiceCallScreen({super.key, this.friend});

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen> {
  Timer? _timer;
  int _friendCallSeconds = 0;
  bool _isFriendMuted = false;
  bool _isSpeakerOn = true;

  @override
  void initState() {
    super.initState();
    if (widget.friend != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _friendCallSeconds++);
        // Deduct coins per minute according to active plan after the first minute
        if (_friendCallSeconds > 0 && _friendCallSeconds % 60 == 0) {
          final profile = ref.read(authProvider).currentUserProfile;
          final coins = profile?.coins ?? 0;
          final isPlus = profile?.isPlusSubscriber ?? false;
          final rate = CoinBilling.costForAction(CoinActionType.voice, isPlus: isPlus);
          if (coins >= rate) {
            ref.read(authProvider.notifier).updateCoins(coins - rate);
          } else {
            _timer?.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Coins exhausted for Voice Call. Please recharge.'),
                backgroundColor: FriendLoopColors.plum,
              ),
            );
            context.pushReplacement('/wallet');
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int total) {
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    final partner = callState.session?.partner;

    // Listen for random match call ended to go to post-call screen
    if (widget.friend == null) {
      ref.listen<CallState>(callProvider, (prev, next) {
        if (next.hasEnded) {
          context.go('/post-call');
        }
      });
    }

    if (widget.friend != null) {
      return _buildFriendVoiceCall(context, widget.friend!);
    }

    return Scaffold(
      backgroundColor: AaraColors.background,
      appBar: AppBar(
        title: Text(callState.isConnecting ? 'Connecting Call...' : '60-Second Match'),
        automaticallyImplyLeading: false,
        actions: [
          // Keep Report explicitly visible (Requested by user)
          TextButton.icon(
            icon: const Icon(Icons.flag_outlined, color: AaraColors.error, size: 18),
            label: const Text(
              'Report',
              style: TextStyle(
                color: AaraColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            onPressed: () => _showReportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.block, color: AaraColors.textSecondary),
            tooltip: 'Block',
            onPressed: () => _showBlockDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Partner Header Info
              AaraCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AaraColors.champagne.withOpacity(0.2),
                      child: Text(
                        partner != null && partner.displayName.isNotEmpty
                            ? partner.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AaraColors.champagneLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partner?.displayName ?? 'Matching Partner',
                            style: AaraTypography.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            partner != null
                                ? '${partner.state} • ${partner.languages.join(", ")}'
                                : 'Connecting across India...',
                            style: AaraTypography.labelSmall.copyWith(color: AaraColors.champagneLight),
                          ),
                        ],
                      ),
                    ),
                    if (callState.isConnecting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AaraColors.champagneLight),
                      ),
                  ],
                ),
              ),

              const Spacer(),

              // Circular Countdown Timer
              if (callState.isConnecting) ...[
                const SizedBox(
                  width: 160,
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AaraColors.champagneLight,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Waiting for partner to connect...', style: AaraTypography.bodyMedium),
              ] else ...[
                AaraCountdownTimer(
                  remainingSeconds: callState.remainingSeconds,
                  totalSeconds: 60,
                  size: 210,
                ),
                if (callState.isReconnecting) ...[
                  const SizedBox(height: 12),
                  const Text('Reconnecting session...', style: TextStyle(color: AaraColors.warning)),
                ],
              ],

              const Spacer(),

              // In-call Control Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute Button
                  _buildCallControl(
                    icon: callState.isMuted ? Icons.mic_off : Icons.mic,
                    label: callState.isMuted ? 'Muted' : 'Mute',
                    isActive: callState.isMuted,
                    activeColor: AaraColors.warning,
                    onTap: () {
                      ref.read(callProvider.notifier).toggleMute();
                    },
                  ),

                  // End Call Button (Solid Red button as requested)
                  _buildCallControl(
                    icon: Icons.call_end,
                    label: 'End Call',
                    isActive: true,
                    activeColor: AaraColors.error,
                    isSolid: true,
                    isLarge: true,
                    onTap: () {
                      ref.read(callProvider.notifier).leaveCall();
                    },
                  ),

                  // Camera Consent toggle (kept OFF by default in Pilot 1)
                  _buildCallControl(
                    icon: callState.isCameraOn ? Icons.videocam : Icons.videocam_off,
                    label: 'Camera',
                    isActive: callState.isCameraOn,
                    activeColor: AaraColors.champagne,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Video matching is disabled in Pilot 1 (audio-only).'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallControl({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
    bool isLarge = false,
    bool isSolid = false,
  }) {
    final size = isLarge ? 64.0 : 52.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSolid
                  ? activeColor
                  : (isActive ? activeColor.withValues(alpha: 0.15) : Colors.white),
              border: Border.all(
                color: isSolid ? activeColor : (isActive ? activeColor : AaraColors.border),
                width: 1.5,
              ),
              boxShadow: isSolid
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isSolid ? Colors.white : (isActive ? activeColor : AaraColors.textPrimary),
              size: isLarge ? 28 : 22,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AaraTypography.labelSmall.copyWith(
            color: isSolid ? activeColor : (isActive ? activeColor : AaraColors.textSecondary),
            fontWeight: isSolid ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block Participant?'),
        content: const Text(
          'Blocking will immediately end this call and permanently prevent any future matching, calls, or chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AaraColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(callProvider.notifier).blockParticipant('Blocked during call');
            },
            child: const Text('Block & End Call', style: TextStyle(color: AaraColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendVoiceCall(BuildContext context, FriendItem friend) {
    final avatarUrl = friend.images.isNotEmpty
        ? friend.images.first
        : (friend.localAssetImage ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80');

    return Scaffold(
      backgroundColor: FriendLoopColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
          onPressed: () => context.pop(),
        ),
        title: Text(
          friend.displayName,
          style: const TextStyle(
            color: FriendLoopColors.plum,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: FriendLoopColors.rose, size: 20),
            tooltip: 'Report',
            onPressed: () => _showReportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.block, color: FriendLoopColors.textMuted, size: 20),
            tooltip: 'Block',
            onPressed: () => _showBlockDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const Spacer(),

              // Friend Profile Picture with Pulsing Glow Ring & Online Dot
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer decorative pulse rings
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: FriendLoopColors.violet.withValues(alpha: 0.08),
                      ),
                    ),
                    Container(
                      width: 145,
                      height: 145,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: FriendLoopColors.violet.withValues(alpha: 0.16),
                      ),
                    ),
                    // Main Avatar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.network(
                        avatarUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 120,
                          height: 120,
                          color: FriendLoopColors.lavender,
                          child: Center(
                            child: Text(
                              friend.displayName.isNotEmpty ? friend.displayName[0] : '?',
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: FriendLoopColors.violet,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Online Badge
                    Positioned(
                      bottom: 8,
                      right: 18,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: FriendLoopColors.onlineGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Friend Name & Location
              Text(
                friend.displayName,
                style: const TextStyle(
                  color: FriendLoopColors.plum,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                friend.city != null && friend.city!.isNotEmpty
                    ? '${friend.city}, ${friend.state}'
                    : friend.state,
                style: const TextStyle(
                  color: FriendLoopColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 14),

              // Rate & Status Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: FriendLoopColors.lavender.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FriendLoopColors.lavender),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🪙 ', style: TextStyle(fontSize: 12)),
                    Text(
                      'Voice Call • 10 coins/min • Connected',
                      style: TextStyle(
                        color: FriendLoopColors.violet,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Live Call Duration Counter
              Text(
                _formatDuration(_friendCallSeconds),
                style: const TextStyle(
                  color: FriendLoopColors.plum,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),

              const Spacer(),

              // In-call Control Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute Button
                  _buildCallControl(
                    icon: _isFriendMuted ? Icons.mic_off : Icons.mic,
                    label: _isFriendMuted ? 'Muted' : 'Mute',
                    isActive: _isFriendMuted,
                    activeColor: FriendLoopColors.rose,
                    onTap: () {
                      setState(() => _isFriendMuted = !_isFriendMuted);
                    },
                  ),

                  // Speaker Button
                  _buildCallControl(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                    label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                    isActive: _isSpeakerOn,
                    activeColor: FriendLoopColors.violet,
                    onTap: () {
                      setState(() => _isSpeakerOn = !_isSpeakerOn);
                    },
                  ),

                  // Switch to Video Call
                  _buildCallControl(
                    icon: Icons.videocam_outlined,
                    label: 'Video',
                    isActive: false,
                    activeColor: FriendLoopColors.violet,
                    onTap: () {
                      context.pushReplacement('/call/video', extra: friend);
                    },
                  ),

                  // End Call Button (Solid Red)
                  _buildCallControl(
                    icon: Icons.call_end,
                    label: 'End Call',
                    isActive: true,
                    activeColor: const Color(0xFFE53935),
                    isSolid: true,
                    isLarge: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Voice call ended'),
                          backgroundColor: FriendLoopColors.plumDark,
                        ),
                      );
                      context.pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    String selectedReason = 'harassment';
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Report Participant'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your identity is kept strictly confidential.'),
              const SizedBox(height: 12),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedReason,
                dropdownColor: AaraColors.surfaceCard,
                items: const [
                  DropdownMenuItem(value: 'harassment', child: Text('Harassment or Abusive Language')),
                  DropdownMenuItem(value: 'threats', child: Text('Threats or Intimidation')),
                  DropdownMenuItem(value: 'scam', child: Text('Scam or Commercial Solicitation')),
                  DropdownMenuItem(value: 'underage', child: Text('Suspected Underage (<18)')),
                  DropdownMenuItem(value: 'inappropriate_content', child: Text('Inappropriate Content')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedReason = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(
                  hintText: 'Optional context for moderators...',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AaraColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(callProvider.notifier).reportParticipant(selectedReason, detailsController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted confidentially.')),
                );
              },
              child: const Text('Submit Report', style: TextStyle(color: AaraColors.champagneLight)),
            ),
          ],
        ),
      ),
    );
  }
}
