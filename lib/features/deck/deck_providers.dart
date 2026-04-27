import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/card_dao.dart';
import '../../data/db/deck_dao.dart';
import '../../domain/models/card_model.dart';
import '../../domain/models/deck_model.dart';

// StreamProvider — Riverpodのキャッシュ・ライフサイクルを活用

final deckListProvider = StreamProvider<List<DeckModel>>((ref) {
  return ref.watch(deckDaoProvider).watchAll();
});

final deckCountProvider = Provider<int>((ref) {
  return ref.watch(deckListProvider).valueOrNull?.length ?? 0;
});

final canCreateDeckProvider = Provider<bool>((ref) {
  return ref.watch(deckCountProvider) < kMaxDecks;
});

// 特定デッキをIDで取得（deckListProviderから派生）
final deckByIdProvider = Provider.autoDispose.family<DeckModel?, String>((ref, deckId) {
  final decks = ref.watch(deckListProvider).valueOrNull;
  return decks?.where((d) => d.id == deckId).firstOrNull;
});

// カード一覧（デッキ編集で使用）
final cardListProvider = StreamProvider.autoDispose<List<CardModel>>((ref) {
  return ref.watch(cardDaoProvider).watchAll();
});
