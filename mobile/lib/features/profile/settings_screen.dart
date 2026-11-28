import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/nav_helper.dart';

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
          onPressed: () => safePop(context, fallbackRoute: '/profile'),
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
            _buildSettingsItem(
              icon: Icons.shield_outlined,
              title: 'Child Safety Standards',
              subtitle: 'Zero tolerance, 18+ policy, designated contact',
              onTap: () => _showChildSafetyDialog(context),
            ),
            _buildSettingsItem(
              icon: Icons.delete_forever_outlined,
              title: 'Delete Account',
              subtitle: 'Permanently remove account & request deletion',
              onTap: () => _showDeleteAccountDialog(context, ref),
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

  void _showChildSafetyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: FriendLoopColors.violet),
            SizedBox(width: 8),
            Text('Child Safety Standards', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'FriendLoop enforces a strict 18+ age restriction and zero-tolerance policy against Child Sexual Abuse Material (CSAM) or Child Sexual Exploitation and Abuse (CSAE).',
                style: TextStyle(fontSize: 13, height: 1.4, color: FriendLoopColors.plum),
              ),
              const SizedBox(height: 12),
              const Text(
                'Key Safeguards:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FriendLoopColors.plum),
              ),
              const SizedBox(height: 6),
              const Text(
                '• Mandatory 18+ verification upon registration.\n'
                '• AI-powered automated media scanning and chat filtering.\n'
                '• 24/7 human moderation & immediate law enforcement (NCMEC) escalation.\n'
                '• In-app reporting and instant blocking available across all chats, reels, rooms, and profiles.',
                style: TextStyle(fontSize: 12, height: 1.35, color: FriendLoopColors.textSecondary),
              ),
              const SizedBox(height: 12),
              const Text(
                'Designated Child Safety Contact:\n'
                'safety@friendloop.app\n'
                'ops@aara.social',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FriendLoopColors.violet),
              ),
              const SizedBox(height: 12),
              Text(
                'Public Standards Webpage:\n${ApiEndpoints.rootUrl}/child-safety',
                style: const TextStyle(fontSize: 11, color: FriendLoopColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FriendLoopColors.violet),
            onPressed: () async {
              Navigator.pop(ctx);
              final url = Uri.parse('${ApiEndpoints.rootUrl}/child-safety');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Open Policy Page', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: FriendLoopColors.rose),
            SizedBox(width: 8),
            Text('Delete Account?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: FriendLoopColors.rose)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to delete your FriendLoop account? This action is permanent and cannot be undone.',
                style: TextStyle(fontSize: 13, height: 1.4, color: FriendLoopColors.plum),
              ),
              const SizedBox(height: 12),
              const Text(
                'What will be deleted:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: FriendLoopColors.plum),
              ),
              const SizedBox(height: 6),
              const Text(
                '• Your profile, photos, and personal information.\n'
                '• All chat history, friendships, and messages.\n'
                '• All uploaded reels and room interactions.\n'
                '• Unused coin balances and subscriptions are permanently forfeited.',
                style: TextStyle(fontSize: 12, height: 1.35, color: FriendLoopColors.textSecondary),
              ),
              const SizedBox(height: 12),
              const Text(
                'Data Retention Policy:\n'
                'Certain transaction logs and safety compliance records may be retained for up to 180 days to comply with applicable statutory laws and prevent fraud.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: FriendLoopColors.textMuted),
              ),
              const SizedBox(height: 10),
              Text(
                'Public Account Deletion URL (accessible without app):\n${ApiEndpoints.rootUrl}/delete-account',
                style: const TextStyle(fontSize: 11, color: FriendLoopColors.violet),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FriendLoopColors.rose),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final client = ApiClient();
                await client.post('/moderation/delete-account');
                ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Your account and associated data have been permanently deleted.'),
                      backgroundColor: FriendLoopColors.rose,
                    ),
                  );
                  context.go('/welcome');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Account deletion failed: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Permanently Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
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
