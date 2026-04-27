import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/models/card_model.dart';
import 'isar_provider.dart';

// Card DAO (Hive)

class CardDao {
  CardDao(this._box);

  final Box<CardModel> _box;

  List<CardModel> findAll() {
    final cards = _box.values.toList();
    cards.sort((a, b) => a.name.compareTo(b.name));
    return cards;
  }

  List<CardModel> search(String query) {
    final lower = query.toLowerCase();
    return _box.values
        .where((c) => c.name.toLowerCase().contains(lower))
        .toList();
  }

  CardModel? findById(String id) {
    try {
      return _box.values.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsert(CardModel card) async {
    await _box.put(card.id, card);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Stream<List<CardModel>> watchAll() async* {
    yield findAll();
    await for (final _ in _box.watch()) {
      yield findAll();
    }
  }
}

final cardDaoProvider = Provider<CardDao>(
  (ref) => CardDao(ref.watch(cardsBoxProvider)),
);
