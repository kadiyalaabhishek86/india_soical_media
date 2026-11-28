import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/coin_billing.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  final FriendItem? friend;

  const VideoCallScreen({
    super.key,
    this.friend,
  });

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  late Timer _durationTimer;
  int _seconds = 136; // Start at 02:16 matching mockup, then increments
  int _elapsedInCallSeconds = 0;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;
  bool _isSwappedView = false;

  @override
  void initState() {
    super.initState();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _seconds++;
        _elapsedInCallSeconds++;
      });
      if (_elapsedInCallSeconds > 0 && _elapsedInCallSeconds % 60 == 0) {
        final profile = ref.read(authProvider).currentUserProfile;
        final coins = profile?.coins ?? 0;
        final isPlus = profile?.isPlusSubscriber ?? false;
        final rate = CoinBilling.costForAction(CoinActionType.video, isPlus: isPlus);
        if (coins >= rate) {
          ref.read(authProvider.notifier).updateCoins(coins - rate);
        } else {
          _durationTimer.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Coins exhausted for Video Call. Please recharge.'),
              backgroundColor: FriendLoopColors.plum,
            ),
          );
          context.pushReplacement('/wallet');
        }
      }
    });
  }

  @override
  void dispose() {
    _durationTimer.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final friend = widget.friend;
    final friendName = friend?.displayName ?? 'Priya Sharma';
    final avatarUrl = (friend != null && friend.images.isNotEmpty)
        ? friend.images.first
        : (friend?.localAssetImage ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80');

    final currentUser = ref.watch(authProvider).currentUserProfile;
    final userAvatar = (currentUser != null && currentUser.images.isNotEmpty)
        ? currentUser.images.first
        : 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80';

    final remoteImage = _isSwappedView ? userAvatar : avatarUrl;
    final localImage = _isSwappedView ? avatarUrl : userAvatar;

    return Scaffold(
      backgroundColor: const Color(0xFF101418),
      body: Stack(
        children: [
          // 1. Full-screen Remote Video / Photo Feed (Matching Screen 5 Mockup)
          Positioned.fill(
            child: _isCameraOff && _isSwappedView
                ? Container(
                    color: FriendLoopColors.plumDark,
                    child: const Center(
                      child: Icon(Icons.videocam_off, size: 64, color: Colors.white54),
                    ),
                  )
                : Image.network(
                    remoteImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: FriendLoopColors.plumDark,
                      child: Center(
                        child: Text(
                          friendName.isNotEmpty ? friendName[0] : '?',
                          style: const TextStyle(fontSize: 72, color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
          ),

          // 2. Subtle Dark Gradient Overlay for Header and Controls visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 3. Top Header: Infinity Logo + Live Timer Pill (Matching Screen 5)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 14.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back / minimize button
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        // Center Infinity Logo
                        Image.asset(
                          'assets/images/friendloop_logo.png',
                          height: 26,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.all_inclusive_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        // Rate badge
                        Container(
                          margin: const EdgeInsets.only(right: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🪙 ', style: TextStyle(fontSize: 12)),
                              Text('40c/m', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Live Duration Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Text(
                        _formatDuration(_seconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      friendName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Floating PiP preview of self (Top Right, Matching Screen 5)
          Positioned(
            top: 75,
            right: 18,
            child: GestureDetector(
              onTap: () {
                setState(() => _isSwappedView = !_isSwappedView);
              },
              child: Container(
                width: 95,
                height: 135,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E50),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _isCameraOff && !_isSwappedView
                          ? Container(
                              color: Colors.black87,
                              child: const Center(
                                child: Icon(Icons.videocam_off, color: Colors.white54, size: 28),
                              ),
                            )
                          : Image.network(
                              localImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.person, color: Colors.white70, size: 36),
                              ),
                            ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.touch_app, color: Colors.white70, size: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 5. Bottom Controls Bar: Mute, Camera toggle, Flip Camera, and End Call
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mic Mute Button
                _buildCallRoundBtn(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  label: _isMuted ? 'Unmute' : 'Mute',
                  color: _isMuted ? FriendLoopColors.rose : Colors.white24,
                  iconColor: Colors.white,
                  onTap: () => setState(() => _isMuted = !_isMuted),
                ),

                // Camera Video Toggle Button
                _buildCallRoundBtn(
                  icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                  label: _isCameraOff ? 'Camera Off' : 'Camera On',
                  color: _isCameraOff ? FriendLoopColors.rose : Colors.white24,
                  iconColor: Colors.white,
                  onTap: () => setState(() => _isCameraOff = !_isCameraOff),
                ),

                // Flip Camera
                _buildCallRoundBtn(
                  icon: Icons.flip_camera_ios,
                  label: 'Flip',
                  color: Colors.white24,
                  iconColor: Colors.white,
                  onTap: () {
                    setState(() => _isFrontCamera = !_isFrontCamera);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isFrontCamera ? 'Front Camera Active' : 'Rear Camera Active'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),

                // Red End Call Button (Solid Red, Matching Mockup)
                _buildCallRoundBtn(
                  icon: Icons.call_end,
                  label: 'End Call',
                  color: const Color(0xFFE53935),
                  iconColor: Colors.white,
                  isLarge: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Video call ended'),
                        backgroundColor: FriendLoopColors.plumDark,
                      ),
                    );
                    context.pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallRoundBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    final size = isLarge ? 64.0 : 54.0;
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
              color: color,
              shape: BoxShape.circle,
              boxShadow: isLarge
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: iconColor, size: isLarge ? 28 : 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
