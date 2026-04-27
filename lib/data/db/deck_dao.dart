import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/models/deck_model.dart';
import 'isar_provider.dart';

// Deck DAO (Hive)

const kMaxDecks = 3;

class DeckDao {
  DeckDao(this._box);

  final Box<DeckModel> _box;

  List<DeckModel> findAll() {
    final decks = _box.values.toList();
    decks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return decks;
  }

  DeckModel? findById(String id) {
    try {
      return _box.values.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  int count() => _box.length;

  Future<void> upsert(DeckModel deck) async {
    await _box.put(deck.id, deck);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Stream<List<DeckModel>> watchAll() async* {
    yield findAll();
    await for (final _ in _box.watch()) {
      yield findAll();
    }
  }
}

final deckDaoProvider = Provider<DeckDao>(
  (ref) => DeckDao(ref.watch(decksBoxProvider)),
);
