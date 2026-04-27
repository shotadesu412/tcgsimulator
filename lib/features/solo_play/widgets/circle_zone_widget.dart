import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../drag_state.dart';
import '../solo_controller.dart';
import 'card_widget.dart';
import 'zone_full_screen_sheet.dart';

// サークルゾーン: 超次元 + パレット をコンパクトに格納
// - カードドラッグ中: Overlayに超次元/パレットのドロップターゲットを展開
// - 長押し + スライド: 方向でゾーンを選択して全画面表示

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

  // 長押しラジアル状態
  bool _lpExpanded = false;
  String? _lpZone; // 現在ハイライト中のゾーン

  // ゾーン定義（角度 = atan2空間、0=右、-π/2=上、π/2=下）
  static const _zones = [
    _ZoneDef(key: 'hyper', label: '超次元', angle: -pi / 2, color: Color(0xFF7E57C2)),
    _ZoneDef(key: 'palette', label: 'パレット', angle: pi / 2, color: Color(0xFF26A69A)),
  ];

  String? _angleToZone(Offset offset) {
    if (offset.distance < 20) return null;
    final angle = offset.direction;
    double minDiff = double.infinity;
    String? best;
    for (final z in _zones) {
      var diff = (z.angle - angle).abs();
      if (diff > pi) diff = 2 * pi - diff;
      if (diff < minDiff) {
        minDiff = diff;
        best = z.key;
      }
    }
    return best;
  }

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
              zoneDef: _zones[0],
              onDrop: (data) {
                _hideDragOverlay();
                ref.read(soloControllerProvider(widget.deckId).notifier).moveCard(
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
              zoneDef: _zones[1],
              onDrop: (data) {
                _hideDragOverlay();
                ref.read(soloControllerProvider(widget.deckId).notifier).moveCard(
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

    return GestureDetector(
      key: _key,
      onLongPressStart: (d) {
        setState(() {
          _lpExpanded = true;
          _lpZone = null;
        });
      },
      onLongPressMoveUpdate: (d) {
        final zone = _angleToZone(d.localOffsetFromOrigin);
        setState(() => _lpZone = zone);
      },
      onLongPressEnd: (d) {
        final zone = _lpZone;
        setState(() {
          _lpExpanded = false;
          _lpZone = null;
        });
        if (zone != null && context.mounted) {
          showZoneFullScreen(context, ref, zoneKey: zone, deckId: widget.deckId);
        }
      },
      onLongPressCancel: () {
        setState(() {
          _lpExpanded = false;
          _lpZone = null;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceMid,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.zoneBorder),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── 長押し展開時のラベル ───────────────────────
            if (_lpExpanded) ...[
              // 上: 超次元
              Positioned(
                top: 4,
                left: 0,
                right: 0,
                child: _LpLabel(
                  zoneDef: _zones[0],
                  highlighted: _lpZone == 'hyper',
                ),
              ),
              // 下: パレット
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: _LpLabel(
                  zoneDef: _zones[1],
                  highlighted: _lpZone == 'palette',
                ),
              ),
            ],
            // ── 通常表示 ───────────────────────────────────
            if (!_lpExpanded)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.blur_circular, size: 18, color: AppColors.textMuted),
                  const SizedBox(height: 4),
                  _ZoneChip(
                    label: '超次元',
                    count: hyperCount,
                    color: _zones[0].color,
                  ),
                  const SizedBox(height: 3),
                  _ZoneChip(
                    label: 'パレット',
                    count: paletteCount,
                    color: _zones[1].color,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '長押し',
                    style: TextStyle(fontSize: 8, color: AppColors.textMuted),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── ドロップセグメント（Overlay内、ドラッグ時に表示）────────────────────

class _DropSegment extends StatelessWidget {
  const _DropSegment({required this.zoneDef, required this.onDrop});

  final _ZoneDef zoneDef;
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
                ? zoneDef.color.withValues(alpha: 0.8)
                : zoneDef.color.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHover ? Colors.white : zoneDef.color,
              width: isHover ? 2 : 1,
            ),
            boxShadow: isHover
                ? [BoxShadow(color: zoneDef.color.withValues(alpha: 0.5), blurRadius: 8)]
                : null,
          ),
          child: Center(
            child: Text(
              zoneDef.label,
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

// ── 長押し時のラベル ───────────────────────────────────────────────────

class _LpLabel extends StatelessWidget {
  const _LpLabel({required this.zoneDef, required this.highlighted});
  final _ZoneDef zoneDef;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: highlighted
            ? zoneDef.color.withValues(alpha: 0.85)
            : zoneDef.color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlighted ? Colors.white : zoneDef.color,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          zoneDef.label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── 通常時のゾーンチップ ──────────────────────────────────────────────

class _ZoneChip extends StatelessWidget {
  const _ZoneChip({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              '$label $count',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ゾーン定義（内部データ）────────────────────────────────────────────

class _ZoneDef {
  const _ZoneDef({
    required this.key,
    required this.label,
    required this.angle,
    required this.color,
  });
  final String key;
  final String label;
  final double angle;
  final Color color;
}
