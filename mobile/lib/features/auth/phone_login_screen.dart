import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/aara_button.dart';
import '../../shared/widgets/aara_card.dart';
import '../../shared/widgets/aara_text_field.dart';
import '../../core/providers/auth_provider.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  int _resendCountdown = 30;
  Timer? _resendTimer;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendCountdown = 30);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number');
      return;
    }
    setState(() => _errorMessage = null);

    try {
      await ref.read(authProvider.notifier).sendOtp(phone);
      setState(() {
        _otpSent = true;
        _otpController.text = '123456'; // Pre-fill simulated OTP for fast testing
      });
      _startResendTimer();
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _handleVerifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit code');
      return;
    }
    setState(() => _errorMessage = null);

    try {
      await ref.read(authProvider.notifier).verifyOtp(phone, otp);
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (auth.profileComplete) {
        context.go('/match');
      } else {
        context.go('/profile-setup');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _fillDemoUser(String phone) {
    _phoneController.text = phone;
    _handleSendOtp();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AaraColors.background,
      appBar: AppBar(
        title: const Text('Phone Sign In'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _otpSent ? 'Enter Verification Code' : 'Welcome to Aara',
                style: AaraTypography.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? 'Enter the 6-digit code sent to +91 ${_phoneController.text.trim()}'
                    : 'Enter your Indian mobile number. We will send an OTP.',
                style: AaraTypography.bodyMedium,
              ),
              const SizedBox(height: 28),

              // Demo quick testing card
              AaraCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.science_outlined, color: AaraColors.champagneLight, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'DEMO MODE (Simulated OTP: 123456)',
                          style: AaraTypography.labelSmall.copyWith(
                            color: AaraColors.champagneLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AaraColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () => _fillDemoUser('9876543210'),
                            child: const Text('Aarav (A)', style: TextStyle(color: AaraColors.champagneLight)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AaraColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () => _fillDemoUser('9876543211'),
                            child: const Text('Priya (B)', style: TextStyle(color: AaraColors.champagneLight)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (!_otpSent) ...[
                AaraTextField(
                  controller: _phoneController,
                  label: 'Indian Mobile Number',
                  prefixText: '+91 ',
                  hint: '98765 43210',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                AaraButton(
                  text: 'Send OTP',
                  isLoading: authState.isLoading,
                  onPressed: _handleSendOtp,
                ),
              ] else ...[
                AaraTextField(
                  controller: _otpController,
                  label: '6-Digit Verification Code',
                  hint: '123456',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _otpSent = false),
                      child: const Text('Edit Phone Number', style: TextStyle(color: AaraColors.textSecondary)),
                    ),
                    TextButton(
                      onPressed: _resendCountdown == 0 ? _handleSendOtp : null,
                      child: Text(
                        _resendCountdown > 0 ? 'Resend in ${_resendCountdown}s' : 'Resend OTP',
                        style: TextStyle(
                          color: _resendCountdown == 0 ? AaraColors.champagneLight : AaraColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AaraButton(
                  text: 'Verify & Enter',
                  isLoading: authState.isLoading,
                  onPressed: _handleVerifyOtp,
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AaraColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AaraColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AaraColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AaraTypography.bodyMedium.copyWith(color: const Color(0xFFFF9E9B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
