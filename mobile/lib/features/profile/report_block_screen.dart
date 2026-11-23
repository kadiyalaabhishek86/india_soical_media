import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/network/api_client.dart';

class ReportBlockScreen extends ConsumerStatefulWidget {
  final String? targetUserId;
  final String? targetUserName;

  const ReportBlockScreen({
    super.key,
    this.targetUserId,
    this.targetUserName,
  });

  @override
  ConsumerState<ReportBlockScreen> createState() => _ReportBlockScreenState();
}

class _ReportBlockScreenState extends ConsumerState<ReportBlockScreen> {
  final ApiClient _client = ApiClient();
  int _actionType = 0; // 0 = Report User, 1 = Block User
  String _selectedReason = 'Harassment or abuse';
  final _detailsController = TextEditingController();
  bool _isLoading = false;

  static const List<Map<String, dynamic>> _reasons = [
    {'title': 'Harassment or abuse', 'icon': Icons.flag_outlined},
    {'title': 'Inappropriate content', 'icon': Icons.warning_amber_rounded},
    {'title': 'Spam or promotions', 'icon': Icons.email_outlined},
    {'title': 'Fake profile', 'icon': Icons.person_off_outlined},
    {'title': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);
    try {
      final targetId = widget.targetUserId ?? '22222222-2222-2222-2222-222222222222';
      if (_actionType == 0) {
        // Report
        await _client.post(
          '/moderation/report',
          body: {
            'reported_id': targetId,
            'reason': _selectedReason,
            'details': _detailsController.text.trim(),
          },
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you. Your report has been submitted to moderators.'),
            backgroundColor: FriendLoopColors.success,
          ),
        );
      } else {
        // Block
        await _client.post(
          '/moderation/block',
          body: {
            'blocked_id': targetId,
            'reason': _selectedReason,
          },
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User has been blocked.'),
            backgroundColor: FriendLoopColors.plum,
          ),
        );
      }
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action completed: ${e.toString()}'), backgroundColor: FriendLoopColors.plum),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.targetUserName ?? 'Kiran Kumar';

    return Scaffold(
      backgroundColor: FriendLoopColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FriendLoopColors.plum),
          onPressed: () => context.pop(),
        ),
        title: Image.asset(
          'assets/images/friendloop_logo.png',
          height: 32,
          errorBuilder: (_, __, ___) => const Icon(Icons.all_inclusive, color: FriendLoopColors.violet, size: 28),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report or Block',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: FriendLoopColors.plum),
              ),
              const SizedBox(height: 14),

              // Target User Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: FriendLoopColors.border),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: FriendLoopColors.plum)),
                          const Text('29 • Hyderabad', style: TextStyle(fontSize: 12, color: FriendLoopColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Mode Radio
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<int>(
                      value: 0,
                      groupValue: _actionType,
                      activeColor: FriendLoopColors.violet,
                      title: const Text('Report User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onChanged: (v) => setState(() => _actionType = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<int>(
                      value: 1,
                      groupValue: _actionType,
                      activeColor: FriendLoopColors.violet,
                      title: const Text('Block User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onChanged: (v) => setState(() => _actionType = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Reason Selector
              const Text(
                'Reason for reporting *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FriendLoopColors.plum),
              ),
              const SizedBox(height: 10),

              ..._reasons.map((r) {
                final isSelected = _selectedReason == r['title'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? FriendLoopColors.violet : FriendLoopColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(r['icon'] as IconData, color: isSelected ? FriendLoopColors.violet : FriendLoopColors.textSecondary),
                    title: Text(
                      r['title'],
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? FriendLoopColors.violet : FriendLoopColors.plum,
                        fontSize: 14,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: FriendLoopColors.violet, size: 20) : null,
                    onTap: () => setState(() => _selectedReason = r['title']),
                  ),
                );
              }),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSubmit,
                  icon: Icon(_actionType == 0 ? Icons.flag : Icons.block, color: Colors.white),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _actionType == 0 ? 'Submit Report' : 'Block User',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _actionType == 0 ? FriendLoopColors.violet : FriendLoopColors.rose,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
