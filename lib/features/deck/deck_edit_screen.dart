import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/db/deck_dao.dart';
import '../../domain/models/card_model.dart';
import '../../domain/models/deck_model.dart';
import '../../shared/widgets/card_image.dart';
import 'deck_providers.dart';

// S03: デッキ編集画面

class DeckEditScreen extends ConsumerStatefulWidget {
  const DeckEditScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<DeckEditScreen> createState() => _DeckEditScreenState();
}

class _DeckEditScreenState extends ConsumerState<DeckEditScreen>
    with SingleTickerProviderStateMixin {
  // デッキ（40枚）タブ
  Map<String, int> _counts = {};
  // 超次元（8枚）タブ
  Map<String, int> _hyperCounts = {};
  bool _initialized = false;
  final _searchController = TextEditingController();
  String _query = '';
  late final TabController _tabController;

  static const _kHyperMax = 8;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initCounts(DeckModel deck) {
    if (_initialized) return;
    _counts = {for (final e in deck.entries) e.cardId: e.count};
    _hyperCounts = {for (final e in deck.hyperEntries) e.cardId: e.count};
    _initialized = true;
  }

  int _total() => _counts.values.fold(0, (s, c) => s + c);
  int _hyperTotal() => _hyperCounts.values.fold(0, (s, c) => s + c);

  Future<void> _setCount(DeckModel deck, String cardId, int count) async {
    setState(() {
      if (count <= 0) {
        _counts.remove(cardId);
      } else {
        _counts[cardId] = count;
      }
    });
    deck.entries = _counts.entries
        .map((e) => DeckEntry(cardId: e.key, count: e.value))
        .toList();
    deck.updatedAt = DateTime.now();
    await ref.read(deckDaoProvider).upsert(deck);
  }

  Future<void> _setHyperCount(DeckModel deck, String cardId, int count) async {
    final newTotal = _hyperTotal() - (_hyperCounts[cardId] ?? 0) + count;
    if (count > 0 && newTotal > _kHyperMax) return; // 8枚上限
    setState(() {
      if (count <= 0) {
        _hyperCounts.remove(cardId);
      } else {
        _hyperCounts[cardId] = count;
      }
    });
    deck.hyperEntries = _hyperCounts.entries
        .map((e) => DeckEntry(cardId: e.key, count: e.value))
        .toList();
    deck.updatedAt = DateTime.now();
    await ref.read(deckDaoProvider).upsert(deck);
  }

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(deckByIdProvider(widget.deckId));
    final cardsAsync = ref.watch(cardListProvider);

    if (deck == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _initCounts(deck);
    final total = _total();
    final hyperTotal = _hyperTotal();

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'デッキ $total枚'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('超次元'),
                  const SizedBox(width: 4),
                  Text(
                    '$hyperTotal/$_kHyperMax',
                    style: TextStyle(
                      fontSize: 11,
                      color: hyperTotal >= _kHyperMax
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (allCards) {
          if (allCards.isEmpty) {
            return const Center(
              child: Text(
                'カードがありません\nカードライブラリから登録してください',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return Column(
            children: [
              // 検索バー
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'カード名で検索',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // タブ1: デッキ
                    _CardGrid(
                      allCards: allCards,
                      query: _query,
                      counts: _counts,
                      onAdd: (cardId, count) => _setCount(deck, cardId, count + 1),
                      onRemove: (cardId, count) => _setCount(deck, cardId, count - 1),
                    ),
                    // タブ2: 超次元（最大8枚）
                    _CardGrid(
                      allCards: allCards,
                      query: _query,
                      counts: _hyperCounts,
                      maxTotal: _kHyperMax,
                      currentTotal: hyperTotal,
                      onAdd: (cardId, count) =>
                          _setHyperCount(deck, cardId, count + 1),
                      onRemove: (cardId, count) =>
                          _setHyperCount(deck, cardId, count - 1),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── カードグリッド（デッキ/超次元共用）─────────────────────────────────────

class _CardGrid extends StatelessWidget {
  const _CardGrid({
    required this.allCards,
    required this.query,
    required this.counts,
    required this.onAdd,
    required this.onRemove,
    this.maxTotal,
    this.currentTotal = 0,
  });

  final List<CardModel> allCards;
  final String query;
  final Map<String, int> counts;
  final void Function(String cardId, int currentCount) onAdd;
  final void Function(String cardId, int currentCount) onRemove;
  final int? maxTotal;
  final int currentTotal;

  List<CardModel> _sortCards(List<CardModel> cards) {
    final inDeck = cards.where((c) => (counts[c.id] ?? 0) > 0).toList();
    final notInDeck = cards.where((c) => (counts[c.id] ?? 0) == 0).toList();
    inDeck.sort((a, b) {
      final diff = (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0);
      return diff != 0 ? diff : a.name.compareTo(b.name);
    });
    notInDeck.sort((a, b) => a.name.compareTo(b.name));
    return [...inDeck, ...notInDeck];
  }

  @override
  Widget build(BuildContext context) {
    var filtered = allCards;
    if (query.isNotEmpty) {
      final lower = query.toLowerCase();
      filtered = allCards.where((c) => c.name.toLowerCase().contains(lower)).toList();
    }
    final sorted = _sortCards(filtered);
    final atMax = maxTotal != null && currentTotal >= maxTotal!;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.62,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final card = sorted[i];
        final count = counts[card.id] ?? 0;
        return _DeckCardTile(
          card: card,
          count: count,
          onAdd: (atMax && count == 0) ? null : () => onAdd(card.id, count),
          onRemove: () => onRemove(card.id, count),
        );
      },
    );
  }
}

class _DeckCardTile extends StatelessWidget {
  const _DeckCardTile({
    required this.card,
    required this.count,
    required this.onAdd,
    required this.onRemove,
  });

  final CardModel card;
  final int count;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // カード画像 or プレースホルダー
              Positioned.fill(
                child: card.imagePath.isNotEmpty
                    ? CardImageWidget(
                        imagePath: card.imagePath,
                        borderColor: count > 0 ? AppColors.primaryLight : null,
                      )
                    : _NoImageCard(card: card, inDeck: count > 0),
              ),
              // コスト・文明バッジ（画像あり時）
              if (card.imagePath.isNotEmpty && (card.cost > 0 || card.civList.isNotEmpty))
                Positioned(
                  top: 3,
                  left: 3,
                  child: _CivCostBadge(card: card),
                ),
              // 枚数バッジ
              if (count > 0)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'x$count',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // カード名
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Text(
            card.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: count > 0 ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        // +-ボタン
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TileButton(icon: Icons.remove, onTap: count > 0 ? onRemove : null),

            SizedBox(
              width: 28,
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            _TileButton(icon: Icons.add, onTap: onAdd),
          ],
        ),
      ],
    );
  }
}

class _TileButton extends StatelessWidget {
  const _TileButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
    );
  }
}

// 画像なしカードのプレースホルダー
class _NoImageCard extends StatelessWidget {
  const _NoImageCard({required this.card, required this.inDeck});
  final CardModel card;
  final bool inDeck;

  @override
  Widget build(BuildContext context) {
    final civs = card.civList;
    Color bgColor;
    if (civs.isEmpty) {
      bgColor = AppColors.surfaceMid;
    } else if (civs.length == 1) {
      bgColor = (kCivColors[civs.first] ?? AppColors.surfaceMid).withValues(alpha: 0.3);
    } else {
      bgColor = AppColors.surfaceMid;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: inDeck ? AppColors.primaryLight : AppColors.zoneBorder,
          width: inDeck ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 文明ドット
          if (civs.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: civs.map((c) {
                final col = kCivColors[c] ?? Colors.grey;
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                );
              }).toList(),
            ),
          if (civs.isNotEmpty) const SizedBox(height: 4),
          // コスト
          if (card.cost > 0)
            Text(
              '${card.cost}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            card.name,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// 画像ありカードへのコスト・文明バッジ
class _CivCostBadge extends StatelessWidget {
  const _CivCostBadge({required this.card});
  final CardModel card;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final civ in card.civList)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: kCivColors[civ] ?? Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          if (card.cost > 0)
            Text(
              '${card.cost}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
