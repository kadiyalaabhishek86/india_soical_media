import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/auth_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _phoneController = TextEditingController();
  final _adminUsernameController = TextEditingController(text: 'admin');
  final _adminPasswordController = TextEditingController(text: 'Admin@12345');
  final _adminMfaController = TextEditingController();

  bool _isAdminMode = false;
  bool _adminNeedsMfa = false;
  String? _adminTempToken;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    _adminMfaController.dispose();
    super.dispose();
  }

  Future<void> _handleUserContinue() async {
    final raw = _phoneController.text.trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number');
      return;
    }
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final phone = '+91${digits.substring(digits.length - 10)}';
      await ref.read(authProvider.notifier).sendOtp(phone);
      if (!mounted) return;
      context.push('/verify-otp', extra: phone);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAdminLogin() async {
    final username = _adminUsernameController.text.trim();
    final password = _adminPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Username and password are required.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final res = await ref.read(authProvider.notifier).adminLogin(username, password);
      if (res['requires_mfa'] == true) {
        setState(() {
          _adminNeedsMfa = true;
          _adminTempToken = res['token'];
          _adminMfaController.text = '123456'; // Preset demo MFA
        });
      } else {
        if (!mounted) return;
        context.go('/admin');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAdminMfa() async {
    final code = _adminMfaController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter 6-digit MFA code.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).adminVerifyMfa(_adminTempToken ?? '', code);
      if (!mounted) return;
      context.go('/admin');
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FriendLoopColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  // Infinity Icon Logo
                  Center(
                    child: Image.asset(
                      'assets/images/friendloop_logo.png',
                      height: 64,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.all_inclusive_rounded,
                        size: 64,
                        color: FriendLoopColors.violet,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Make real friends\nacross India',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: FriendLoopColors.plum,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Group Photo Card (from mockup)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/telegram/wallpaper_sample.png',
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 170,
                        decoration: BoxDecoration(
                          color: FriendLoopColors.lavender,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.people_alt_rounded, size: 64, color: FriendLoopColors.violet),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mode toggle (User vs Admin Login)
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        _isAdminMode ? 'Staff & Admin Sign In' : 'Welcome',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: FriendLoopColors.plum,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isAdminMode = !_isAdminMode;
                            _adminNeedsMfa = false;
                            _errorMessage = null;
                          });
                        },
                        icon: Icon(
                          _isAdminMode ? Icons.person : Icons.admin_panel_settings_outlined,
                          size: 18,
                          color: FriendLoopColors.violet,
                        ),
                        label: Text(
                          _isAdminMode ? 'User Sign In' : 'Admin Sign In',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: FriendLoopColors.violet,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: FriendLoopColors.rose.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FriendLoopColors.rose),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: FriendLoopColors.rose, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (!_isAdminMode) ...[
                    // Phone Number Input (India +91)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FriendLoopColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            decoration: const BoxDecoration(
                              border: Border(right: BorderSide(color: FriendLoopColors.border)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🇮🇳', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 4),
                                Text(
                                  'India +91',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: FriendLoopColors.plum,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: 'Enter phone number',
                                hintStyle: TextStyle(color: FriendLoopColors.textMuted, fontSize: 14),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleUserContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FriendLoopColors.violet,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Demo Switchers for Fast Verification
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ActionChip(
                          avatar: const CircleAvatar(
                            radius: 10,
                            backgroundColor: FriendLoopColors.lavender,
                            child: Text('A', style: TextStyle(fontSize: 10, color: FriendLoopColors.violet, fontWeight: FontWeight.bold)),
                          ),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: FriendLoopColors.lavender),
                          label: const Text('Aarav (+91 98765 43210)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          onPressed: () async {
                            _phoneController.text = '9876543210';
                            setState(() => _isLoading = true);
                            try {
                              await ref.read(authProvider.notifier).switchDemoUser('aarav');
                              if (mounted) context.go('/home');
                            } catch (_) {
                              if (mounted) _handleUserContinue();
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                        ),
                        ActionChip(
                          avatar: const CircleAvatar(
                            radius: 10,
                            backgroundColor: FriendLoopColors.lavender,
                            child: Text('P', style: TextStyle(fontSize: 10, color: FriendLoopColors.violet, fontWeight: FontWeight.bold)),
                          ),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: FriendLoopColors.lavender),
                          label: const Text('Priya (+91 98765 43211)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          onPressed: () async {
                            _phoneController.text = '9876543211';
                            setState(() => _isLoading = true);
                            try {
                              await ref.read(authProvider.notifier).switchDemoUser('priya');
                              if (mounted) context.go('/home');
                            } catch (_) {
                              if (mounted) _handleUserContinue();
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                        ),
                      ],
                    ),
                  ] else ...[
                // Admin login form
                if (!_adminNeedsMfa) ...[
                  TextField(
                    controller: _adminUsernameController,
                    decoration: InputDecoration(
                      labelText: 'Staff Username',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FriendLoopColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _adminPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FriendLoopColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAdminLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FriendLoopColors.plum,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Sign In as Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  // MFA Form
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FriendLoopColors.lavender),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MFA Verification',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FriendLoopColors.plum),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter your 6-digit authenticator code (or demo 123456)',
                          style: TextStyle(fontSize: 13, color: FriendLoopColors.textSecondary),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _adminMfaController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: FriendLoopColors.canvas,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAdminMfa,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FriendLoopColors.violet,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Verify & Enter Console', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
