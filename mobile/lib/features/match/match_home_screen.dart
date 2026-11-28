import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/aara_button.dart';
import '../../shared/widgets/aara_badge.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/match_provider.dart';
import '../../core/providers/call_provider.dart';

class MatchHomeScreen extends ConsumerStatefulWidget {
  const MatchHomeScreen({super.key});

  @override
  ConsumerState<MatchHomeScreen> createState() => _MatchHomeScreenState();
}

class _MatchHomeScreenState extends ConsumerState<MatchHomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startVoiceMatch() async {
    final auth = ref.read(authProvider);
    final profile = auth.currentUserProfile;

    if (profile != null && profile.freeCallsRemaining <= 0 && !profile.hasActivePass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Free call allowance exhausted. Get a 20-minute pass or continue chat with friends.'),
          backgroundColor: AaraColors.warning,
        ),
      );
      return;
    }

    try {
      await ref.read(matchProvider.notifier).joinQueue(callMode: 'voice');
      final matchState = ref.read(matchProvider);

      if (matchState.matchedSession != null) {
        ref.read(callProvider.notifier).startSession(matchState.matchedSession!);
        if (mounted) context.go('/call');
      } else {
        if (mounted) context.go('/queue');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AaraColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUserProfile;

    return Scaffold(
      backgroundColor: AaraColors.background, // Warm ivory (#FFFBF7)
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                child: Column(
                  children: [
                    // Top App Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Playfair Display for the Aara wordmark
                              const Text('Aara', style: AaraTypography.displayLarge),
                              Text(
                                user != null ? '${user.state} • ${user.languages.join(", ")}' : 'India-wide Match',
                                style: AaraTypography.labelSmall.copyWith(color: AaraColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: AaraAllowanceBadge(
                            remaining: user?.freeCallsRemaining ?? 5,
                            hasActivePass: user?.hasActivePass ?? false,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Voice-Match Card with Lavender-to-Peach Gradient (Requested by user)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                      decoration: BoxDecoration(
                        gradient: AaraColors.matchCardGradient, // Lavender (#F0E8FF) to Peach (#FFE9E1)
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AaraColors.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AaraColors.plumViolet.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Hero Animated Voice Pulse Circle
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 170,
                                  height: 170,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: AaraColors.plumViolet.withValues(alpha: 0.35), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AaraColors.plumViolet.withValues(alpha: 0.16),
                                        blurRadius: 32,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.graphic_eq,
                                      size: 64,
                                      color: AaraColors.plumViolet, // Plum violet
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),
                          // Deep aubergine heading (#261D30)
                          const Text(
                            'One-Minute Voice Matching',
                            style: AaraTypography.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // Muted purple-grey body (#62586B)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Speak with someone new across India in a private 60-second voice call. If both agree, keep chatting.',
                              style: AaraTypography.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Solid Plum "Start Voice Match" Button with White Text (Requested by user)
                    AaraButton(
                      text: 'Start Voice Match',
                      icon: Icons.mic,
                      variant: AaraButtonVariant.primary,
                      onPressed: _startVoiceMatch,
                    ),

                    const SizedBox(height: 10),
                    Text(
                      'Unanswered or cancelled matches use 0 credits.',
                      style: AaraTypography.labelSmall.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: Colors.white,
        selectedItemColor: AaraColors.plumViolet, // Plum violet (#6844A6)
        unselectedItemColor: AaraColors.textSecondary, // Muted purple-grey (#62586B)
        elevation: 8,
        onTap: (index) {
          if (index == 1) context.go('/friends');
          if (index == 2) context.go('/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'Match'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
