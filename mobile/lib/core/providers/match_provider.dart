import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import 'call_provider.dart';

class MatchState {
  final bool inQueue;
  final String? queueId;
  final bool allowAnyLanguage;
  final int waitTimeSeconds;
  final CallSessionData? matchedSession;
  final bool isLoading;
  final String? error;

  MatchState({
    this.inQueue = false,
    this.queueId,
    this.allowAnyLanguage = false,
    this.waitTimeSeconds = 0,
    this.matchedSession,
    this.isLoading = false,
    this.error,
  });

  MatchState copyWith({
    bool? inQueue,
    String? queueId,
    bool? allowAnyLanguage,
    int? waitTimeSeconds,
    CallSessionData? matchedSession,
    bool? isLoading,
    String? error,
  }) {
    return MatchState(
      inQueue: inQueue ?? this.inQueue,
      queueId: queueId ?? this.queueId,
      allowAnyLanguage: allowAnyLanguage ?? this.allowAnyLanguage,
      waitTimeSeconds: waitTimeSeconds ?? this.waitTimeSeconds,
      matchedSession: matchedSession,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MatchNotifier extends StateNotifier<MatchState> {
  final ApiClient _client = ApiClient();
  Timer? _pollingTimer;

  MatchNotifier() : super(MatchState());

  Future<void> joinQueue({String callMode = 'voice', bool allowAnyLanguage = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post(ApiEndpoints.matchJoin, body: {
        'call_mode': callMode,
        'allow_any_language': allowAnyLanguage,
      });

      if (res['matched_session'] != null) {
        final sess = CallSessionData.fromJson(res['matched_session']);
        state = state.copyWith(
          inQueue: false,
          matchedSession: sess,
          isLoading: false,
        );
        _stopPolling();
      } else {
        state = state.copyWith(
          inQueue: true,
          queueId: res['queue_id'],
          allowAnyLanguage: allowAnyLanguage,
          waitTimeSeconds: 0,
          isLoading: false,
        );
        _startPolling();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> cancelQueue() async {
    _stopPolling();
    try {
      await _client.post(ApiEndpoints.matchCancel);
    } catch (_) {}
    state = MatchState();
  }

  Future<void> broadenLanguages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _client.post(ApiEndpoints.matchBroaden);
      if (res['matched_session'] != null) {
        final sess = CallSessionData.fromJson(res['matched_session']);
        state = state.copyWith(
          inQueue: false,
          matchedSession: sess,
          isLoading: false,
        );
        _stopPolling();
      } else {
        state = state.copyWith(
          inQueue: true,
          allowAnyLanguage: true,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final res = await _client.get(ApiEndpoints.matchStatus);
        if (res['matched_session'] != null) {
          final sess = CallSessionData.fromJson(res['matched_session']);
          state = state.copyWith(
            inQueue: false,
            matchedSession: sess,
          );
          _stopPolling();
        } else if (res['in_queue'] == true) {
          state = state.copyWith(waitTimeSeconds: state.waitTimeSeconds + 2);
        } else {
          _stopPolling();
          state = MatchState();
        }
      } catch (_) {}
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void clearSession() {
    state = MatchState();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}

final matchProvider = StateNotifierProvider<MatchNotifier, MatchState>((ref) {
  return MatchNotifier();
});
