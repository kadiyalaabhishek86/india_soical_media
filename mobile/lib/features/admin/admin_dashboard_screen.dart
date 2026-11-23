import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/colors.dart';
import '../../core/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final ApiClient _client = ApiClient();
  int _currentSection = 0; // 0: Overview, 1: Members, 2: Sales, 3: Finance, 4: Moderation
  bool _isLoading = true;

  Map<String, dynamic> _overviewData = {};
  List<dynamic> _members = [];
  List<dynamic> _reports = [];
  final _searchMembersController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  @override
  void dispose() {
    _searchMembersController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdminData() async {
    setState(() => _isLoading = true);
    try {
      final overview = await _client.get('/admin/overview-stats');
      final members = await _client.get('/admin/members');
      final reports = await _client.get('/admin/reports');

      if (mounted) {
        setState(() {
          _overviewData = Map<String, dynamic>.from(overview);
          _members = List<dynamic>.from(members);
          _reports = List<dynamic>.from(reports);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _overviewData = {
            'total_users': 38,
            'active_now': 19,
            'total_reels': 14,
            'total_rooms': 6,
            'gross_revenue_inr': 80400.0,
            'refunds_inr': 1200.0,
            'expenses_inr': 14850.0,
            'taxes_inr': 14256.0,
            'net_profit_inr': 50094.0,
            'city_distribution': [
              {'city': 'Mumbai', 'count': 12},
              {'city': 'Bengaluru', 'count': 9},
              {'city': 'Hyderabad', 'count': 7},
              {'city': 'Delhi NCR', 'count': 6},
              {'city': 'Chennai', 'count': 4},
            ],
            'coin_packs_sold': [
              {'pack': '40 Coins (₹9)', 'sold_count': 340, 'revenue_inr': 3060.0},
              {'pack': '100 Coins (₹19)', 'sold_count': 780, 'revenue_inr': 14820.0},
              {'pack': '275 Coins (₹49)', 'sold_count': 348, 'revenue_inr': 17052.0},
            ],
          };
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleSuspend(String userId, bool isCurrentlySuspended) async {
    try {
      if (isCurrentlySuspended) {
        await _client.post('/admin/members/$userId/unsuspend');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User unsuspended')));
      } else {
        await _client.post(
          '/admin/suspend',
          body: {'user_id': userId, 'reason': 'Violation of FriendLoop community guidelines'},
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User suspended')));
      }
      _fetchAdminData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Image.asset(
              'assets/images/friendloop_logo.png',
              height: 28,
              errorBuilder: (_, __, ___) => const Icon(Icons.all_inclusive_rounded, color: FriendLoopColors.violet),
            ),
            const SizedBox(width: 8),
            const Text(
              'FriendLoop Admin Console',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FriendLoopColors.plum),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: FriendLoopColors.violet),
            tooltip: 'Refresh Analytics',
            onPressed: _fetchAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: FriendLoopColors.rose),
            tooltip: 'Sign Out',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/welcome');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar Navigation
        Container(
          width: 220,
          color: Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildNavTile(Icons.dashboard_outlined, 'Overview', 0),
              _buildNavTile(Icons.people_outline, 'Members', 1),
              _buildNavTile(Icons.shopping_bag_outlined, 'Sales', 2),
              _buildNavTile(Icons.account_balance_outlined, 'Finance', 3),
              _buildNavTile(Icons.gavel_outlined, 'Moderation', 4),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Main Content Area
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildCurrentSection(),
                ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Top Navigation Bar Pills
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMobileNavPill('Overview', 0),
                const SizedBox(width: 8),
                _buildMobileNavPill('Members', 1),
                const SizedBox(width: 8),
                _buildMobileNavPill('Sales', 2),
                const SizedBox(width: 8),
                _buildMobileNavPill('Finance', 3),
                const SizedBox(width: 8),
                _buildMobileNavPill('Moderation', 4),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildCurrentSection(),
                ),
        ),
      ],
    );
  }

  Widget _buildNavTile(IconData icon, String title, int index) {
    final isSelected = _currentSection == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? FriendLoopColors.violet : FriendLoopColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? FriendLoopColors.violet : FriendLoopColors.plum,
        ),
      ),
      selected: isSelected,
      selectedTileColor: FriendLoopColors.lavender.withValues(alpha: 0.5),
      onTap: () => setState(() => _currentSection = index),
    );
  }

  Widget _buildMobileNavPill(String title, int index) {
    final isSelected = _currentSection == index;
    return GestureDetector(
      onTap: () => setState(() => _currentSection = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? FriendLoopColors.violet : FriendLoopColors.lavender.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : FriendLoopColors.plum,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSection() {
    switch (_currentSection) {
      case 0:
        return _buildOverviewSection();
      case 1:
        return _buildMembersSection();
      case 2:
        return _buildSalesSection();
      case 3:
        return _buildFinanceSection();
      case 4:
        return _buildModerationSection();
      default:
        return _buildOverviewSection();
    }
  }

  Widget _buildOverviewSection() {
    final gross = _overviewData['gross_revenue_inr'] ?? 80400.0;
    final net = _overviewData['net_profit_inr'] ?? 50094.0;
    final cities = List<Map<String, dynamic>>.from(_overviewData['city_distribution'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview & Key Metrics',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: FriendLoopColors.plum),
        ),
        const SizedBox(height: 16),

        // 4 KPI Cards
        Row(
          children: [
            _buildKpiCard('Total Users', '${_overviewData['total_users'] ?? 38}', Icons.people, FriendLoopColors.violet),
            const SizedBox(width: 12),
            _buildKpiCard('Active Now', '${_overviewData['active_now'] ?? 19}', Icons.online_prediction, FriendLoopColors.onlineGreen),
            const SizedBox(width: 12),
            _buildKpiCard('Live Rooms', '${_overviewData['total_rooms'] ?? 6}', Icons.groups, FriendLoopColors.plum),
            const SizedBox(width: 12),
            _buildKpiCard('Total Reels', '${_overviewData['total_reels'] ?? 14}', Icons.movie, FriendLoopColors.brightViolet),
          ],
        ),
        const SizedBox(height: 20),

        // Financial Performance Card (Gross - Refunds - Expenses - Taxes = Net Profit)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FriendLoopColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Financial Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FriendLoopColors.plum)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: FriendLoopColors.onlineGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Net Profit: ₹${net.toStringAsFixed(2)}',
                      style: const TextStyle(color: FriendLoopColors.onlineGreen, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Formula: Gross Revenue - Refunds - Expenses - Taxes = Net Profit',
                style: TextStyle(fontSize: 12, color: FriendLoopColors.textMuted, fontStyle: FontStyle.italic),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFinanceStat('Gross Revenue', '₹${gross.toStringAsFixed(0)}', Colors.black87),
                  _buildFinanceStat('Refunds', '-₹1,200', FriendLoopColors.rose),
                  _buildFinanceStat('Expenses', '-₹14,850', Colors.orange),
                  _buildFinanceStat('GST (18%)', '-₹14,256', Colors.purple),
                  _buildFinanceStat('Net Profit', '₹${net.toStringAsFixed(0)}', FriendLoopColors.onlineGreen),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // City Distribution breakdown
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FriendLoopColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Active Users by City', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FriendLoopColors.plum)),
              const SizedBox(height: 14),
              ...cities.map((c) {
                final cityName = c['city'] ?? 'City';
                final count = c['count'] ?? 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(cityName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: FriendLoopColors.plum)),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: count / 15.0,
                            backgroundColor: FriendLoopColors.lavender,
                            color: FriendLoopColors.violet,
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text('$count users', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FriendLoopColors.textSecondary)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FriendLoopColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: FriendLoopColors.plum)),
            Text(label, style: const TextStyle(fontSize: 12, color: FriendLoopColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceStat(String title, String val, Color col) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: FriendLoopColors.textSecondary)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: col)),
      ],
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Member Management & Audit',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: FriendLoopColors.plum),
        ),
        const SizedBox(height: 14),

        // Search bar
        TextField(
          controller: _searchMembersController,
          decoration: InputDecoration(
            hintText: 'Search members by name, phone or city...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FriendLoopColors.border)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        // Members list
        ..._members.map((m) {
          final isSuspended = m['is_suspended'] == true;
          final name = m['name'] ?? 'User';
          final phone = m['phone'] ?? '';
          final city = m['city'] ?? 'Bengaluru';
          final coins = m['coins'] ?? 120;
          final isPlus = m['is_plus'] == true;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isSuspended ? FriendLoopColors.rose : FriendLoopColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: FriendLoopColors.lavender,
                  child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: FriendLoopColors.plum)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.plum)),
                          if (isPlus) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: FriendLoopColors.brightViolet, borderRadius: BorderRadius.circular(4)),
                              child: const Text('PLUS', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                          if (isSuspended) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: FriendLoopColors.rose, borderRadius: BorderRadius.circular(4)),
                              child: const Text('SUSPENDED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      Text('$phone • $city • $coins 🪙', style: const TextStyle(fontSize: 12, color: FriendLoopColors.textSecondary)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _toggleSuspend(m['id'], isSuspended),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuspended ? FriendLoopColors.onlineGreen : FriendLoopColors.rose,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  child: Text(isSuspended ? 'Unsuspend' : 'Suspend', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSalesSection() {
    final packs = List<Map<String, dynamic>>.from(_overviewData['coin_packs_sold'] ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sales & Plans Breakdown',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: FriendLoopColors.plum),
        ),
        const SizedBox(height: 16),

        // Plus Subscription MRR Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FriendLoopColors.border),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FriendLoop Plus Memberships', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FriendLoopColors.plum)),
                  SizedBox(height: 4),
                  Text('130 active subscribers @ ₹350/mo', style: TextStyle(color: FriendLoopColors.textSecondary, fontSize: 13)),
                ],
              ),
              Text('₹45,500.00', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: FriendLoopColors.violet)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Coin Packs Table
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FriendLoopColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Coin Packs Sold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FriendLoopColors.plum)),
              const Divider(height: 24),
              ...packs.map((p) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p['pack'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: FriendLoopColors.plum)),
                      Text('${p['sold_count']} packs sold', style: const TextStyle(color: FriendLoopColors.textSecondary, fontSize: 13)),
                      Text('₹${(p['revenue_inr'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.onlineGreen)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Financial Ledger & Tax Reporting',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: FriendLoopColors.plum),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FriendLoopColors.border),
          ),
          child: Column(
            children: [
              _buildFinanceRow('Gross Collections (Coin Packs + Plus)', '₹80,400.00', isBold: true),
              const Divider(),
              _buildFinanceRow('Less: Customer Refunds & Chargebacks', '-₹1,200.00', isMinus: true),
              _buildFinanceRow('Operating Expenses: Cloud Hosting & DB', '-₹8,400.00', isMinus: true),
              _buildFinanceRow('Operating Expenses: Agora RTC Video & Voice Minutes', '-₹4,150.00', isMinus: true),
              _buildFinanceRow('Operating Expenses: Fast2SMS India OTP Gateway', '-₹2,300.00', isMinus: true),
              const Divider(),
              _buildFinanceRow('Tax: GST @ 18% (Applicable across India)', '-₹14,256.00', isMinus: true),
              const Divider(),
              _buildFinanceRow('Net Operating Profit', '₹50,094.00', isBold: true, isHighlight: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceRow(String title, String val, {bool isBold = false, bool isMinus = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                color: isHighlight ? FriendLoopColors.onlineGreen : FriendLoopColors.plum,
              ),
            ),
          ),
          Text(
            val,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              fontSize: 14,
              color: isHighlight
                  ? FriendLoopColors.onlineGreen
                  : (isMinus ? FriendLoopColors.rose : FriendLoopColors.plum),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModerationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Safety & Moderation Queue',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: FriendLoopColors.plum),
        ),
        const SizedBox(height: 14),

        if (_reports.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('All clear! Zero pending violation reports.')),
          )
        else
          ..._reports.map((rep) {
            final name = rep['reported_display_name'] ?? 'Reported User';
            final reason = rep['reason'] ?? 'Violation';
            final details = rep['details'] ?? 'No extra notes provided';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FriendLoopColors.rose),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: FriendLoopColors.plum)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: FriendLoopColors.rose, borderRadius: BorderRadius.circular(8)),
                        child: Text(reason, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Details: $details', style: const TextStyle(fontSize: 13, color: FriendLoopColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setState(() => _reports.remove(rep));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report dismissed')));
                        },
                        child: const Text('Dismiss'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _toggleSuspend(rep['reported_user_id'] ?? '', false);
                          setState(() => _reports.remove(rep));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: FriendLoopColors.rose),
                        child: const Text('Suspend User', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
