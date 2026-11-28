import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/network/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/coin_billing.dart';
import '../../core/utils/nav_helper.dart';

class WalletScreen extends ConsumerStatefulWidget {
  final PendingCoinAction? pendingAction;

  const WalletScreen({super.key, this.pendingAction});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final ApiClient _client = ApiClient();
  int _historyTab = 0; // 0 = All, 1 = Purchases, 2 = Call Usage
  bool _isLoading = true;
  bool _showAllPacks = false;
  List<dynamic> _transactions = [];

  static const List<Map<String, dynamic>> _packs = [
    {
      'id': 'pack_40',
      'coins': 40,
      'formattedCoins': '40',
      'price_inr': 9.00,
      'badge': null,
    },
    {
      'id': 'pack_100',
      'coins': 100,
      'formattedCoins': '100',
      'price_inr': 19.00,
      'badge': null,
    },
    {
      'id': 'pack_275',
      'coins': 275,
      'formattedCoins': '275',
      'price_inr': 49.00,
      'badge': null,
    },
    {
      'id': 'pack_600',
      'coins': 600,
      'formattedCoins': '600',
      'price_inr': 99.00,
      'badge': null,
    },
    {
      'id': 'pack_1250',
      'coins': 1250,
      'formattedCoins': '1,250',
      'price_inr': 199.00,
      'badge': null,
    },
    {
      'id': 'pack_3300',
      'coins': 3300,
      'formattedCoins': '3,300',
      'price_inr': 499.00,
      'badge': 'Best value',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    try {
      final res = await _client.get('/wallet/balance');
      if (mounted) {
        setState(() {
          _transactions = List<dynamic>.from(res['transactions'] ?? []);
          _isLoading = false;
        });
        if (res['coins'] != null) {
          ref.read(authProvider.notifier).updateCoins(res['coins']);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPurchaseConfirm(Map<String, dynamic> pack) {
    String selectedMethod = 'google_play'; // Default to Google Play Billing

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
                  'Choose Payment Option',
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        '${pack['formattedCoins']} Coins — ₹${(pack['price_inr'] as num).toInt()}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FriendLoopColors.plum),
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
                                  'Google Play Billing',
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
                              'Pay with Google Play balance, UPI, cards, or netbanking. Buyer protection included.',
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
                              'Direct checkout via Razorpay (GPay, PhonePe, Paytm, BHIM, Cards, Netbanking).',
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

              // Purchase Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      final res = await _client.post(
                        '/wallet/buy',
                        body: {
                          'pack_id': pack['id'],
                          'coins': pack['coins'],
                          'price_inr': pack['price_inr'],
                          'payment_method': selectedMethod,
                        },
                      );
                      if (res['coins'] != null) {
                        ref.read(authProvider.notifier).updateCoins(res['coins']);
                      }
                      _fetchWallet();
                      if (!mounted) return;
                      final providerLabel = selectedMethod == 'google_play' ? 'Google Play Billing' : 'Razorpay';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment via $providerLabel successful! Added ${pack['formattedCoins']} coins! 🪙'),
                          backgroundColor: FriendLoopColors.success,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: FriendLoopColors.rose),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FriendLoopColors.violet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    selectedMethod == 'google_play'
                        ? 'Pay ₹${(pack['price_inr'] as num).toInt()} with Google Play'
                        : 'Pay ₹${(pack['price_inr'] as num).toInt()} with Razorpay',
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

  List<dynamic> _getFilteredTransactions() {
    if (_transactions.isEmpty) {
      if (_historyTab == 0) {
        return [
          {
            'amount': 120,
            'description': 'Welcome to FriendLoop bonus!',
            'transaction_type': 'bonus',
            'is_welcome': true,
          }
        ];
      }
      return [];
    }

    if (_historyTab == 1) {
      return _transactions.where((t) => (t['transaction_type'] ?? '') == 'purchase').toList();
    } else if (_historyTab == 2) {
      return _transactions.where((t) => (t['transaction_type'] ?? '') == 'call_usage' || (t['transaction_type'] ?? '') == 'usage').toList();
    }
    return _transactions;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUserProfile;
    final coins = user?.coins ?? 120;
    final isPlus = user?.isPlusSubscriber ?? false;
    final voiceRate = CoinBilling.costForAction(CoinActionType.voice, isPlus: isPlus);
    final videoRate = CoinBilling.costForAction(CoinActionType.video, isPlus: isPlus);
    final chatRate = CoinBilling.costForAction(CoinActionType.chat, isPlus: isPlus);
    final pending = widget.pendingAction;
    final pendingCost = pending != null
        ? CoinBilling.costForAction(pending.actionType, isPlus: isPlus)
        : 0;
    final displayedPacks = _showAllPacks ? _packs : _packs.take(3).toList();
    final filteredHistory = _getFilteredTransactions();

    return Scaffold(
      backgroundColor: FriendLoopColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
          onPressed: () => safePop(context),
        ),
        title: const Text(
          'Coin Wallet',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FriendLoopColors.plum),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pending != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: coins >= pendingCost ? const Color(0xFFEAFBF0) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: coins >= pendingCost ? FriendLoopColors.success : FriendLoopColors.violet,
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coins >= pendingCost
                            ? 'Coins Verified for ${pending.actionLabel}!'
                            : '${pending.actionLabel} requires $pendingCost coins (${CoinBilling.planLabel(isPlus)})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: FriendLoopColors.plum,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coins >= pendingCost
                            ? 'Your balance ($coins coins) covers the $pendingCost coin plan deduction.'
                            : 'You currently have $coins coins. Add coins below, then continue.',
                        style: const TextStyle(fontSize: 12, color: FriendLoopColors.textSecondary),
                      ),
                      if (coins >= pendingCost) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(authProvider.notifier).updateCoins(coins - pendingCost);
                              if (pending.actionType == CoinActionType.voice) {
                                context.pushReplacement('/call', extra: pending.friend);
                              } else if (pending.actionType == CoinActionType.video) {
                                context.pushReplacement('/call/video', extra: pending.friend);
                              } else {
                                final chatId = pending.chatRouteId ?? pending.friend?.friendshipId ?? '';
                                context.pushReplacement('/chat/$chatId', extra: pending.friend);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FriendLoopColors.violet,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Start ${pending.actionLabel} (-$pendingCost coins)'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              // Balance Hero Card matching FriendLoop mockup
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A1080), Color(0xFF2B094C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF350D4D).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Available balance',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFDF6B), Color(0xFFFFA800)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.account_balance, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$coins',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'coins',
                            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${CoinBilling.planLabel(isPlus)}: Voice ${voiceRate}c/m · Video ${videoRate}c/m · Chat ${chatRate}c',
                        style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (!isPlus) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => context.push('/plus'),
                        child: const Text(
                          'Upgrade to Plus for 50% off coin rates ›',
                          style: TextStyle(
                            color: FriendLoopColors.gold,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Buy Coins Section
              const Text(
                'Buy Coins',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: FriendLoopColors.plum),
              ),
              const SizedBox(height: 12),

              // Dynamic Coin Packs list (3 collapsed, 6 expanded)
              ...displayedPacks.map((p) {
                final hasBadge = p['badge'] != null;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: FriendLoopColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFF7DC),
                          border: Border.all(color: const Color(0xFFFFD56B), width: 1.5),
                        ),
                        child: const Center(
                          child: Text('🪙', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '${p['formattedCoins']} coins',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: FriendLoopColors.plum),
                            ),
                            if (hasBadge) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8634D2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  p['badge'],
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showPurchaseConfirm(p),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FriendLoopColors.violet,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          minimumSize: const Size(64, 36),
                          elevation: 0,
                        ),
                        child: Text(
                          '₹${(p['price_inr'] as num).toInt()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),

              // Show more / Show less Outlined Button
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showAllPacks = !_showAllPacks;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE0C7FA), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    backgroundColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showAllPacks ? 'Show less' : 'Show more',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: FriendLoopColors.violet,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showAllPacks ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18,
                        color: FriendLoopColors.violet,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Coin History Header
              const Text(
                'Coin History',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: FriendLoopColors.plum),
              ),
              const SizedBox(height: 10),

              // Filter tabs: All, Purchases, Call Usage
              Row(
                children: [
                  _buildHistoryTab('All', 0),
                  const SizedBox(width: 8),
                  _buildHistoryTab('Purchases', 1),
                  const SizedBox(width: 8),
                  _buildHistoryTab('Call Usage', 2),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else if (filteredHistory.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No transaction history', style: TextStyle(color: FriendLoopColors.textMuted)),
                  ),
                )
              else
                ...filteredHistory.map((t) {
                  final amount = t['amount'] ?? 0;
                  final isPositive = amount > 0;
                  final desc = t['description'] ?? 'Transaction';
                  final isWelcome = t['is_welcome'] == true || desc.toLowerCase().contains('bonus');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: FriendLoopColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(isWelcome ? '🎁 ' : (isPositive ? '🪙 ' : '📞 '), style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              desc,
                              style: const TextStyle(fontSize: 13, color: FriendLoopColors.plum, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Text(
                          '${isPositive ? '+' : ''}$amount coins',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? FriendLoopColors.onlineGreen : FriendLoopColors.rose,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab(String label, int index) {
    final isSelected = _historyTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _historyTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? FriendLoopColors.lavender : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? FriendLoopColors.violet : FriendLoopColors.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? FriendLoopColors.violet : FriendLoopColors.plum,
            ),
          ),
        ),
      ),
    );
  }
}
