import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../domain/models/card_model.dart';
import '../../../domain/models/zone_def.dart';
import '../../../shared/widgets/card_image.dart';
import '../drag_state.dart';

// T13: CardWidget

const double kCardWidth = 64;
const double kCardHeight = 89;

class CardWidget extends ConsumerWidget {
  const CardWidget({
    super.key,
    required this.instance,
    required this.cardModel,
    required this.zoneKey,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.isDragging = false,
    this.isSelected = false,
    this.width = kCardWidth,
    this.height = kCardHeight,
  });

  final CardInstance instance;
  final CardModel? cardModel;
  final String zoneKey;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final bool isDragging;
  final bool isSelected;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget card = SizedBox(
      width: width,
      height: height,
      child: CardImageWidget(
        imagePath: cardModel?.imagePath,
        backImagePath: cardModel?.backImagePath,
        faceUp: instance.faceUp,
        borderColor: isSelected ? AppColors.cardSelected : null,
        width: width,
        height: height,
      ),
    );

    if (instance.tapped) {
      card = RotatedBox(quarterTurns: 1, child: card);
    }

    if (instance.counters.isNotEmpty) {
      card = Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(
            top: -4,
            right: -4,
            child: _CounterBadge(counters: instance.counters),
          ),
        ],
      );
    }

    return Opacity(
      opacity: isDragging ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        child: card,
      ),
    );
  }
}

class _CounterBadge extends StatelessWidget {
  const _CounterBadge({required this.counters});

  final Map<String, int> counters;

  @override
  Widget build(BuildContext context) {
    final total = counters.values.fold(0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: AppColors.warning,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$total',
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
    );
  }
}

/// ドラッグ可能なCardWidget
class DraggableCardWidget extends ConsumerWidget {
  const DraggableCardWidget({
    super.key,
    required this.instance,
    required this.cardModel,
    required this.zoneKey,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.width = kCardWidth,
    this.height = kCardHeight,
  });

  final CardInstance instance;
  final CardModel? cardModel;
  final String zoneKey;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LongPressDraggable<CardDragData>(
      data: CardDragData(
        instanceId: instance.instanceId,
        fromZone: zoneKey,
        instance: instance,
        cardModel: cardModel,
      ),
      delay: const Duration(milliseconds: 150),
      onDragStarted: () => ref.read(isDraggingProvider.notifier).state = true,
      onDragCompleted: () => ref.read(isDraggingProvider.notifier).state = false,
      onDraggableCanceled: (_, __) => ref.read(isDraggingProvider.notifier).state = false,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: CardWidget(
            instance: instance,
            cardModel: cardModel,
            zoneKey: zoneKey,
            width: width,
            height: height,
          ),
        ),
      ),
      childWhenDragging: CardWidget(
        instance: instance,
        cardModel: cardModel,
        zoneKey: zoneKey,
        isDragging: true,
        width: width,
        height: height,
      ),
      child: CardWidget(
        instance: instance,
        cardModel: cardModel,
        zoneKey: zoneKey,
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        width: width,
        height: height,
      ),
    );
  }
}

class CardDragData {
  const CardDragData({
    required this.instanceId,
    required this.fromZone,
    required this.instance,
    required this.cardModel,
  });

  final String instanceId;
  final String fromZone;
  final CardInstance instance;
  final CardModel? cardModel;
}
