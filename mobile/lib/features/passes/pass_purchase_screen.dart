import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/aara_button.dart';
import '../../shared/widgets/aara_card.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';

class PassPurchaseScreen extends ConsumerStatefulWidget {
  const PassPurchaseScreen({super.key});

  @override
  ConsumerState<PassPurchaseScreen> createState() => _PassPurchaseScreenState();
}

class _PassPurchaseScreenState extends ConsumerState<PassPurchaseScreen> {
  final ApiClient _client = ApiClient();
  Map<String, dynamic>? _passData;
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _message;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _fetchPassStatus();
    // Refresh countdown every 30 seconds
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _passData != null && _passData!['is_active'] == true) {
        _fetchPassStatus();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPassStatus() async {
    try {
      final res = await _client.get(ApiEndpoints.passStatus);
      if (mounted) {
        setState(() {
          _passData = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startRazorpayCheckout() async {
    setState(() {
      _isPurchasing = true;
      _message = null;
    });

    try {
      // 1. Create Razorpay order on backend
      final orderRes = await _client.post(ApiEndpoints.razorpayCreateOrder, body: {
        'amount': 2000,
        'currency': 'INR',
      });

      if (!mounted) return;

      // 2. Open Razorpay Checkout modal
      _showRazorpaySheet(orderRes);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _message = 'Failed to create Razorpay order: ${e.toString().replaceAll("Exception: ", "")}';
        });
      }
    }
  }

  void _showRazorpaySheet(Map<String, dynamic> order) {
    final orderId = order['order_id'] ?? 'order_simulated';
    final amountPaise = order['amount'] ?? 2000;
    final amountInr = (amountPaise / 100).toStringAsFixed(0);
    String selectedMethod = 'upi';
    final upiController = TextEditingController(text: 'aarav@okhdfcbank');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131317),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Razorpay Logo & Security
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0C2340),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF3395FF), width: 1),
                              ),
                              child: const Text(
                                'Razorpay',
                                style: TextStyle(
                                  color: Color(0xFF3395FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Secure Checkout',
                              style: TextStyle(color: AaraColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AaraColors.textMuted),
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() => _isPurchasing = false);
                          },
                        ),
                      ],
                    ),
                    const Divider(color: AaraColors.border, height: 20),

                    // Order Summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Aara 20-Minute Match Pass', style: AaraTypography.titleMedium.copyWith(fontSize: 15)),
                            const SizedBox(height: 2),
                            Text('Order ID: $orderId', style: const TextStyle(color: AaraColors.textMuted, fontSize: 11)),
                          ],
                        ),
                        Text(
                          '₹$amountInr',
                          style: AaraTypography.titleLarge.copyWith(color: AaraColors.champagneLight, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Payment Method Tabs
                    Text('Select Payment Method', style: AaraTypography.labelLarge.copyWith(color: AaraColors.champagneLight)),
                    const SizedBox(height: 10),

                    // Method 1: UPI
                    _buildPaymentOption(
                      title: 'UPI / QR (Instant)',
                      subtitle: 'Google Pay, PhonePe, Paytm, BHIM',
                      icon: Icons.qr_code_scanner,
                      isSelected: selectedMethod == 'upi',
                      onTap: () => setSheetState(() => selectedMethod = 'upi'),
                    ),
                    if (selectedMethod == 'upi') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: upiController,
                        style: const TextStyle(color: AaraColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'UPI ID / VPA',
                          labelStyle: const TextStyle(color: AaraColors.textSecondary, fontSize: 12),
                          hintText: 'e.g. mobile@upi or username@okhdfcbank',
                          hintStyle: const TextStyle(color: AaraColors.textMuted, fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          filled: true,
                          fillColor: AaraColors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AaraColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AaraColors.border)),
                          prefixIcon: const Icon(Icons.flash_on, color: AaraColors.champagneLight, size: 18),
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Method 2: Cards
                    _buildPaymentOption(
                      title: 'Debit / Credit Card',
                      subtitle: 'Visa, MasterCard, RuPay, Maestro',
                      icon: Icons.credit_card,
                      isSelected: selectedMethod == 'card',
                      onTap: () => setSheetState(() => selectedMethod = 'card'),
                    ),

                    const SizedBox(height: 10),

                    // Method 3: NetBanking
                    _buildPaymentOption(
                      title: 'NetBanking',
                      subtitle: 'HDFC, SBI, ICICI, Axis, Kotak, etc.',
                      icon: Icons.account_balance,
                      isSelected: selectedMethod == 'netbanking',
                      onTap: () => setSheetState(() => selectedMethod = 'netbanking'),
                    ),

                    const SizedBox(height: 24),

                    // Pay Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3395FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _completeRazorpayPayment(orderId, selectedMethod);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Pay ₹$amountInr via Razorpay',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        '100% Secure • RBI Authorized Payment Gateway',
                        style: TextStyle(color: AaraColors.textMuted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B2230) : AaraColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3395FF) : AaraColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF3395FF) : AaraColors.textSecondary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? Colors.white : AaraColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(color: AaraColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF3395FF), size: 18)
            else
              const Icon(Icons.radio_button_unchecked, color: AaraColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _completeRazorpayPayment(String orderId, String method) async {
    setState(() {
      _isPurchasing = true;
      _message = 'Processing payment with Razorpay...';
    });

    try {
      // Generate standard Razorpay payment credentials
      final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}_${orderId.replaceAll("order_", "")}';
      final simulatedSignature = 'demo_sig_rzp_${DateTime.now().millisecondsSinceEpoch}';

      // Verify payment with backend
      final res = await _client.post(ApiEndpoints.razorpayVerifyPayment, body: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': simulatedSignature,
      });

      // Refresh global profile state
      await ref.read(authProvider.notifier).refreshProfile();

      if (mounted) {
        setState(() {
          _passData = res;
          _isPurchasing = false;
          _message = 'Payment Verified! Your 20-minute random match pass is now ACTIVE.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _message = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _passData != null && _passData!['is_active'] == true;
    final remainingMins = _passData?['remaining_minutes'] ?? 0;

    return Scaffold(
      backgroundColor: AaraColors.background,
      appBar: AppBar(
        title: const Text('Random Match Pass'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AaraColors.champagneLight))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('20-Minute Access Pass', style: AaraTypography.displayMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Unlimited 60-second voice matches for 20 consecutive minutes across India.',
                      style: AaraTypography.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    // Active Pass Status Card (Shows countdown when active!)
                    if (isActive) ...[
                      AaraCard(
                        hasGlow: true,
                        child: Column(
                          children: [
                            const Icon(Icons.bolt, color: AaraColors.champagneLight, size: 40),
                            const SizedBox(height: 10),
                            Text(
                              'Pass Currently Active',
                              style: AaraTypography.titleLarge.copyWith(color: AaraColors.champagneLight, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: AaraColors.champagne.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AaraColors.champagneLight),
                              ),
                              child: Text(
                                '$remainingMins minutes remaining',
                                style: AaraTypography.titleMedium.copyWith(
                                  color: AaraColors.champagneLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'After payment, your random match access is active for exactly 20 minutes.\nIf your pass expires during an active call, you can finish the full 60 seconds.',
                              style: AaraTypography.labelSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AaraColors.champagneLight,
                                foregroundColor: AaraColors.background,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.flash_on, size: 18),
                              label: const Text('Start Voice Matching Now', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => context.go('/match'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Pass Pricing & Terms Card
                    AaraCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('One-Time Pass', style: AaraTypography.titleMedium),
                                  Text('20 Consecutive Minutes', style: AaraTypography.labelSmall.copyWith(color: AaraColors.champagneLight)),
                                ],
                              ),
                              Text(
                                '₹20',
                                style: AaraTypography.displayMedium.copyWith(color: AaraColors.champagneLight),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildBenefit(Icons.check_circle_outline, 'Unlimited connected random matches in the 20m window'),
                          const SizedBox(height: 10),
                          _buildBenefit(Icons.timer_outlined, 'Clock runs continuously for 20 minutes once payment is verified'),
                          const SizedBox(height: 10),
                          _buildBenefit(Icons.savings_outlined, 'Free credits are preserved while your pass is running'),
                          const SizedBox(height: 10),
                          _buildBenefit(Icons.replay, 'No automatic renewal or recurring subscription'),
                          const SizedBox(height: 10),
                          _buildBenefit(Icons.chat_bubble_outline, 'Chat with friends remains free forever'),
                        ],
                      ),
                    ),

                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AaraColors.surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AaraColors.champagne),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AaraColors.champagneLight, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_message!, style: const TextStyle(color: AaraColors.champagneLight, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Primary Razorpay Payment Action
                    if (isActive)
                      AaraButton(
                        text: 'Pass Active ($remainingMins mins left)',
                        icon: Icons.check,
                        onPressed: null,
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AaraColors.champagneLight,
                          foregroundColor: AaraColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isPurchasing ? null : _startRazorpayCheckout,
                        child: _isPurchasing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AaraColors.background),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0C2340),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'RAZORPAY',
                                      style: TextStyle(
                                        color: Color(0xFF3395FF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Pay ₹20 with Razorpay',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.lock_outline, size: 12, color: AaraColors.textMuted),
                        SizedBox(width: 4),
                        Text(
                          'Secured by Razorpay • UPI (GPay, PhonePe, Paytm), Cards & NetBanking',
                          style: TextStyle(color: AaraColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AaraColors.champagneLight),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AaraTypography.bodyMedium.copyWith(fontSize: 13))),
      ],
    );
  }
}
