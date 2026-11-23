import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/network/api_client.dart';
import '../../core/providers/auth_provider.dart';

class PlusSubscriptionScreen extends ConsumerStatefulWidget {
  const PlusSubscriptionScreen({super.key});

  @override
  ConsumerState<PlusSubscriptionScreen> createState() => _PlusSubscriptionScreenState();
}

class _PlusSubscriptionScreenState extends ConsumerState<PlusSubscriptionScreen> {
  final ApiClient _client = ApiClient();
  bool _isLoading = false;

  Future<void> _handleSubscribe() async {
    setState(() => _isLoading = true);
    try {
      await _client.post('/plus/subscribe');
      ref.read(authProvider.notifier).setPlusSubscriber(true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Congratulations! You are now a FriendLoop Plus member!'),
          backgroundColor: FriendLoopColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: FriendLoopColors.rose),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Plus',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FriendLoopColors.plum),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Plus Card from Mockup
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: FriendLoopColors.lavender),
                  boxShadow: [
                    BoxShadow(
                      color: FriendLoopColors.violet.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Infinity Logo
                    Image.asset(
                      'assets/images/friendloop_logo.png',
                      height: 60,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.all_inclusive_rounded,
                        color: FriendLoopColors.violet,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '₹350/month',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: FriendLoopColors.plum,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'One membership for eligible\nprofile galleries across profiles',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: FriendLoopColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildFeatureRow('🔓 Unlock private photos & videos'),
                    const SizedBox(height: 10),
                    _buildFeatureRow('✨ Unlimited profile gallery browsing'),
                    const SizedBox(height: 10),
                    _buildFeatureRow('👑 Exclusive Plus badge on your profile'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Subscribe Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FriendLoopColors.violet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Subscribe for ₹350/month',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Renews monthly until canceled',
                style: TextStyle(fontSize: 12, color: FriendLoopColors.textMuted),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checking app store purchases...')),
                  );
                },
                child: const Text(
                  'Restore purchase',
                  style: TextStyle(color: FriendLoopColors.violet, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FriendLoopColors.plum),
          ),
        ),
      ],
    );
  }
}
