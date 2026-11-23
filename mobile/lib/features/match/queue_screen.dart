import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/aara_button.dart';
import '../../shared/widgets/aara_card.dart';
import '../../shared/widgets/aara_badge.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/match_provider.dart';
import '../../core/providers/call_provider.dart';

class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(matchProvider);
    final user = ref.watch(authProvider).currentUserProfile;

    // Listen for match found event
    ref.listen<MatchState>(matchProvider, (prev, next) {
      if (next.matchedSession != null) {
        ref.read(callProvider.notifier).startSession(next.matchedSession!);
        context.go('/call');
      }
    });

    return Scaffold(
      backgroundColor: AaraColors.background,
      appBar: AppBar(
        title: const Text('Searching for Match'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              AaraAllowanceBadge(
                remaining: user?.freeCallsRemaining ?? 5,
                hasActivePass: user?.hasActivePass ?? false,
              ),

              const Spacer(),

              // Radar Pulser
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ...List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _radarController,
                        builder: (context, child) {
                          final value = (_radarController.value + (index / 3.0)) % 1.0;
                          return Container(
                            width: 220 * value,
                            height: 220 * value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AaraColors.champagne.withOpacity((1.0 - value) * 0.4),
                                width: 1.5,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AaraColors.surfaceCard,
                        boxShadow: [
                          BoxShadow(
                            color: AaraColors.pulseGlow,
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.graphic_eq, color: AaraColors.champagneLight, size: 36),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Text(
                matchState.allowAnyLanguage
                    ? 'Matching across all languages...'
                    : 'Matching with someone who speaks ${user?.languages.first ?? "your language"}...',
                style: AaraTypography.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Wait time: ${matchState.waitTimeSeconds}s',
                style: AaraTypography.labelSmall.copyWith(color: AaraColors.champagneLight),
              ),

              const Spacer(),

              // Broaden languages option
              if (!matchState.allowAnyLanguage) ...[
                AaraCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.translate, size: 20, color: AaraColors.champagneLight),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Broaden Languages?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('Connect faster with speakers across India', style: AaraTypography.labelSmall),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(matchProvider.notifier).broadenLanguages();
                        },
                        child: const Text('Broaden', style: TextStyle(color: AaraColors.champagneLight)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Cancel button (Safe cancellation, zero credits consumed)
              AaraButton(
                text: 'Cancel Search',
                variant: AaraButtonVariant.secondary,
                onPressed: () async {
                  await ref.read(matchProvider.notifier).cancelQueue();
                  if (context.mounted) context.go('/match');
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Cancelling preserves all your call credits.',
                style: AaraTypography.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
