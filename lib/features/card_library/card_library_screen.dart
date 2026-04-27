import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/db/card_dao.dart';
import '../../domain/models/card_model.dart';
import '../../shared/widgets/card_image.dart';

// S04: カードライブラリ画面

class CardLibraryScreen extends ConsumerStatefulWidget {
  const CardLibraryScreen({super.key});

  @override
  ConsumerState<CardLibraryScreen> createState() => _CardLibraryScreenState();
}

class _CardLibraryScreenState extends ConsumerState<CardLibraryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カードライブラリ'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'カード名で検索',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: _CardGrid(query: _query),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/cards/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CardGrid extends ConsumerWidget {
  const _CardGrid({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(cardDaoProvider);
    return StreamBuilder<List<CardModel>>(
      stream: dao.watchAll(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var cards = snap.data ?? [];
        if (query.isNotEmpty) {
          final lower = query.toLowerCase();
          cards = cards
              .where((c) => c.name.toLowerCase().contains(lower))
              .toList();
        }

        if (cards.isEmpty) {
          return const Center(
            child: Text(
              'カードがありません\n右下のボタンで登録',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: cards.length,
          itemBuilder: (context, i) => _CardTile(card: cards[i]),
        );
      },
    );
  }
}

class _CardTile extends ConsumerWidget {
  const _CardTile({required this.card});

  final CardModel card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/cards/${card.id}'),
      onLongPress: () => _showMenu(context, ref),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: card.imagePath.isNotEmpty
                      ? CardImageWidget(imagePath: card.imagePath)
                      : _NoImagePlaceholder(card: card),
                ),
                if (card.imagePath.isNotEmpty &&
                    (card.cost > 0 || card.civList.isNotEmpty))
                  Positioned(
                    top: 3,
                    left: 3,
                    child: _CivCostBadge(card: card),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            card.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Future<void> _showMenu(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(card.name),
            subtitle: const Text('タップして編集'),
            onTap: () {
              Navigator.pop(context, 'edit');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: AppColors.error),
            title: const Text('削除', style: TextStyle(color: AppColors.error)),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    if (action == 'edit') {
      context.push('/cards/${card.id}');
    } else if (action == 'delete') {
      final ok = await _confirmDelete(context);
      if (ok) {
        await ref.read(cardDaoProvider).delete(card.id);
      }
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カードを削除'),
        content: Text('「${card.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _NoImagePlaceholder extends StatelessWidget {
  const _NoImagePlaceholder({required this.card});
  final CardModel card;

  @override
  Widget build(BuildContext context) {
    final civs = card.civList;
    final bgColor = civs.length == 1
        ? (kCivColors[civs.first] ?? AppColors.surfaceMid).withValues(alpha: 0.25)
        : AppColors.surfaceMid;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.zoneBorder),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          if (civs.isNotEmpty && card.cost > 0) const SizedBox(height: 4),
          if (card.cost > 0)
            Text(
              '${card.cost}',
              style: const TextStyle(
                fontSize: 18,
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
