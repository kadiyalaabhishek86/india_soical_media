import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/network/api_client.dart';
import '../../core/providers/auth_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final ApiClient _client = ApiClient();
  int _historyTab = 0; // 0 = All, 1 = Purchases, 2 = Call Usage
  bool _isLoading = true;
  List<dynamic> _transactions = [];

  static const List<Map<String, dynamic>> _packs = [
    {
      'id': 'pack_40',
      'coins': 40,
      'price_inr': 9.00,
      'badge': null,
    },
    {
      'id': 'pack_100',
      'coins': 100,
      'price_inr': 19.00,
      'badge': 'MOST POPULAR',
    },
    {
      'id': 'pack_275',
      'coins': 275,
      'price_inr': 49.00,
      'badge': 'BEST VALUE',
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Confirm Purchase',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FriendLoopColors.plum),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  '${pack['coins']} Coins',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: FriendLoopColors.plum),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Amount to pay: ₹${(pack['price_inr'] as num).toInt()}',
              style: const TextStyle(fontSize: 15, color: FriendLoopColors.textSecondary),
            ),
            const SizedBox(height: 24),
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
                      },
                    );
                    if (res['coins'] != null) {
                      ref.read(authProvider.notifier).updateCoins(res['coins']);
                    }
                    _fetchWallet();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Successfully added ${pack['coins']} coins! 🪙'),
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
                child: const Text('Pay with UPI / Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUserProfile;
    final coins = user?.coins ?? 120;

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
              // Balance Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  gradient: FriendLoopColors.plumGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: FriendLoopColors.plum.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 10),
                        Text(
                          '$coins',
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Coins', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Voice: 10 coins/min • Video: 40 coins/min',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Coin Packs
              const Text(
                'Buy Coins',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: FriendLoopColors.plum),
              ),
              const SizedBox(height: 12),
              ..._packs.map((p) {
                final hasBadge = p['badge'] != null;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasBadge ? FriendLoopColors.violet : FriendLoopColors.border,
                      width: hasBadge ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: FriendLoopColors.lavender,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('🪙', style: TextStyle(fontSize: 22))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasBadge) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: FriendLoopColors.violet,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  p['badge'],
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            Text(
                              '${p['coins']} Coins',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FriendLoopColors.plum),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showPurchaseConfirm(p),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FriendLoopColors.violet,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
              const SizedBox(height: 20),

              // Coin History Header
              const Text(
                'Coin History',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: FriendLoopColors.plum),
              ),
              const SizedBox(height: 10),
              // Filter tabs
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
              else if (_transactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No transaction history', style: TextStyle(color: FriendLoopColors.textMuted)),
                  ),
                )
              else
                ..._transactions.map((t) {
                  final amount = t['amount'] ?? 0;
                  final isPositive = amount > 0;
                  final desc = t['description'] ?? 'Transaction';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FriendLoopColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            desc,
                            style: const TextStyle(fontSize: 13, color: FriendLoopColors.plum, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '${isPositive ? '+' : ''}$amount 🪙',
                          style: TextStyle(
                            fontSize: 14,
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
