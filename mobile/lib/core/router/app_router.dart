import 'package:go_router/go_router.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/auth/otp_verification_screen.dart';
import '../../features/auth/profile_setup_screen.dart';
import '../../features/home/main_shell_screen.dart';
import '../../features/reels/create_reel_screen.dart';
import '../../features/rooms/create_room_screen.dart';
import '../../features/rooms/room_inside_screen.dart';
import '../../features/friends/friends_list_screen.dart';
import '../../features/friends/friend_requests_screen.dart';
import '../../features/match/random_connect_screen.dart';
import '../../features/call/recent_calls_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/plus/plus_subscription_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/profile/report_block_screen.dart';
import '../../features/profile/blocked_users_screen.dart';
import '../../features/friends/private_chat_screen.dart';
import '../../features/friends/friend_profile_screen.dart';
import '../../features/call/voice_call_screen.dart';
import '../../features/match/queue_screen.dart';
import '../../features/post_call/post_call_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../providers/friends_provider.dart';

final appRouter = GoRouter(
  initialLocation: '/welcome',
  routes: [
    // 1. Auth routes
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) {
        final phone = (state.extra as String?) ?? '+919876543210';
        return OtpVerificationScreen(phone: phone);
      },
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),

    // 2. User Shell Navigation Tabs
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainShellScreen(initialIndex: 0),
    ),
    GoRoute(
      path: '/reels',
      builder: (context, state) => const MainShellScreen(initialIndex: 1),
    ),
    GoRoute(
      path: '/rooms',
      builder: (context, state) => const MainShellScreen(initialIndex: 2),
    ),
    GoRoute(
      path: '/chats',
      builder: (context, state) => const MainShellScreen(initialIndex: 3),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const MainShellScreen(initialIndex: 4),
    ),

    // Backward compatibility match route
    GoRoute(
      path: '/match',
      builder: (context, state) => const MainShellScreen(initialIndex: 0),
    ),

    // 3. User Features & Shortcuts
    GoRoute(
      path: '/create-reel',
      builder: (context, state) => const CreateReelScreen(),
    ),
    GoRoute(
      path: '/create-room',
      builder: (context, state) => const CreateRoomScreen(),
    ),
    GoRoute(
      path: '/room/:id',
      builder: (context, state) {
        final roomId = state.pathParameters['id'] ?? '';
        final roomData = state.extra as Map<String, dynamic>?;
        return RoomInsideScreen(roomId: roomId, initialRoomData: roomData);
      },
    ),
    GoRoute(
      path: '/friends',
      builder: (context, state) => const FriendsListScreen(),
    ),
    GoRoute(
      path: '/friend-requests',
      builder: (context, state) => const FriendRequestsScreen(),
    ),
    GoRoute(
      path: '/random-connect',
      builder: (context, state) => const RandomConnectScreen(),
    ),
    GoRoute(
      path: '/recent-calls',
      builder: (context, state) => const RecentCallsScreen(),
    ),
    GoRoute(
      path: '/wallet',
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(
      path: '/plus',
      builder: (context, state) => const PlusSubscriptionScreen(),
    ),
    GoRoute(
      path: '/pass',
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/report-block',
      builder: (context, state) => const ReportBlockScreen(),
    ),
    GoRoute(
      path: '/blocked-users',
      builder: (context, state) => const BlockedUsersScreen(),
    ),

    // 4. Calling & Chat Detail
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) {
        final friendshipId = state.pathParameters['id'] ?? '';
        final friendInfo = state.extra as FriendItem?;
        return PrivateChatScreen(
          friendshipId: friendshipId,
          friendInfo: friendInfo,
        );
      },
    ),
    GoRoute(
      path: '/friend-profile/:id',
      builder: (context, state) {
        final friendshipId = state.pathParameters['id'] ?? '';
        final friendInfo = state.extra as FriendItem?;
        return FriendProfileScreen(
          friendshipId: friendshipId,
          initialFriend: friendInfo,
        );
      },
    ),
    GoRoute(
      path: '/call',
      builder: (context, state) => const VoiceCallScreen(),
    ),
    GoRoute(
      path: '/queue',
      builder: (context, state) => const QueueScreen(),
    ),
    GoRoute(
      path: '/post-call',
      builder: (context, state) => const PostCallScreen(),
    ),

    // 5. Admin Dashboard
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);
