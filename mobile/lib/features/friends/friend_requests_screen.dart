import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';

class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  ConsumerState<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> {
  final List<Map<String, dynamic>> _requests = [
    {
      'id': 'req-1',
      'name': 'Rahul Varma',
      'age': 27,
      'city': 'Bengaluru',
      'languages': 'Telugu, English',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': 'req-2',
      'name': 'Priya Nair',
      'age': 25,
      'city': 'Chennai',
      'languages': 'Tamil, English',
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': 'req-3',
      'name': 'Kiran Kumar',
      'age': 29,
      'city': 'Hyderabad',
      'languages': 'Telugu, Hindi, English',
      'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    },
    {
      'id': 'req-4',
      'name': 'Meghana S',
      'age': 24,
      'city': 'Visakhapatnam',
      'languages': 'Telugu, English',
      'avatar': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=400&q=80',
    },
  ];

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
        title: Image.asset(
          'assets/images/friendloop_logo.png',
          height: 32,
          errorBuilder: (_, __, ___) => const Icon(Icons.all_inclusive, color: FriendLoopColors.violet, size: 28),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Friend Requests',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: FriendLoopColors.plum),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: FriendLoopColors.violet,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_requests.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _requests.isEmpty
                    ? const Center(child: Text('No pending requests', style: TextStyle(color: FriendLoopColors.textMuted)))
                    : ListView.separated(
                        itemCount: _requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, idx) {
                          final req = _requests[idx];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: FriendLoopColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundImage: NetworkImage(req['avatar']),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        req['name'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: FriendLoopColors.plum),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${req['age']} • ${req['city']}',
                                        style: const TextStyle(fontSize: 12, color: FriendLoopColors.textSecondary),
                                      ),
                                      Text(
                                        req['languages'],
                                        style: const TextStyle(fontSize: 11, color: FriendLoopColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() => _requests.removeAt(idx));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Accepted ${req['name']}! 🤝'), backgroundColor: FriendLoopColors.success),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: FriendLoopColors.violet,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        minimumSize: Size.zero,
                                      ),
                                      child: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 4),
                                    OutlinedButton(
                                      onPressed: () {
                                        setState(() => _requests.removeAt(idx));
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: FriendLoopColors.border),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        minimumSize: Size.zero,
                                      ),
                                      child: const Text('Decline', style: TextStyle(fontSize: 12, color: FriendLoopColors.textSecondary)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
