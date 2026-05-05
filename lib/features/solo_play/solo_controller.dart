import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/id.dart';
import '../../core/logger.dart';
import '../../data/db/deck_dao.dart';
import '../../data/db/game_dao.dart';
import '../../domain/models/card_model.dart';
import '../../domain/models/deck_model.dart';
import '../../domain/models/game_state_model.dart';
import '../../domain/models/zone_def.dart';
import '../../domain/presets/duel_masters.dart';
import '../card_library/card_repository.dart';

// T14: SoloController — family Notifier（deckIdを引数で受け取る）

class SoloState {
  const SoloState({
    required this.gameStateId,
    required this.deckId,
    required this.preset,
    required this.zones,
    required this.cardMap,
  });

  final String gameStateId;
  final String deckId;
  final GamePreset preset;
  final Map<String, List<CardInstance>> zones;
  final Map<String, CardModel> cardMap;

  SoloState copyWith({Map<String, List<CardInstance>>? zones}) {
    return SoloState(
      gameStateId: gameStateId,
      deckId: deckId,
      preset: preset,
      zones: zones ?? this.zones,
      cardMap: cardMap,
    );
  }

  ZoneDef zoneDef(String zoneKey) =>
      preset.zones.firstWhere((z) => z.key == zoneKey);

  List<CardInstance> zone(String key) => zones[key] ?? const [];
}

class SoloController
    extends AutoDisposeFamilyAsyncNotifier<SoloState, String> {
  @override
  Future<SoloState> build(String deckId) async {
    return _init(deckId);
  }

  Future<SoloState> _init(String deckId) async {
    final deckDao = ref.read(deckDaoProvider);
    final gameDao = ref.read(gameDaoProvider);
    final cardRepo = ref.read(cardRepositoryProvider);

    final deck = deckDao.findById(deckId);
    if (deck == null) throw Exception('デッキが見つかりません');

    const preset = kDuelMastersPreset;

    final cardMap = <String, CardModel>{
      for (final c in cardRepo.findAll()) c.id: c,
    };

    // deckId別にセーブデータを管理（複数デッキ同時使用に対応）
    final existing = gameDao.findSoloByDeckId(deckId)
        ?? gameDao.findLatestSolo(); // 旧データの後方互換
    if (existing != null) {
      final loaded = _loadFromModel(existing, preset, cardMap);
      if (loaded != null) return loaded;
    }

    return _newGame(deck, preset, cardMap, gameDao);
  }

  SoloState? _loadFromModel(
    GameStateModel model,
    GamePreset preset,
    Map<String, CardModel> cardMap,
  ) {
    try {
      final player = model.players.firstOrNull;
      if (player == null) return null;
      final zonesJson = jsonDecode(player.zonesJson) as Map<String, dynamic>;
      final zones = <String, List<CardInstance>>{
        for (final e in zonesJson.entries)
          e.key: (e.value as List)
              .map((j) => CardInstance.fromJson(j as Map<String, dynamic>))
              .toList(),
      };
      return SoloState(
        gameStateId: model.id,
        deckId: model.deckId,
        preset: preset,
        zones: zones,
        cardMap: cardMap,
      );
    } catch (e) {
      AppLogger.w('Failed to load game state', error: e);
      return null;
    }
  }

  Future<SoloState> _newGame(
    DeckModel deck,
    GamePreset preset,
    Map<String, CardModel> cardMap,
    GameDao gameDao,
  ) async {
    final instances = <CardInstance>[];
    for (final entry in deck.entries) {
      for (var i = 0; i < entry.count; i++) {
        instances.add(
          CardInstance(instanceId: generateId(), cardId: entry.cardId, faceUp: false),
        );
      }
    }
    instances.shuffle(Random.secure());

    final zones = <String, List<CardInstance>>{
      for (final z in preset.zones) z.key: [],
    };
    zones['deck'] = instances;

    // 超次元ゾーン: デッキ登録時に設定した hyperEntries を配置（裏向き＝武器面）
    for (final entry in deck.hyperEntries) {
      for (var i = 0; i < entry.count; i++) {
        zones['hyper']!.add(
          CardInstance(
            instanceId: generateId(),
            cardId: entry.cardId,
            faceUp: false, // 超次元では武器面（裏面）を表示
          ),
        );
      }
    }

    // 初期手札
    for (var i = 0; i < preset.initialHand && zones['deck']!.isNotEmpty; i++) {
      zones['hand']!.add(zones['deck']!.removeAt(0).copyWith(faceUp: true));
    }
    // シールド5枚
    for (var i = 0; i < 5 && zones['deck']!.isNotEmpty; i++) {
      zones['shield']!.add(zones['deck']!.removeAt(0));
    }

    final stateId = generateId();
    final s = SoloState(
      gameStateId: stateId,
      deckId: deck.id,
      preset: preset,
      zones: zones,
      cardMap: cardMap,
    );
    await _persist(s, gameDao);
    return s;
  }

  // ── 操作API ──────────────────────────────────────────

  Future<void> moveCard({
    required String instanceId,
    required String fromZone,
    required String toZone,
    int? toIndex,
    bool? faceUp,
  }) async {
    final s = state.valueOrNull;
    if (s == null) return;
    final zones = _copyZones(s.zones);
    final from = zones[fromZone]!;
    final idx = from.indexWhere((c) => c.instanceId == instanceId);
    if (idx < 0) return;
    var card = from.removeAt(idx);
    // faceUp未指定の場合は移動先ゾーンのデフォルトに従う
    final destFaceDown = s.preset.zones
        .firstWhere((z) => z.key == toZone)
        .faceDownByDefault;
    final effectiveFaceUp = faceUp ?? !destFaceDown;
    card = card.copyWith(faceUp: effectiveFaceUp);
    final to = zones[toZone]!;
    if (toIndex != null) {
      to.insert(toIndex.clamp(0, to.length), card);
    } else {
      to.add(card);
    }
    await _update(s.copyWith(zones: zones));
  }

  Future<void> drawOne() async {
    final deck = state.valueOrNull?.zone('deck');
    if (deck == null || deck.isEmpty) return;
    await moveCard(
      instanceId: deck.first.instanceId,
      fromZone: 'deck',
      toZone: 'hand',
      faceUp: true,
    );
  }

  Future<void> drawN(int n) async {
    for (var i = 0; i < n; i++) {
      if (state.valueOrNull?.zone('deck').isEmpty ?? true) break;
      await drawOne();
    }
  }

  Future<void> revealToPalette(int n) async {
    final s = state.valueOrNull;
    if (s == null) return;
    final zones = _copyZones(s.zones);
    final deck = zones['deck']!;
    final palette = zones['palette']!;
    final count = n.clamp(0, deck.length);
    for (var i = 0; i < count; i++) {
      palette.add(deck.removeAt(0).copyWith(faceUp: true));
    }
    await _update(s.copyWith(zones: zones));
  }

  Future<void> paletteToTop(String instanceId) async {
    await moveCard(
      instanceId: instanceId,
      fromZone: 'palette',
      toZone: 'deck',
      toIndex: 0,
      faceUp: false,
    );
  }

  Future<void> paletteToBottom(String instanceId) async {
    await moveCard(
      instanceId: instanceId,
      fromZone: 'palette',
      toZone: 'deck',
      faceUp: false,
    );
  }

  Future<void> allPaletteToTop() async {
    final s = state.valueOrNull;
    if (s == null) return;
    final zones = _copyZones(s.zones);
    final palette = zones['palette']!;
    final deck = zones['deck']!;
    deck.insertAll(0, palette.map((c) => c.copyWith(faceUp: false)));
    palette.clear();
    await _update(s.copyWith(zones: zones));
  }

  Future<void> allPaletteToBottom() async {
    final s = state.valueOrNull;
    if (s == null) return;
    final zones = _copyZones(s.zones);
    final palette = zones['palette']!;
    final deck = zones['deck']!;
    deck.addAll(palette.map((c) => c.copyWith(faceUp: false)));
    palette.clear();
    await _update(s.copyWith(zones: zones));
  }

  Future<void> shuffleDeck() async {
    final s = state.valueOrNull;
    if (s == null) return;
    final zones = _copyZones(s.zones);
    zones['deck']!.shuffle(Random.secure());
    await _update(s.copyWith(zones: zones));
  }

  Future<void> untapAll() async {
    final s = state.valueOrNull;
    if (s == null) return;
    final zones = _copyZones(s.zones);
    for (final key in zones.keys) {
      zones[key] = zones[key]!
          .map((c) => c.tapped ? c.copyWith(tapped: false) : c)
          .toList();
    }
    await _update(s.copyWith(zones: zones));
  }

  Future<void> toggleTap(String zoneKey, String instanceId) async {
    await _updateCard(zoneKey, instanceId, (c) => c.copyWith(tapped: !c.tapped));
  }

  Future<void> toggleFace(String zoneKey, String instanceId) async {
    await _updateCard(zoneKey, instanceId, (c) => c.copyWith(faceUp: !c.faceUp));
  }

  Future<void> updatePosition(String zoneKey, String instanceId, double x, double y) async {
    await _updateCard(zoneKey, instanceId, (c) => c.copyWith(position: (x: x, y: y)));
  }

  Future<void> reorderInZone(String zoneKey, int oldIndex, int newIndex) async {
    final s = state.valueOrNull;
    if (s == null) return;
    final zones = _copyZones(s.zones);
    final list = zones[zoneKey]!;
    if (oldIndex < 0 || oldIndex >= list.length) return;
    final item = list.removeAt(oldIndex);
    list.insert((newIndex > oldIndex ? newIndex - 1 : newIndex).clamp(0, list.length), item);
    await _update(s.copyWith(zones: zones));
  }

  Future<void> stackCards(String zoneKey, String bottomId, String topId) async {
    final s = state.valueOrNull;
    if (s == null || bottomId == topId) return;
    final zones = _copyZones(s.zones);
    final list = zones[zoneKey]!;

    final bottomIdx = list.indexWhere((c) => c.instanceId == bottomId);
    final topIdx = list.indexWhere((c) => c.instanceId == topId);
    if (bottomIdx < 0 || topIdx < 0) return;

    final bottom = list[bottomIdx];
    final stackId = bottom.stackId ?? generateId();
    list[bottomIdx] = bottom.copyWith(stackId: stackId, stackIndex: 0);

    final maxIdx = list
        .where((c) => c.stackId == stackId)
        .map((c) => c.stackIndex)
        .fold(0, (a, b) => a > b ? a : b);

    list[topIdx] = list[topIdx].copyWith(
      stackId: stackId,
      stackIndex: maxIdx + 1,
      position: bottom.position,
    );
    await _update(s.copyWith(zones: zones));
  }

  Future<void> unstackCard(String zoneKey, String instanceId) async {
    final s = state.valueOrNull;
    if (s == null) return;
    final zones = _copyZones(s.zones);
    final list = zones[zoneKey]!;
    final idx = list.indexWhere((c) => c.instanceId == instanceId);
    if (idx < 0) return;

    final card = list[idx];
    final stackId = card.stackId;
    if (stackId == null) return;

    list[idx] = card.copyWith(
      clearStack: true,
      stackIndex: 0,
      position: card.position != null
          ? (x: card.position!.x + 30, y: card.position!.y + 30)
          : null,
    );

    // 残り1枚になったらそちらもスタック解除
    final remaining = list.where((c) => c.stackId == stackId).toList();
    if (remaining.length == 1) {
      final lastIdx = list.indexWhere((c) => c.instanceId == remaining.first.instanceId);
      list[lastIdx] = list[lastIdx].copyWith(clearStack: true, stackIndex: 0);
    }
    await _update(s.copyWith(zones: zones));
  }

  Future<void> resetGame(String deckId) async {
    final s = state.valueOrNull;
    if (s != null) await ref.read(gameDaoProvider).delete(s.gameStateId);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _init(deckId));
  }

  // ── helpers ──────────────────────────────────────────

  Future<void> _updateCard(
    String zoneKey,
    String instanceId,
    CardInstance Function(CardInstance) fn,
  ) async {
    final s = state.valueOrNull;
    if (s == null) return;
    final zones = _copyZones(s.zones);
    final list = zones[zoneKey]!;
    final idx = list.indexWhere((c) => c.instanceId == instanceId);
    if (idx < 0) return;
    list[idx] = fn(list[idx]);
    await _update(s.copyWith(zones: zones));
  }

  Map<String, List<CardInstance>> _copyZones(Map<String, List<CardInstance>> src) =>
      {for (final e in src.entries) e.key: List.from(e.value)};

  Future<void> _update(SoloState newState) async {
    state = AsyncValue.data(newState);
    await _persist(newState, ref.read(gameDaoProvider));
  }

  Future<void> _persist(SoloState s, GameDao gameDao) async {
    try {
      final zonesJson = jsonEncode({
        for (final e in s.zones.entries)
          e.key: e.value.map((c) => c.toJson()).toList(),
      });
      final player = PlayerStateEmbed(playerId: 'solo', zonesJson: zonesJson);
      final model = GameStateModel()
        ..id = s.gameStateId
        ..presetId = s.preset.id
        ..mode = GameMode.solo
        ..turn = 1
        ..updatedAt = DateTime.now()
        ..players = [player]
        ..deckId = s.deckId;
      await gameDao.upsert(model);
    } catch (e) {
      AppLogger.e('Failed to persist game state', error: e);
    }
  }
}

// family プロバイダ — deckId を引数で受け取る
final soloControllerProvider = AsyncNotifierProvider.autoDispose
    .family<SoloController, SoloState, String>(SoloController.new);
