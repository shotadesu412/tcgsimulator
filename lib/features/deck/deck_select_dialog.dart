import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/deck_dao.dart';

Future<String?> showDeckSelectDialog(
  BuildContext context, {
  String title = 'デッキを選択',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _DeckSelectDialog(title: title),
  );
}

class _DeckSelectDialog extends ConsumerWidget {
  const _DeckSelectDialog({this.title = 'デッキを選択'});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: _DeckList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }
}

class _DeckList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(deckDaoProvider);
    final decks = dao.findAll();
    if (decks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('デッキがありません。デッキ管理から作成してください。'),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: decks.length,
      itemBuilder: (context, i) {
        final deck = decks[i];
        final total = deck.entries.fold(0, (s, e) => s + e.count);
        return ListTile(
          title: Text(deck.name),
          subtitle: Text('$total枚'),
          onTap: () => Navigator.of(context).pop(deck.id),
        );
      },
    );
  }
}
