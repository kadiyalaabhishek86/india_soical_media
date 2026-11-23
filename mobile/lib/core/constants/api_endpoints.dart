import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Automatically detects Android emulator vs Localhost/Desktop/Web
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
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
