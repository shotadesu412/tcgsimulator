import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../domain/models/card_model.dart';
import '../../domain/models/deck_model.dart';
import '../../domain/models/game_state_model.dart';

// Hive初期化・Boxプロバイダ

class HiveDb {
  HiveDb._();

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CardModelAdapter());
    Hive.registerAdapter(DeckModelAdapter());
    Hive.registerAdapter(GameStateModelAdapter());

    await Future.wait([
      Hive.openBox<CardModel>('cards'),
      Hive.openBox<DeckModel>('decks'),
      Hive.openBox<GameStateModel>('games'),
    ]);
  }
}

final cardsBoxProvider = Provider<Box<CardModel>>((ref) => Hive.box('cards'));
final decksBoxProvider = Provider<Box<DeckModel>>((ref) => Hive.box('decks'));
final gamesBoxProvider = Provider<Box<GameStateModel>>((ref) => Hive.box('games'));
