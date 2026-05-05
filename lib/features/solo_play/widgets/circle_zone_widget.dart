import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../drag_state.dart';
import '../solo_controller.dart';
import 'card_widget.dart';
import 'zone_full_screen_sheet.dart';

// サークルゾーン: 超次元 + パレット をコンパクトに格納
// - カードドラッグ中: Overlayに超次元/パレットのドロップターゲットを展開
// - 上部に「超次元」「パレット」ボタン → タップで拡大表示

class CircleZoneWidget extends ConsumerStatefulWidget {
  const CircleZoneWidget({
    super.key,
    required this.deckId,
    required this.state,
  });

  final String deckId;
  final SoloState state;

  @override
  ConsumerState<CircleZoneWidget> createState() => _CircleZoneWidgetState();
}

class _CircleZoneWidgetState extends ConsumerState<CircleZoneWidget> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _dragOverlay;

  static const _hyperColor = Color(0xFF7E57C2);
  static const _paletteColor = Color(0xFF26A69A);

  // ── ドラッグ用 Overlay ─────────────────────────────────────

  void _showDragOverlay() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    final cx = pos.dx + size.width / 2;
    final cy = pos.dy + size.height / 2;
    const segW = 80.0;
    const segH = 36.0;
    const gap = 8.0;

    _dragOverlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // 超次元 (上)
          Positioned(
            left: cx - segW / 2,
            top: cy - size.height / 2 - segH - gap,
            width: segW,
            height: segH,
            child: _DropSegment(
              label: '超次元',
              color: _hyperColor,
              onDrop: (data) {
                _hideDragOverlay();
                ref
                    .read(soloControllerProvider(widget.deckId).notifier)
                    .moveCard(
                      instanceId: data.instanceId,
                      fromZone: data.fromZone,
                      toZone: 'hyper',
                    );
              },
            ),
          ),
          // パレット (下)
          Positioned(
            left: cx - segW / 2,
            top: cy + size.height / 2 + gap,
            width: segW,
            height: segH,
            child: _DropSegment(
              label: 'パレット',
              color: _paletteColor,
              onDrop: (data) {
                _hideDragOverlay();
                ref
                    .read(soloControllerProvider(widget.deckId).notifier)
                    .moveCard(
                      instanceId: data.instanceId,
                      fromZone: data.fromZone,
                      toZone: 'palette',
                      faceUp: true,
                    );
              },
            ),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _dragOverlay != null) {
        Overlay.of(context).insert(_dragOverlay!);
      }
    });
  }

  void _hideDragOverlay() {
    _dragOverlay?.remove();
    _dragOverlay = null;
  }

  @override
  void dispose() {
    _hideDragOverlay();
    super.dispose();
  }

  // ── ビルド ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isDraggingProvider, (prev, next) {
      if (next && prev == false) {
        _showDragOverlay();
      } else if (!next && (prev ?? false)) {
        _hideDragOverlay();
      }
    });

    final hyperCount = widget.state.zone('hyper').length;
    final paletteCount = widget.state.zone('palette').length;

    return Container(
      key: _key,
      decoration: BoxDecoration(
        color: AppColors.surfaceMid,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.zoneBorder),
      ),
      child: Column(
        children: [
          // 超次元ボタン
          Expanded(
            child: _ZoneButton(
              label: '超次元',
              count: hyperCount,
              color: _hyperColor,
              onTap: () => showZoneFullScreen(
                context, ref,
                zoneKey: 'hyper',
                deckId: widget.deckId,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.zoneBorder),
          // パレットボタン
          Expanded(
            child: _ZoneButton(
              label: 'パレット',
              count: paletteCount,
              color: _paletteColor,
              onTap: () => showZoneFullScreen(
                context, ref,
                zoneKey: 'palette',
                deckId: widget.deckId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ゾーンボタン ──────────────────────────────────────────────

class _ZoneButton extends StatelessWidget {
  const _ZoneButton({
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ドロップセグメント（Overlay内、ドラッグ時に表示）────────────────────

class _DropSegment extends StatelessWidget {
  const _DropSegment({
    required this.label,
    required this.color,
    required this.onDrop,
  });

  final String label;
  final Color color;
  final void Function(CardDragData) onDrop;

  @override
  Widget build(BuildContext context) {
    return DragTarget<CardDragData>(
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (ctx, candidates, _) {
        final isHover = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isHover
                ? color.withValues(alpha: 0.8)
                : color.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHover ? Colors.white : color,
              width: isHover ? 2 : 1,
            ),
            boxShadow: isHover
                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: isHover ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}
