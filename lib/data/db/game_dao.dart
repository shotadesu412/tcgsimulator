import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/models/game_state_model.dart';
import 'isar_provider.dart';

// GameState DAO (Hive)

class GameDao {
  GameDao(this._box);

  final Box<GameStateModel> _box;

  GameStateModel? findById(String id) {
    return _box.get(id);
  }

  GameStateModel? findLatestSolo() {
    final solos = _box.values
        .where((g) => g.mode == GameMode.solo)
        .toList();
    if (solos.isEmpty) return null;
    solos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return solos.first;
  }

  GameStateModel? findSoloByDeckId(String deckId) {
    final matches = _box.values
        .where((g) => g.mode == GameMode.solo && g.deckId == deckId)
        .toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return matches.first;
  }

  Future<void> upsert(GameStateModel state) async {
    await _box.put(state.id, state);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}

final gameDaoProvider = Provider<GameDao>(
  (ref) => GameDao(ref.watch(gamesBoxProvider)),
);
