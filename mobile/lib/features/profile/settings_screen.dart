import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: FriendLoopColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FriendLoopColors.plum),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            _buildSettingsItem(
              icon: Icons.lock_outline,
              title: 'Privacy',
              subtitle: 'Online status, profile visibility',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy settings are active')));
              },
            ),
            _buildSettingsItem(
              icon: Icons.block,
              title: 'Blocked Users',
              subtitle: 'Manage blocked profiles',
              onTap: () => context.push('/blocked-users'),
            ),
            _buildSettingsItem(
              icon: Icons.star_outline,
              title: 'FriendLoop Plus',
              subtitle: 'Manage your ₹350/mo membership',
              onTap: () => context.push('/plus'),
            ),
            _buildSettingsItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Coin Wallet',
              subtitle: 'Recharge coins, transaction history',
              onTap: () => context.push('/wallet'),
            ),
            _buildSettingsItem(
              icon: Icons.help_outline,
              title: 'Help & FAQ',
              subtitle: 'Safe community rules, calling guides',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('FriendLoop Help Desk: 24/7 support active.')));
              },
            ),
            _buildSettingsItem(
              icon: Icons.report_problem_outlined,
              title: 'Report a Problem',
              subtitle: 'Report a bug or safety issue',
              onTap: () => context.push('/report-block'),
            ),
            const SizedBox(height: 24),

            // Sign Out Button
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: FriendLoopColors.rose),
              ),
              tileColor: Colors.white,
              leading: const Icon(Icons.logout, color: FriendLoopColors.rose),
              title: const Text(
                'Sign Out',
                style: TextStyle(fontWeight: FontWeight.bold, color: FriendLoopColors.rose),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out from FriendLoop?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: FriendLoopColors.rose),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(authProvider.notifier).logout();
                          context.go('/welcome');
                        },
                        child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FriendLoopColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: FriendLoopColors.violet),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: FriendLoopColors.plum)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: FriendLoopColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right, color: FriendLoopColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
