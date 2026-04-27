import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/widgets/card_image.dart';
import 'solo_controller.dart';
import 'widgets/card_long_press_menu.dart';

// T17: S09 ゾーン一覧画面

class ZoneInspectorScreen extends ConsumerWidget {
  const ZoneInspectorScreen({
    super.key,
    required this.zoneKey,
    required this.gameStateId,
    required this.deckId,
  });

  final String zoneKey;
  final String gameStateId;
  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(soloControllerProvider(deckId));

    return asyncState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (state) {
        final zoneDef = state.zoneDef(zoneKey);
        final cards = state.zone(zoneKey);

        return Scaffold(
          appBar: AppBar(
            title: Text('${zoneDef.label}（${cards.length}枚）'),
            actions: [
              if (zoneKey == 'deck')
                IconButton(
                  icon: const Icon(Icons.shuffle),
                  tooltip: 'シャッフル',
                  onPressed: () {
                    ref.read(soloControllerProvider(deckId).notifier).shuffleDeck();
                  },
                ),
            ],
          ),
          body: cards.isEmpty
              ? const Center(
                  child: Text(
                    'カードがありません',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: cards.length,
                  onReorder: (oldIdx, newIdx) {
                    ref
                        .read(soloControllerProvider(deckId).notifier)
                        .reorderInZone(zoneKey, oldIdx, newIdx);
                  },
                  itemBuilder: (context, i) {
                    final card = cards[i];
                    final model = state.cardMap[card.cardId];
                    return ListTile(
                      key: ValueKey(card.instanceId),
                      leading: SizedBox(
                        width: 40,
                        height: 56,
                        child: CardImageWidget(
                          imagePath: model?.imagePath,
                          faceUp: card.faceUp,
                        ),
                      ),
                      title: Text(model?.name ?? '不明なカード'),
                      subtitle: Row(
                        children: [
                          if (card.tapped)
                            const Chip(
                              label: Text('タップ', style: TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          if (!card.faceUp)
                            const Chip(
                              label: Text('裏向き', style: TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.vertical_align_top, size: 20),
                            tooltip: '先頭へ',
                            onPressed: i == 0
                                ? null
                                : () => ref
                                    .read(soloControllerProvider(deckId).notifier)
                                    .reorderInZone(zoneKey, i, 0),
                          ),
                          IconButton(
                            icon: const Icon(Icons.vertical_align_bottom, size: 20),
                            tooltip: '末尾へ',
                            onPressed: i == cards.length - 1
                                ? null
                                : () => ref
                                    .read(soloControllerProvider(deckId).notifier)
                                    .reorderInZone(
                                      zoneKey,
                                      i,
                                      cards.length,
                                    ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onPressed: () => showCardLongPressMenu(
                              context,
                              ref,
                              zoneKey: zoneKey,
                              instanceId: card.instanceId,
                              state: state,
                              deckId: deckId,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
