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

  void _showPaymentMethodChooser() {
    String selectedMethod = 'google_play';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Center(
                child: Text(
                  'Choose Subscription Billing',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FriendLoopColors.plum),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: FriendLoopColors.lavender.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: FriendLoopColors.violet, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'FriendLoop Plus — ₹350/month',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FriendLoopColors.plum),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'In accordance with Google Play’s User Choice Billing program for India, you may choose Google Play Billing or an alternative payment method:',
                style: TextStyle(fontSize: 11, color: FriendLoopColors.textMuted, height: 1.35),
              ),
              const SizedBox(height: 14),

              // Option 1: Google Play Billing
              GestureDetector(
                onTap: () => setSheetState(() => selectedMethod = 'google_play'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selectedMethod == 'google_play' ? FriendLoopColors.lavender.withValues(alpha: 0.3) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedMethod == 'google_play' ? FriendLoopColors.violet : FriendLoopColors.border,
                      width: selectedMethod == 'google_play' ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'google_play',
                        groupValue: selectedMethod,
                        activeColor: FriendLoopColors.violet,
                        onChanged: (v) => setSheetState(() => selectedMethod = v!),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Google Play Subscription',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FriendLoopColors.plum),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: FriendLoopColors.violet.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('Play Store', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FriendLoopColors.violet)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Auto-renews monthly. Easily cancel or manage in Google Play > Subscriptions.',
                              style: TextStyle(fontSize: 11, color: FriendLoopColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Option 2: Alternative Billing (Razorpay India)
              GestureDetector(
                onTap: () => setSheetState(() => selectedMethod = 'alternative_razorpay'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selectedMethod == 'alternative_razorpay' ? FriendLoopColors.lavender.withValues(alpha: 0.3) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedMethod == 'alternative_razorpay' ? FriendLoopColors.violet : FriendLoopColors.border,
                      width: selectedMethod == 'alternative_razorpay' ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'alternative_razorpay',
                        groupValue: selectedMethod,
                        activeColor: FriendLoopColors.violet,
                        onChanged: (v) => setSheetState(() => selectedMethod = v!),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Alternative Billing (Razorpay)',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FriendLoopColors.plum),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('UPI & Cards', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Direct checkout via Razorpay (UPI AutoPay, Debit/Credit Card, Netbanking).',
                              style: TextStyle(fontSize: 11, color: FriendLoopColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _executeSubscription(selectedMethod);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FriendLoopColors.violet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    selectedMethod == 'google_play'
                        ? 'Subscribe ₹350/mo with Google Play'
                        : 'Subscribe ₹350/mo with Razorpay',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeSubscription(String paymentMethod) async {
    setState(() => _isLoading = true);
    try {
      await _client.post(
        '/plus/subscribe',
        body: {'payment_method': paymentMethod},
      );
      ref.read(authProvider.notifier).setPlusSubscriber(true);
      if (!mounted) return;
      final label = paymentMethod == 'google_play' ? 'Google Play' : 'Razorpay';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Subscribed via $label! Welcome to FriendLoop Plus!'),
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
                  onPressed: _isLoading ? null : _showPaymentMethodChooser,
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
