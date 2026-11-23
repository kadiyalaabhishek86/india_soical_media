import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/aara_card.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final ApiClient _client = ApiClient();
  List<dynamic> _blockedList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBlockedUsers();
  }

  Future<void> _fetchBlockedUsers() async {
    try {
      final List res = await _client.get(ApiEndpoints.blockedList);
      setState(() {
        _blockedList = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unblock(String targetId) async {
    try {
      await _client.delete(ApiEndpoints.unblock(targetId));
      await _fetchBlockedUsers();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AaraColors.background,
      appBar: AppBar(
        title: const Text('Blocked Accounts'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AaraColors.champagneLight))
            : _blockedList.isEmpty
                ? Center(
                    child: Text(
                      'No blocked accounts.',
                      style: AaraTypography.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _blockedList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _blockedList[index];
                      return AaraCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['display_name'] ?? 'Blocked User',
                              style: AaraTypography.titleMedium.copyWith(fontSize: 15),
                            ),
                            TextButton(
                              onPressed: () => _unblock(item['id']),
                              child: const Text('Unblock', style: TextStyle(color: AaraColors.champagneLight)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
