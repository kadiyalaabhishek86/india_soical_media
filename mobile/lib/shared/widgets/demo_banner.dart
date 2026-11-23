import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/friends_provider.dart';

class DemoModeBanner extends ConsumerWidget {
  const DemoModeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF0E8FF), // Soft lavender
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8DFEB), width: 1), // Pale lilac-grey
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6844A6), // Plum violet
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'DEMO MODE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Simulated SMS & Media: ${authState.currentUserProfile?.displayName ?? "Not Signed In"}',
                style: AaraTypography.labelSmall.copyWith(color: AaraColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 20, color: Color(0xFF6844A6)),
              tooltip: 'Admin Console (/admin)',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => context.push('/admin'),
            ),
            PopupMenuButton<String>(
              tooltip: 'Switch Demo User',
              icon: const Icon(Icons.swap_horiz, size: 20, color: Color(0xFF6844A6)),
              color: Colors.white,
              onSelected: (user) async {
                await ref.read(authProvider.notifier).switchDemoUser(user);
                await ref.read(friendsProvider.notifier).fetchFriends();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'aarav',
                  child: Text('User A: Aarav (Maharashtra)', style: TextStyle(color: AaraColors.textPrimary)),
                ),
                const PopupMenuItem(
                  value: 'priya',
                  child: Text('User B: Priya (Karnataka)', style: TextStyle(color: AaraColors.textPrimary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
