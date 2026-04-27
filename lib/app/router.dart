import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/deck/deck_list_screen.dart';
import '../features/deck/deck_edit_screen.dart';
import '../features/card_library/card_library_screen.dart';
import '../features/card_library/card_edit_screen.dart';
import '../features/solo_play/solo_screen.dart' show SoloScreen, DualScreen;
import '../features/versus/lobby_screen.dart';
import '../features/versus/versus_screen.dart';
import '../features/solo_play/zone_inspector_screen.dart';
import '../features/settings/settings_screen.dart';

// T04: ルーティング雛形

abstract class AppRoutes {
  static const home = '/';
  static const deckList = '/decks';
  static const deckEdit = '/decks/:deckId';
  static const cardLibrary = '/cards';
  static const cardEdit = '/cards/:cardId';
  static const soloPlay = '/solo/:deckId';
  static const dualPlay = '/dual/:deck1Id/:deck2Id';
  static const versusLobby = '/lobby';
  static const versusPlay = '/versus/:roomCode';
  static const zoneInspector = '/zone-inspector';
  static const settings = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.deckList,
        builder: (context, state) => const DeckListScreen(),
        routes: [
          GoRoute(
            path: ':deckId',
            builder: (context, state) => DeckEditScreen(
              deckId: state.pathParameters['deckId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.cardLibrary,
        builder: (context, state) => const CardLibraryScreen(),
        routes: [
          GoRoute(
            path: ':cardId',
            builder: (context, state) => CardEditScreen(
              cardId: state.pathParameters['cardId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/solo/:deckId',
        builder: (context, state) => SoloScreen(
          deckId: state.pathParameters['deckId']!,
        ),
      ),
      GoRoute(
        path: '/dual/:deck1Id/:deck2Id',
        builder: (context, state) => DualScreen(
          deck1Id: state.pathParameters['deck1Id']!,
          deck2Id: state.pathParameters['deck2Id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.versusLobby,
        builder: (context, state) => const LobbyScreen(),
      ),
      GoRoute(
        path: '/versus/:roomCode',
        builder: (context, state) => VersusScreen(
          roomCode: state.pathParameters['roomCode']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.zoneInspector,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ZoneInspectorScreen(
            zoneKey: extra['zoneKey'] as String,
            gameStateId: extra['gameStateId'] as String,
            deckId: extra['deckId'] as String,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('ページが見つかりません: ${state.uri}'),
      ),
    ),
  );
});
