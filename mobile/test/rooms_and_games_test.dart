import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/providers/rooms_provider.dart';
import 'package:mobile/features/rooms/games/carrom_clash_game_view.dart';
import 'package:mobile/features/rooms/games/voice_mimic_party_view.dart';
import 'package:mobile/features/rooms/games/truth_or_dare_game_view.dart';
import 'package:mobile/features/rooms/games/ludo_party_game_view.dart';

class _NoOpHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _NoOpHttpOverrides();
  });

  test('roomsProvider holds default rooms including games', () {
    final container = ProviderContainer();
    final rooms = container.read(roomsProvider).rooms;
    expect(rooms.isNotEmpty, isTrue);
    expect(rooms.any((r) => r.activityType == 'carrom'), isTrue);
    expect(rooms.any((r) => r.activityType == 'voice_mimic'), isTrue);
    expect(rooms.any((r) => r.activityType == 'truth_or_dare'), isTrue);
    expect(rooms.any((r) => r.activityType == 'ludo'), isTrue);
  });

  testWidgets('Carrom Clash renders header, striker and controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CarromClashGameView()),
      ),
    );
    await tester.pump(const Duration(seconds: 15));
    expect(find.text('Carrom Clash'), findsOneWidget);
    expect(find.text('20 COIN POT'), findsOneWidget);
    expect(find.text('RELEASE & STRIKE >>'), findsOneWidget);
  });

  testWidgets('Voice Mimic renders Tom stage, filters and SFX', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: VoiceMimicPartyView()),
      ),
    );
    await tester.pump(const Duration(seconds: 15));
    expect(find.text('Party Room #104'), findsOneWidget);
    expect(find.text('Classic Tom'), findsOneWidget);
    expect(find.text('Hold to Speak & Mimic'), findsOneWidget);
  });

  testWidgets('Truth or Dare renders bottle stage and choices', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TruthOrDareGameView()),
      ),
    );
    await tester.pump(const Duration(seconds: 15));
    expect(find.textContaining('Truth or Dare'), findsOneWidget);
    expect(find.text('SPIN THE BOTTLE AGAIN 🔄'), findsOneWidget);
  });

  testWidgets('Ludo 2v2 renders table, teams and dice', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LudoPartyGameView()),
      ),
    );
    await tester.pump(const Duration(seconds: 15));
    expect(find.textContaining('TABLE #12'), findsOneWidget);
    expect(find.text('TEAM VIOLET'), findsOneWidget);
    expect(find.textContaining('ADVANCE PAWN'), findsOneWidget);
  });

  testWidgets('Ludo 2v2 renders without overflow on narrow 320px screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LudoPartyGameView()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ludo with Friends'), findsOneWidget);
    expect(find.textContaining('TABLE #12'), findsOneWidget);
    expect(find.text('Rhea'), findsOneWidget);
    expect(find.text('Rohan'), findsOneWidget);
    expect(find.text('Ananya'), findsOneWidget);
    expect(find.text('Priya'), findsOneWidget);
    expect(find.textContaining('ADVANCE PAWN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
