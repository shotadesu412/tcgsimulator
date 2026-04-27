import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/theme.dart';
import '../../data/db/card_dao.dart';
import '../../data/db/deck_dao.dart';

// S11: 設定画面 — T19

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const _SectionHeader('表示設定'),
          Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(themeModeProvider);
              return ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('ダークモード'),
                trailing: Switch(
                  value: mode == ThemeMode.dark,
                  onChanged: (v) {
                    ref.read(themeModeProvider.notifier).state =
                        v ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
              );
            },
          ),
          const Divider(),
          const _SectionHeader('データ管理'),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('データをエクスポート'),
            subtitle: const Text('カード・デッキをJSONでバックアップ'),
            onTap: () => _export(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('データをインポート'),
            subtitle: const Text('バックアップから復元'),
            onTap: () => _import(context, ref),
          ),
          const Divider(),
          const _SectionHeader('このアプリについて'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('バージョン'),
            trailing: Text('1.0.0', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      final cardDao = ref.read(cardDaoProvider);
      final deckDao = ref.read(deckDaoProvider);

      final cards = cardDao.findAll();
      final decks = deckDao.findAll();

      final data = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'cards': cards.map((c) => {
          'id': c.id,
          'name': c.name,
          'imagePath': c.imagePath,
          'tags': c.tags,
        }).toList(),
        'decks': decks.map((d) => {
          'id': d.id,
          'name': d.name,
          'entries': d.entries.map((e) => {'cardId': e.cardId, 'count': e.count}).toList(),
        }).toList(),
      };

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/boardkit_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonEncode(data));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エクスポート完了: ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エクスポート失敗: $e')),
        );
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    // TODO T19: ファイルピッカーでJSONを選択してインポート
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('インポート機能は準備中です')),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
