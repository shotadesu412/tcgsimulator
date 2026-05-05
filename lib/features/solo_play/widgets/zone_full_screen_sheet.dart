import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../domain/models/card_model.dart';
import '../../../domain/models/zone_def.dart';
import '../../../shared/utils/file_image_helper.dart';
import '../../../shared/widgets/card_image.dart';
import '../drag_state.dart';
import '../solo_controller.dart';
import 'card_widget.dart';

// ── OverlayEntry管理 ───────────────────────────────────────────────────────
// showModalBottomSheet を使わない理由:
//   1. ModalBarrier が背後の DragTarget を遮断する
//   2. Navigator.pop() でウィジェットが dispose → ドラッグもキャンセルされる
// → ModalBarrier なしの OverlayEntry を使い、
//    ドラッグ中は IgnorePointer で透明化して背後のゾーンにドロップできるようにする

final _activeOverlays = <String, OverlayEntry>{};

/// deckId ごとに1つのオーバーレイを管理（重複防止）
void closeZoneOverlay(String deckId) {
  _activeOverlays.remove(deckId)?.remove();
}

Future<void> showZoneFullScreen(
  BuildContext context,
  WidgetRef ref, {
  required String zoneKey,
  required String deckId,
  bool forceShowFaceUp = false,
}) async {
  // 既存を閉じてから開く
  closeZoneOverlay(deckId);

  late final OverlayEntry entry;

  void close() {
    entry.remove();
    _activeOverlays.remove(deckId);
  }

  entry = OverlayEntry(
    builder: (_) => _ZoneFullScreenOverlay(
      zoneKey: zoneKey,
      deckId: deckId,
      forceShowFaceUp: forceShowFaceUp,
      onClose: close,
    ),
  );

  _activeOverlays[deckId] = entry;
  Overlay.of(context).insert(entry);
}

// ── オーバーレイ本体 ────────────────────────────────────────────────────────

class _ZoneFullScreenOverlay extends ConsumerWidget {
  const _ZoneFullScreenOverlay({
    required this.zoneKey,
    required this.deckId,
    required this.forceShowFaceUp,
    required this.onClose,
  });

  final String zoneKey;
  final String deckId;
  final bool forceShowFaceUp;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDragging = ref.watch(isDraggingProvider);
    final asyncState = ref.watch(soloControllerProvider(deckId));

    // ドラッグ中はオーバーレイ全体を IgnorePointer + 透明にする。
    // これで背後の ZoneView DragTarget にヒットテストが届き、ドロップを受け取れる。
    // LongPressDraggable は GestureBinding.pointerRouter でポインタを追跡しているため、
    // IgnorePointer になった後もドラッグは継続する。
    return IgnorePointer(
      ignoring: isDragging,
      child: AnimatedOpacity(
        opacity: isDragging ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          children: [
            // スクリム（タップで閉じる）
            GestureDetector(
              onTap: onClose,
              child: Container(color: Colors.black54),
            ),
            // シートコンテンツ
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: MediaQuery.of(context).size.height * 0.08,
              child: Material(
                color: AppColors.surfaceDark,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: asyncState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (state) => _SheetContent(
                    zoneKey: zoneKey,
                    deckId: deckId,
                    state: state,
                    forceShowFaceUp: forceShowFaceUp,
                    onClose: onClose,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── シートのUI ─────────────────────────────────────────────────────────────

class _SheetContent extends StatelessWidget {
  const _SheetContent({
    required this.zoneKey,
    required this.deckId,
    required this.state,
    required this.forceShowFaceUp,
    required this.onClose,
  });

  final String zoneKey;
  final String deckId;
  final SoloState state;
  final bool forceShowFaceUp;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final zoneDef = state.zoneDef(zoneKey);
    final cards = state.zone(zoneKey);

    return Column(
      children: [
        // ハンドル
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.textMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // ヘッダー
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
          child: Row(
            children: [
              Text(
                zoneDef.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMid,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${cards.length}枚',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              const Spacer(),
              // ✕ 閉じるボタン
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // カードグリッド
        Expanded(
          child: cards.isEmpty
              ? const Center(
                  child: Text(
                    'カードがありません',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: kCardWidth / kCardHeight,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, i) {
                    final card = cards[i];
                    return _FullScreenCard(
                      card: card,
                      model: state.cardMap[card.cardId],
                      zoneKey: zoneKey,
                      deckId: deckId,
                      forceShowFaceUp: forceShowFaceUp,
                      onClose: onClose,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── 個々のカード ───────────────────────────────────────────────────────────

class _FullScreenCard extends ConsumerWidget {
  const _FullScreenCard({
    required this.card,
    required this.model,
    required this.zoneKey,
    required this.deckId,
    required this.forceShowFaceUp,
    required this.onClose,
  });

  final CardInstance card;
  final CardModel? model;
  final String zoneKey;
  final String deckId;
  final bool forceShowFaceUp;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayFaceUp = forceShowFaceUp ? true : card.faceUp;
    final cardWidget = CardImageWidget(
      imagePath: model?.imagePath,
      backImagePath: model?.backImagePath,
      faceUp: displayFaceUp,
      tapped: card.tapped,
      borderColor: card.stackId != null ? AppColors.primaryLight : null,
    );

    return LongPressDraggable<CardDragData>(
      data: CardDragData(
        instanceId: card.instanceId,
        fromZone: zoneKey,
        instance: card,
        cardModel: model,
      ),
      // 300ms長押し → フィードバック表示 → 指を動かすとドラッグ
      delay: const Duration(milliseconds: 300),
      onDragStarted: () {
        // isDraggingProvider を true にする
        // → _ZoneFullScreenOverlay が IgnorePointer + 透明化
        // → ModalBarrier がないので背後の DragTarget にドロップできる
        // → Navigator.pop() は不要（OverlayEntry のままで透明）
        ref.read(isDraggingProvider.notifier).state = true;
      },
      onDragCompleted: () {
        // ドロップ成功 → isDragging リセット → オーバーレイを閉じる
        ref.read(isDraggingProvider.notifier).state = false;
        onClose();
      },
      onDraggableCanceled: (_, __) {
        // キャンセル → リセット（オーバーレイは開いたまま。再試行可）
        ref.read(isDraggingProvider.notifier).state = false;
      },
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: SizedBox(
            width: kCardWidth * 1.8,
            height: kCardHeight * 1.8,
            child: CardImageWidget(
              imagePath: model?.imagePath,
              faceUp: displayFaceUp,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: cardWidget),
      child: GestureDetector(
        onTap: () => _showDetail(context, displayFaceUp),
        child: Stack(
          fit: StackFit.expand,
          children: [
            cardWidget,
            // ドラッグ可能を示すアイコン
            const Positioned(
              bottom: 3,
              right: 3,
              child: Icon(Icons.open_with, size: 11, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, bool displayFaceUp) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: AspectRatio(
              aspectRatio: 0.72,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: displayFaceUp && model?.imagePath != null
                    ? buildFileImage(model!.imagePath, fit: BoxFit.contain)
                    : Container(
                        color: AppColors.cardBack,
                        child: const Center(
                          child: Icon(
                            Icons.style,
                            color: AppColors.textMuted,
                            size: 80,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
