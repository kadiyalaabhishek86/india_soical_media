import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/friends_provider.dart';
import '../theme/colors.dart';

enum CoinActionType { voice, video, chat }

class PendingCoinAction {
  final CoinActionType actionType;
  final FriendItem? friend;
  final String? chatRouteId;
  final int requiredCoins;
  final String planName;

  const PendingCoinAction({
    required this.actionType,
    this.friend,
    this.chatRouteId,
    required this.requiredCoins,
    required this.planName,
  });

  String get actionLabel {
    switch (actionType) {
      case CoinActionType.voice:
        return 'Voice Call';
      case CoinActionType.video:
        return 'Video Call';
      case CoinActionType.chat:
        return 'Chat';
    }
  }
}

class CoinBilling {
  /// Returns the coin cost based on the user's current plan (Standard vs FriendLoop Plus).
  static int costForAction(CoinActionType type, {required bool isPlus}) {
    switch (type) {
      case CoinActionType.voice:
        return isPlus ? 5 : 10;
      case CoinActionType.video:
        return isPlus ? 20 : 40;
      case CoinActionType.chat:
        return isPlus ? 2 : 5;
    }
  }

  static String planLabel(bool isPlus) => isPlus ? 'Plus Plan (50% off)' : 'Standard Plan';

  /// Checks the user's coins against their plan cost.
  /// If insufficient, opens the Coin Wallet (`/wallet`) with the pending action so they can recharge and proceed.
  /// If sufficient, deducts coins according to plan and returns true.
  static bool checkAndDeductForAction({
    required BuildContext context,
    required WidgetRef ref,
    required CoinActionType actionType,
    FriendItem? friend,
    String? chatRouteId,
  }) {
    final profile = ref.read(authProvider).currentUserProfile;
    final userCoins = profile?.coins ?? 120;
    final isPlus = profile?.isPlusSubscriber ?? false;
    final cost = costForAction(actionType, isPlus: isPlus);
    final plan = planLabel(isPlus);

    if (userCoins < cost) {
      final label = actionType == CoinActionType.voice
          ? 'Voice Call'
          : (actionType == CoinActionType.video ? 'Video Call' : 'Chat');
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient coins for $label ($cost coins on $plan, you have $userCoins). Opening Coins page...',
          ),
          backgroundColor: FriendLoopColors.plum,
          duration: const Duration(seconds: 2),
        ),
      );
      context.push(
        '/wallet',
        extra: PendingCoinAction(
          actionType: actionType,
          friend: friend,
          chatRouteId: chatRouteId,
          requiredCoins: cost,
          planName: plan,
        ),
      );
      return false;
    }

    ref.read(authProvider.notifier).updateCoins(userCoins - cost);
    return true;
  }
}

