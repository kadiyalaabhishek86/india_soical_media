import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import 'auth_provider.dart';

class PartnerInfo {
  final String id;
  final String displayName;
  final String state;
  final String? city;
  final List<String> languages;

  PartnerInfo({
    required this.id,
    required this.displayName,
    required this.state,
    this.city,
    required this.languages,
  });

  factory PartnerInfo.fromJson(Map<String, dynamic> json) {
    return PartnerInfo(
      id: json['id'] ?? '',
      displayName: json['display_name'] ?? 'Friend',
      state: json['state_or_union_territory'] ?? 'India',
      city: json['city'],
      languages: List<String>.from(json['languages'] ?? []),
    );
  }
}

class CallSessionData {
  final String id;
  final String roomId;
  final String callMode;
  final String status;
  final String? startedAt;
  final String? sharedEndTime;
  final int durationSeconds;
  final String? token;
  final PartnerInfo? partner;

  CallSessionData({
    required this.id,
    required this.roomId,
    required this.callMode,
    required this.status,
    this.startedAt,
    this.sharedEndTime,
    this.durationSeconds = 60,
    this.token,
    this.partner,
  });

  factory CallSessionData.fromJson(Map<String, dynamic> json) {
    return CallSessionData(
      id: json['id'] ?? '',
      roomId: json['room_id'] ?? '',
      callMode: json['call_mode'] ?? 'voice',
      status: json['status'] ?? 'connecting',
      startedAt: json['started_at'],
      sharedEndTime: json['shared_end_time'],
      durationSeconds: json['duration_seconds'] ?? 60,
      token: json['token'],
      partner: json['partner'] != null ? PartnerInfo.fromJson(json['partner']) : null,
    );
  }
}

class CallState {
  final CallSessionData? session;
  final int remainingSeconds;
  final bool isConnecting;
  final bool isConnected;
  final bool isReconnecting;
  final bool isMuted;
  final bool isCameraOn;
  final bool hasEnded;
  final String? errorMessage;

  CallState({
    this.session,
    this.remainingSeconds = 60,
    this.isConnecting = true,
    this.isConnected = false,
    this.isReconnecting = false,
    this.isMuted = false,
    this.isCameraOn = false,
    this.hasEnded = false,
    this.errorMessage,
  });

  CallState copyWith({
    CallSessionData? session,
    int? remainingSeconds,
    bool? isConnecting,
    bool? isConnected,
    bool? isReconnecting,
    bool? isMuted,
    bool? isCameraOn,
    bool? hasEnded,
    String? errorMessage,
  }) {
    return CallState(
      session: session ?? this.session,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      isMuted: isMuted ?? this.isMuted,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      hasEnded: hasEnded ?? this.hasEnded,
      errorMessage: errorMessage,
    );
  }
}

class CallNotifier extends StateNotifier<CallState> {
  final ApiClient _client = ApiClient();
  final Ref ref;
  Timer? _ticker;

  CallNotifier(this.ref) : super(CallState());

  Future<void> startSession(CallSessionData session) async {
    state = CallState(
      session: session,
      remainingSeconds: 60,
      isConnecting: true,
      isConnected: false,
    );

    try {
      // Notify backend that this participant connected
      final res = await _client.post(ApiEndpoints.callConnect(session.roomId), body: {
        'room_id': session.roomId,
      });
      final updated = CallSessionData.fromJson(res);

      state = state.copyWith(
        session: updated,
        isConnecting: false,
        isConnected: true,
      );

      // Refresh remaining credit balance in authProvider
      ref.read(authProvider.notifier).refreshProfile();

      _startTimer();
    } catch (e) {
      // In local demo or simulated scenario, start call anyway
      state = state.copyWith(isConnecting: false, isConnected: true);
      _startTimer();
    }
  }

  void _startTimer() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _ticker?.cancel();
        state = state.copyWith(remainingSeconds: 0, hasEnded: true);
        leaveCall();
      }
    });
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void toggleCamera() {
    state = state.copyWith(isCameraOn: !state.isCameraOn);
  }

  Future<void> leaveCall() async {
    _ticker?.cancel();
    final roomId = state.session?.roomId;
    if (roomId != null) {
      try {
        await _client.post(ApiEndpoints.callLeave(roomId), body: {'room_id': roomId});
      } catch (_) {}
    }
    state = state.copyWith(hasEnded: true, isConnected: false);
  }

  Future<void> reconnect() async {
    final roomId = state.session?.roomId;
    if (roomId == null) return;

    state = state.copyWith(isReconnecting: true);
    try {
      final res = await _client.get(ApiEndpoints.callReconnect(roomId));
      final remaining = res['remaining_seconds'] ?? 0;
      if (remaining <= 0) {
        state = state.copyWith(isReconnecting: false, hasEnded: true);
      } else {
        state = state.copyWith(
          isReconnecting: false,
          remainingSeconds: remaining,
          isConnected: true,
        );
        _startTimer();
      }
    } catch (_) {
      state = state.copyWith(isReconnecting: false);
    }
  }

  Future<void> blockParticipant(String reason) async {
    final partnerId = state.session?.partner?.id;
    if (partnerId != null) {
      await _client.post(ApiEndpoints.block, body: {
        'blocked_id': partnerId,
        'reason': reason,
      });
      leaveCall();
    }
  }

  Future<void> reportParticipant(String reason, String details) async {
    final partnerId = state.session?.partner?.id;
    final callId = state.session?.id;
    if (partnerId != null) {
      await _client.post(ApiEndpoints.report, body: {
        'reported_id': partnerId,
        'call_id': callId,
        'reason': reason,
        'details': details,
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final callProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  return CallNotifier(ref);
});
