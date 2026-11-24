class ApiEndpoints {
  // Primary default Render backend URL, with --dart-define=API_BASE_URL override support
  static const String _defaultRenderUrl = 'https://india-soical-media.onrender.com';

  static String get rootUrl {
    const defined = String.fromEnvironment('API_BASE_URL', defaultValue: _defaultRenderUrl);
    final trimmed = defined.trim();
    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }

  static String get baseUrl {
    final root = rootUrl;
    if (root.endsWith('/api/v1')) return root;
    return '$root/api/v1';
  }

  // WebSocket URL using wss:// for https and ws:// for http
  static String get wsUrl {
    final uri = Uri.parse(rootUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final host = uri.host;
    final portStr = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://$host$portStr/ws';
  }

  // Auth & Profile
  static String get sendOtp => '$baseUrl/auth/send-otp';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';
  static String get setupProfile => '$baseUrl/auth/profile';
  static String get updateProfile => '$baseUrl/auth/profile';
  static String get uploadProfileImage => '$baseUrl/auth/profile/image';
  static String get me => '$baseUrl/auth/me';
  static String get updateLanguages => '$baseUrl/auth/languages';
  static String get acceptRules => '$baseUrl/auth/accept-rules';

  // Matching & Calls
  static String get matchJoin => '$baseUrl/match/join';
  static String get matchCancel => '$baseUrl/match/cancel';
  static String get matchBroaden => '$baseUrl/match/broaden';
  static String get matchStatus => '$baseUrl/match/status';
  static String callConnect(String roomId) => '$baseUrl/calls/connect';
  static String callLeave(String roomId) => '$baseUrl/calls/leave';
  static String callReconnect(String roomId) => '$baseUrl/calls/reconnect/$roomId';

  // Friendships & Chat
  static String get friendChoice => '$baseUrl/friendships/choose';
  static String get friendshipsList => '$baseUrl/friendships';
  static String friendProfile(String id) => '$baseUrl/friendships/$id/profile';
  static String unfriend(String id) => '$baseUrl/friendships/$id';
  static String get sendMessage => '$baseUrl/messages';
  static String getMessages(String friendshipId) => '$baseUrl/messages/$friendshipId';

  // Reels
  static String get reels => '$baseUrl/reels';
  static String get reelsUploadMedia => '$baseUrl/reels/upload-media';
  static String reelComments(String reelId) => '$baseUrl/reels/$reelId/comments';
  static String reelLike(String reelId) => '$baseUrl/reels/$reelId/like';

  // Rooms
  static String get rooms => '$baseUrl/rooms';
  static String roomJoin(String roomId) => '$baseUrl/rooms/$roomId/join';
  static String roomLeave(String roomId) => '$baseUrl/rooms/$roomId/leave';

  // Wallet & Plus
  static String get walletBalance => '$baseUrl/wallet/balance';
  static String get walletBuy => '$baseUrl/wallet/buy';
  static String get walletHistory => '$baseUrl/wallet/history';
  static String get plusStatus => '$baseUrl/plus/status';
  static String get plusSubscribe => '$baseUrl/plus/subscribe';

  // Moderation & Support
  static String get block => '$baseUrl/moderation/block';
  static String get blockedList => '$baseUrl/moderation/blocked';
  static String unblock(String targetId) => '$baseUrl/moderation/block/$targetId';
  static String get report => '$baseUrl/moderation/report';
  static String get support => '$baseUrl/moderation/support';
  static String get deleteAccount => '$baseUrl/moderation/delete-account';

  // Passes & Razorpay
  static String get passStatus => '$baseUrl/passes/status';
  static String get passVerify => '$baseUrl/passes/verify';
  static String get razorpayCreateOrder => '$baseUrl/passes/razorpay/create-order';
  static String get razorpayVerifyPayment => '$baseUrl/passes/razorpay/verify-payment';
}
