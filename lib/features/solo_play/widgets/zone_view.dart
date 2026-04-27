import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../domain/models/card_model.dart';
import '../../../domain/models/zone_def.dart';
import 'card_widget.dart';

// T12: ZoneView — ZoneDefを受けて描画

typedef OnCardTap = void Function(String zoneKey, String instanceId);
typedef OnCardDoubleTap = void Function(String zoneKey, String instanceId);
typedef OnCardLongPress = void Function(String zoneKey, String instanceId);
typedef OnCardDrop = void Function(CardDragData data, String toZone);

class ZoneView extends ConsumerWidget {
  const ZoneView({
    super.key,
    required this.zoneDef,
    required this.cards,
    required this.cardMap,
    this.onCardTap,
    this.onCardDoubleTap,
    this.onCardLongPress,
    this.onDrop,
    this.onZoneTap,
  });

  final ZoneDef zoneDef;
  final List<CardInstance> cards;
  final Map<String, CardModel> cardMap;
  final OnCardTap? onCardTap;
  final OnCardDoubleTap? onCardDoubleTap;
  final OnCardLongPress? onCardLongPress;
  final OnCardDrop? onDrop;
  final VoidCallback? onZoneTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<CardDragData>(
      onAcceptWithDetails: (details) {
        if (details.data.fromZone != zoneDef.key) {
          onDrop?.call(details.data, zoneDef.key);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHover = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: isHover
                ? AppColors.zoneBorderHighlight.withValues(alpha: 0.15)
                : AppColors.zoneBackground,
            border: Border.all(
              color: isHover ? AppColors.zoneBorderHighlight : AppColors.zoneBorder,
              width: isHover ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ZoneHeader(
                zoneDef: zoneDef,
                cardCount: cards.length,
                onTap: onZoneTap,
              ),
              Expanded(child: _buildLayout()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLayout() {
    // 手札はスナップスクロール（ポケポケ風）
    if (zoneDef.key == 'hand') {
      return _HandLayout(
        cards: cards,
        cardMap: cardMap,
        zoneKey: zoneDef.key,
        onTap: onCardTap,
        onDoubleTap: onCardDoubleTap,
        onLongPress: onCardLongPress,
      );
    }
    // 墓地・シールドはスライドしてカードを探せるようファンレイアウトに統一
    final useScroll = zoneDef.key == 'graveyard' || zoneDef.key == 'shield';
    if (useScroll) {
      return _FanLayout(
        cards: cards,
        cardMap: cardMap,
        zoneKey: zoneDef.key,
        onTap: onCardTap,
        onDoubleTap: onCardDoubleTap,
        onLongPress: onCardLongPress,
      );
    }
    return switch (zoneDef.layout) {
      ZoneLayout.stack => _StackLayout(
          cards: cards,
          cardMap: cardMap,
          zoneKey: zoneDef.key,
          onTap: onCardTap,
          onDoubleTap: onCardDoubleTap,
          onLongPress: onCardLongPress,
        ),
      ZoneLayout.fan => _FanLayout(
          cards: cards,
          cardMap: cardMap,
          zoneKey: zoneDef.key,
          onTap: onCardTap,
          onDoubleTap: onCardDoubleTap,
          onLongPress: onCardLongPress,
        ),
      ZoneLayout.grid => _GridLayout(
          cards: cards,
          cardMap: cardMap,
          zoneKey: zoneDef.key,
          onTap: onCardTap,
          onDoubleTap: onCardDoubleTap,
          onLongPress: onCardLongPress,
        ),
      ZoneLayout.free => _FreeLayout(
          cards: cards,
          cardMap: cardMap,
          zoneKey: zoneDef.key,
          onTap: onCardTap,
          onDoubleTap: onCardDoubleTap,
          onLongPress: onCardLongPress,
        ),
    };
  }
}

class _ZoneHeader extends StatelessWidget {
  const _ZoneHeader({
    required this.zoneDef,
    required this.cardCount,
    this.onTap,
  });

  final ZoneDef zoneDef;
  final int cardCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(
          color: AppColors.surfaceMid,
          borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
        ),
        child: Row(
          children: [
            Text(
              zoneDef.label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '$cardCount',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
            if (onTap != null)
              const Icon(Icons.list, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Layouts ────────────────────────────────────────────────────────────────

class _StackLayout extends StatelessWidget {
  const _StackLayout({
    required this.cards,
    required this.cardMap,
    required this.zoneKey,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  final List<CardInstance> cards;
  final Map<String, CardModel> cardMap;
  final String zoneKey;
  final OnCardTap? onTap;
  final OnCardDoubleTap? onDoubleTap;
  final OnCardLongPress? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Center(
        child: Icon(Icons.layers, color: AppColors.textMuted, size: 28),
      );
    }

    // 上から3枚分オフセットして重ねて表示
    final top = cards.last;
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (cards.length >= 3)
            Transform.translate(
              offset: const Offset(4, 4),
              child: Opacity(
                opacity: 0.4,
                child: _smallCard(cards[cards.length - 3]),
              ),
            ),
          if (cards.length >= 2)
            Transform.translate(
              offset: const Offset(2, 2),
              child: Opacity(
                opacity: 0.7,
                child: _smallCard(cards[cards.length - 2]),
              ),
            ),
          DraggableCardWidget(
            instance: top,
            cardModel: cardMap[top.cardId],
            zoneKey: zoneKey,
            onTap: () => onTap?.call(zoneKey, top.instanceId),
            onDoubleTap: () => onDoubleTap?.call(zoneKey, top.instanceId),
            onLongPress: () => onLongPress?.call(zoneKey, top.instanceId),
          ),
        ],
      ),
    );
  }

  Widget _smallCard(CardInstance c) {
    return CardWidget(
      instance: c,
      cardModel: cardMap[c.cardId],
      zoneKey: zoneKey,
    );
  }
}

class _FanLayout extends StatelessWidget {
  const _FanLayout({
    required this.cards,
    required this.cardMap,
    required this.zoneKey,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  final List<CardInstance> cards;
  final Map<String, CardModel> cardMap;
  final String zoneKey;
  final OnCardTap? onTap;
  final OnCardDoubleTap? onDoubleTap;
  final OnCardLongPress? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Center(
        child: Icon(Icons.style, color: AppColors.textMuted, size: 28),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardH = (constraints.maxHeight - 8).clamp(30.0, kCardHeight);
        final cardW = cardH * (kCardWidth / kCardHeight);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (final card in cards)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: DraggableCardWidget(
                    instance: card,
                    cardModel: cardMap[card.cardId],
                    zoneKey: zoneKey,
                    width: cardW,
                    height: cardH,
                    onTap: () => onTap?.call(zoneKey, card.instanceId),
                    onDoubleTap: () => onDoubleTap?.call(zoneKey, card.instanceId),
                    onLongPress: () => onLongPress?.call(zoneKey, card.instanceId),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── 手札スナップスクロール（ポケポケ風）────────────────────────────────────────

class _HandLayout extends StatelessWidget {
  const _HandLayout({
    required this.cards,
    required this.cardMap,
    required this.zoneKey,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  final List<CardInstance> cards;
  final Map<String, CardModel> cardMap;
  final String zoneKey;
  final OnCardTap? onTap;
  final OnCardDoubleTap? onDoubleTap;
  final OnCardLongPress? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Center(
        child: Icon(Icons.style, color: AppColors.textMuted, size: 28),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardH = (constraints.maxHeight - 8).clamp(30.0, kCardHeight);
        final cardW = cardH * (kCardWidth / kCardHeight);
        // 1ページ = 1枚分の幅でスナップ
        final fraction = ((cardW + 12) / constraints.maxWidth).clamp(0.05, 0.9);
        return PageView.builder(
          controller: PageController(viewportFraction: fraction),
          physics: const BouncingScrollPhysics(),
          itemCount: cards.length,
          itemBuilder: (context, i) {
            final card = cards[i];
            return Center(
              child: DraggableCardWidget(
                instance: card,
                cardModel: cardMap[card.cardId],
                zoneKey: zoneKey,
                width: cardW,
                height: cardH,
                onTap: () => onTap?.call(zoneKey, card.instanceId),
                onDoubleTap: () => onDoubleTap?.call(zoneKey, card.instanceId),
                onLongPress: () => onLongPress?.call(zoneKey, card.instanceId),
              ),
            );
          },
        );
      },
    );
  }
}

class _GridLayout extends StatelessWidget {
  const _GridLayout({
    required this.cards,
    required this.cardMap,
    required this.zoneKey,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  final List<CardInstance> cards;
  final Map<String, CardModel> cardMap;
  final String zoneKey;
  final OnCardTap? onTap;
  final OnCardDoubleTap? onDoubleTap;
  final OnCardLongPress? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Center(
        child: Icon(Icons.grid_on, color: AppColors.textMuted, size: 28),
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final card in cards)
          DraggableCardWidget(
            instance: card,
            cardModel: cardMap[card.cardId],
            zoneKey: zoneKey,
            onTap: () => onTap?.call(zoneKey, card.instanceId),
            onDoubleTap: () => onDoubleTap?.call(zoneKey, card.instanceId),
            onLongPress: () => onLongPress?.call(zoneKey, card.instanceId),
          ),
      ],
    );
  }
}

class _FreeLayout extends StatelessWidget {
  const _FreeLayout({
    required this.cards,
    required this.cardMap,
    required this.zoneKey,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  final List<CardInstance> cards;
  final Map<String, CardModel> cardMap;
  final String zoneKey;
  final OnCardTap? onTap;
  final OnCardDoubleTap? onDoubleTap;
  final OnCardLongPress? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Center(
        child: Icon(Icons.open_with, color: AppColors.textMuted, size: 28),
      );
    }

    // スタックごとにグループ化
    final stacks = <String, List<CardInstance>>{};
    final soloCards = <CardInstance>[];
    for (final card in cards) {
      if (card.stackId != null) {
        stacks.putIfAbsent(card.stackId!, () => []).add(card);
      } else {
        soloCards.add(card);
      }
    }
    for (final stack in stacks.values) {
      stack.sort((a, b) => a.stackIndex.compareTo(b.stackIndex));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int soloIdx = 0;
        return Stack(
          children: [
            // 単体カード
            for (var i = 0; i < soloCards.length; i++)
              Positioned(
                left: (soloCards[i].position?.x ??
                        ((i % 3) * (kCardWidth + 6)))
                    .clamp(0, (constraints.maxWidth - kCardWidth).clamp(0, double.infinity)),
                top: (soloCards[i].position?.y ??
                        ((i ~/ 3) * (kCardHeight + 6)))
                    .clamp(0, (constraints.maxHeight - kCardHeight).clamp(0, double.infinity)),
                child: DraggableCardWidget(
                  instance: soloCards[i],
                  cardModel: cardMap[soloCards[i].cardId],
                  zoneKey: zoneKey,
                  onTap: () => onTap?.call(zoneKey, soloCards[i].instanceId),
                  onDoubleTap: () => onDoubleTap?.call(zoneKey, soloCards[i].instanceId),
                  onLongPress: () => onLongPress?.call(zoneKey, soloCards[i].instanceId),
                ),
              ),
            // スタック
            for (final entry in stacks.entries)
              _StackPile(
                cards: entry.value,
                cardMap: cardMap,
                zoneKey: zoneKey,
                constraints: constraints,
                onTap: onTap,
                onDoubleTap: onDoubleTap,
                onLongPress: onLongPress,
              ),
          ],
        );
      },
    );
  }
}

class _StackPile extends StatelessWidget {
  const _StackPile({
    required this.cards,
    required this.cardMap,
    required this.zoneKey,
    required this.constraints,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  final List<CardInstance> cards; // stackIndexで昇順ソート済み
  final Map<String, CardModel> cardMap;
  final String zoneKey;
  final BoxConstraints constraints;
  final OnCardTap? onTap;
  final OnCardDoubleTap? onDoubleTap;
  final OnCardLongPress? onLongPress;

  @override
  Widget build(BuildContext context) {
    final top = cards.last;
    final pos = top.position;
    final left = (pos?.x ?? 0).clamp(0.0, constraints.maxWidth - kCardWidth);
    final topPos = (pos?.y ?? 0).clamp(0.0, constraints.maxHeight - kCardHeight);

    return Positioned(
      left: left,
      top: topPos,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 下のカードを少しずらして見せる
          for (var i = 0; i < cards.length - 1; i++)
            Positioned(
              left: (cards.length - 1 - i) * 3.0,
              top: -(cards.length - 1 - i) * 3.0,
              child: Opacity(
                opacity: 0.55,
                child: CardWidget(
                  instance: cards[i],
                  cardModel: cardMap[cards[i].cardId],
                  zoneKey: zoneKey,
                ),
              ),
            ),
          // 一番上のカード（操作可能）
          DraggableCardWidget(
            instance: top,
            cardModel: cardMap[top.cardId],
            zoneKey: zoneKey,
            onTap: () => onTap?.call(zoneKey, top.instanceId),
            onDoubleTap: () => onDoubleTap?.call(zoneKey, top.instanceId),
            onLongPress: () => onLongPress?.call(zoneKey, top.instanceId),
          ),
          // 枚数バッジ
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${cards.length}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
