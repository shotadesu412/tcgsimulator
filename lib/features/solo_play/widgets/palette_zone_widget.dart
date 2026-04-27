import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../domain/models/card_model.dart';
import '../../../domain/models/zone_def.dart';
import '../../../shared/widgets/card_image.dart';
import '../solo_controller.dart';
import 'card_widget.dart';

class PaletteZoneWidget extends ConsumerWidget {
  const PaletteZoneWidget({
    super.key,
    required this.deckId,
    required this.cards,
    required this.cardMap,
  });

  final String deckId;
  final List<CardInstance> cards;
  final Map<String, CardModel> cardMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(soloControllerProvider(deckId).notifier);

    return DragTarget<CardDragData>(
      onAcceptWithDetails: (details) {
        if (details.data.fromZone != 'palette') {
          ctrl.moveCard(
            instanceId: details.data.instanceId,
            fromZone: details.data.fromZone,
            toZone: 'palette',
            faceUp: true,
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHover = candidateData.isNotEmpty;
        return _PaletteBody(
          deckId: deckId,
          cards: cards,
          cardMap: cardMap,
          ctrl: ctrl,
          isHover: isHover,
        );
      },
    );
  }
}

class _PaletteBody extends StatelessWidget {
  const _PaletteBody({
    required this.deckId,
    required this.cards,
    required this.cardMap,
    required this.ctrl,
    required this.isHover,
  });

  final String deckId;
  final List<CardInstance> cards;
  final Map<String, CardModel> cardMap;
  final SoloController ctrl;
  final bool isHover;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isHover
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.zoneBackground,
        border: Border.all(
          color: isHover ? AppColors.primary : AppColors.zoneBorder,
          width: isHover ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: const BoxDecoration(
              color: AppColors.surfaceMid,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                const Text(
                  'パレット',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${cards.length}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const Spacer(),
                if (cards.isNotEmpty) ...[
                  _HeaderButton(
                    label: '↑全',
                    onTap: () => ctrl.allPaletteToTop(),
                  ),
                  const SizedBox(width: 4),
                  _HeaderButton(
                    label: '↓全',
                    onTap: () => ctrl.allPaletteToBottom(),
                  ),
                ],
              ],
            ),
          ),
          // Cards
          Expanded(
            child: cards.isEmpty
                ? const Center(
                    child: Icon(Icons.style_outlined, color: AppColors.textMuted, size: 20),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final cardH = (constraints.maxHeight - 26).clamp(28.0, kCardHeight);
                      final cardW = cardH * (kCardWidth / kCardHeight);
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final card in cards)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: _PaletteCard(
                                  card: card,
                                  model: cardMap[card.cardId],
                                  cardW: cardW,
                                  cardH: cardH,
                                  onToTop: () => ctrl.paletteToTop(card.instanceId),
                                  onToBottom: () => ctrl.paletteToBottom(card.instanceId),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.card,
    required this.model,
    required this.cardW,
    required this.cardH,
    required this.onToTop,
    required this.onToBottom,
  });

  final CardInstance card;
  final CardModel? model;
  final double cardW;
  final double cardH;
  final VoidCallback onToTop;
  final VoidCallback onToBottom;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: cardW,
          height: cardH,
          child: CardImageWidget(
            imagePath: model?.imagePath,
            faceUp: card.faceUp,
            width: cardW,
            height: cardH,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SmallButton(icon: Icons.vertical_align_top, onTap: onToTop),
            _SmallButton(icon: Icons.vertical_align_bottom, onTap: onToBottom),
          ],
        ),
      ],
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 14, color: AppColors.textSecondary),
      ),
    );
  }
}
