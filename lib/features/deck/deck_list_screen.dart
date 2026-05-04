import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/id.dart';
import '../../data/db/deck_dao.dart';
import '../../domain/models/deck_model.dart';
import '../purchase/purchase_service.dart';
import '../purchase/purchase_sheet.dart';
import 'deck_providers.dart';

// S02: デッキ一覧画面

class DeckListScreen extends ConsumerWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(deckListProvider);
    final deckCount = ref.watch(deckCountProvider);
    final maxDecks = ref.watch(maxDecksProvider);
    final canCreate = ref.watch(canCreateDeckProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('デッキ管理'),
        actions: [
          // デッキ上限を常時表示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '$deckCount / $maxDecks',
                style: TextStyle(
                  color: canCreate ? AppColors.textSecondary : AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: decksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (decks) {
          if (decks.isEmpty) {
            return const Center(
              child: Text(
                'デッキがありません\n右下のボタンで作成',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: decks.length,
            itemBuilder: (context, i) => _DeckCard(deck: decks[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: canCreate
            ? () => _createDeck(context, ref)
            : () => PurchaseSheet.show(context),
        icon: Icon(canCreate ? Icons.add : Icons.lock_open),
        label: Text(canCreate ? '新規デッキ' : '枠を追加する'),
      ),
    );
  }

  Future<void> _createDeck(BuildContext context, WidgetRef ref) async {
    final count = ref.read(deckCountProvider);
    final name = await _showNameDialog(context, initialName: 'デッキ${count + 1}');
    if (name == null || !context.mounted) return;

    final now = DateTime.now();
    final deck = DeckModel()
      ..id = generateId()
      ..name = name
      ..createdAt = now
      ..updatedAt = now
      ..entries = [];

    await ref.read(deckDaoProvider).upsert(deck);
    if (context.mounted) context.push('/decks/${deck.id}');
  }
}

class _DeckCard extends ConsumerWidget {
  const _DeckCard({required this.deck});

  final DeckModel deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = deck.entries.fold(0, (s, e) => s + e.count);
    final warn = total > 60;

    return Card(
      child: ListTile(
        title: Text(deck.name),
        subtitle: Row(
          children: [
            Text('$total枚'),
            if (warn) ...[
              const SizedBox(width: 8),
              const Icon(Icons.warning_amber, size: 14, color: AppColors.warning),
              const Text(' 60枚超', style: TextStyle(color: AppColors.warning, fontSize: 12)),
            ],
          ],
        ),
        trailing: PopupMenuButton<_DeckAction>(
          onSelected: (action) => _onAction(context, ref, action),
          itemBuilder: (_) => const [
            PopupMenuItem(value: _DeckAction.edit, child: Text('編集')),
            PopupMenuItem(value: _DeckAction.rename, child: Text('名前を変更')),
            PopupMenuItem(value: _DeckAction.duplicate, child: Text('複製')),
            PopupMenuItem(
              value: _DeckAction.delete,
              child: Text('削除', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
        onTap: () => context.push('/decks/${deck.id}'),
      ),
    );
  }

  Future<void> _onAction(BuildContext context, WidgetRef ref, _DeckAction action) async {
    final dao = ref.read(deckDaoProvider);
    switch (action) {
      case _DeckAction.edit:
        context.push('/decks/${deck.id}');

      case _DeckAction.rename:
        final name = await _showNameDialog(context, initialName: deck.name);
        if (name != null) {
          deck.name = name;
          deck.updatedAt = DateTime.now();
          await dao.upsert(deck);
        }

      case _DeckAction.duplicate:
        if (!ref.read(canCreateDeckProvider)) {
          if (context.mounted) {
            await PurchaseSheet.show(context);
          }
          return;
        }
        final now = DateTime.now();
        final copy = DeckModel()
          ..id = generateId()
          ..name = '${deck.name}（コピー）'
          ..createdAt = now
          ..updatedAt = now
          ..entries = deck.entries
              .map((e) => DeckEntry(cardId: e.cardId, count: e.count))
              .toList();
        await dao.upsert(copy);

      case _DeckAction.delete:
        if (await _confirmDelete(context)) await dao.delete(deck.id);
    }
  }
}

enum _DeckAction { edit, rename, duplicate, delete }

Future<String?> _showNameDialog(BuildContext context, {required String initialName}) async {
  final controller = TextEditingController(text: initialName);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('デッキ名'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'デッキ名を入力'),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('キャンセル')),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<bool> _confirmDelete(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('デッキを削除'),
      content: const Text('このデッキを削除しますか？'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
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
