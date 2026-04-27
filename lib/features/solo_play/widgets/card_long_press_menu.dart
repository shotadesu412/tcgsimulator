import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/card_model.dart';
import '../../../domain/models/zone_def.dart';
import '../../../shared/widgets/card_image.dart';
import '../solo_controller.dart';

// T16: 長押しメニュー

Future<void> showCardLongPressMenu(
  BuildContext context,
  WidgetRef ref, {
  required String zoneKey,
  required String instanceId,
  required SoloState state,
  required String deckId,
}) async {
  final instance = state.zone(zoneKey)
      .where((c) => c.instanceId == instanceId)
      .firstOrNull;
  if (instance == null) return;

  final preset = state.preset;
  final otherZones = preset.zones
      .where((z) => z.key != zoneKey)
      .toList();

  await showModalBottomSheet<void>(
    context: context,
    builder: (context) => _CardMenu(
      zoneKey: zoneKey,
      instanceId: instanceId,
      instance: instance,
      otherZones: otherZones,
      ref: ref,
      deckId: deckId,
      state: state,
    ),
  );
}

class _CardMenu extends StatelessWidget {
  const _CardMenu({
    required this.zoneKey,
    required this.instanceId,
    required this.instance,
    required this.otherZones,
    required this.ref,
    required this.deckId,
    required this.state,
  });

  final String zoneKey;
  final String instanceId;
  final CardInstance instance;
  final List<ZoneDef> otherZones;
  final WidgetRef ref;
  final String deckId;
  final SoloState state;

  @override
  Widget build(BuildContext context) {
    final zoneCards = state.zone(zoneKey)
        .where((c) => c.instanceId != instanceId)
        .toList();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'カードを操作',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          // タップ/アンタップ
          ListTile(
            leading: const Icon(Icons.rotate_right),
            title: Text(instance.tapped ? 'アンタップ' : 'タップ'),
            onTap: () async {
              Navigator.pop(context);
              await ref
                  .read(soloControllerProvider(deckId).notifier)
                  .toggleTap(zoneKey, instanceId);
            },
          ),
          // 表/裏切替
          ListTile(
            leading: const Icon(Icons.flip),
            title: Text(instance.faceUp ? '裏向きにする' : '表向きにする'),
            onTap: () async {
              Navigator.pop(context);
              await ref
                  .read(soloControllerProvider(deckId).notifier)
                  .toggleFace(zoneKey, instanceId);
            },
          ),
          const Divider(height: 1),
          // カードに重ねる
          if (zoneCards.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.layers),
              title: const Text('カードに重ねる'),
              onTap: () async {
                Navigator.pop(context);
                await _showStackPicker(context, ref, zoneCards, deckId, state);
              },
            ),
          // スタックから外す
          if (instance.stackId != null)
            ListTile(
              leading: const Icon(Icons.layers_clear),
              title: const Text('スタックから外す'),
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(soloControllerProvider(deckId).notifier)
                    .unstackCard(zoneKey, instanceId);
              },
            ),
          const Divider(height: 1),
          // 山札へ（上/下）
          if (zoneKey != 'deck') ...[
            ListTile(
              leading: const Icon(Icons.vertical_align_top),
              title: const Text('山札の一番上へ'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(soloControllerProvider(deckId).notifier).moveCard(
                      instanceId: instanceId,
                      fromZone: zoneKey,
                      toZone: 'deck',
                      toIndex: 0,
                      faceUp: false,
                    );
              },
            ),
            ListTile(
              leading: const Icon(Icons.vertical_align_bottom),
              title: const Text('山札の一番下へ'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(soloControllerProvider(deckId).notifier).moveCard(
                      instanceId: instanceId,
                      fromZone: zoneKey,
                      toZone: 'deck',
                      faceUp: false,
                    );
              },
            ),
          ],
          const Divider(height: 1),
          // その他のゾーンへ移動
          ...otherZones
              .where((z) => z.key != 'deck')
              .map(
                (z) => ListTile(
                  leading: const Icon(Icons.send),
                  title: Text('${z.label}へ移動'),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(soloControllerProvider(deckId).notifier).moveCard(
                          instanceId: instanceId,
                          fromZone: zoneKey,
                          toZone: z.key,
                          faceUp: z.faceDownByDefault ? false : true,
                        );
                  },
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _showStackPicker(
    BuildContext context,
    WidgetRef ref,
    List<CardInstance> zoneCards,
    String deckId,
    SoloState state,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'どのカードに重ねる？',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: zoneCards.length,
              itemBuilder: (ctx2, i) {
                final target = zoneCards[i];
                final model = state.cardMap[target.cardId];
                return ListTile(
                  leading: SizedBox(
                    width: 32,
                    height: 44,
                    child: CardImageWidget(
                      imagePath: model?.imagePath,
                      faceUp: target.faceUp,
                    ),
                  ),
                  title: Text(model?.name ?? '不明なカード'),
                  subtitle: target.stackId != null
                      ? const Text('（スタック中）', style: TextStyle(fontSize: 11))
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(soloControllerProvider(deckId).notifier)
                        .stackCards(zoneKey, target.instanceId, instanceId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
