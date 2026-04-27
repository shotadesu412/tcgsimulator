import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../shared/utils/file_image_helper.dart';
import 'solo_controller.dart';
import 'widgets/card_long_press_menu.dart';
import 'widgets/circle_zone_widget.dart';
import 'widgets/zone_full_screen_sheet.dart';
import 'widgets/zone_view.dart';

// T15: S06 一人回し画面

class SoloScreen extends ConsumerWidget {
  const SoloScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // family プロバイダ — initState 不要、deckId を直接渡す
    final asyncState = ref.watch(soloControllerProvider(deckId));

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        title: const Text('一人回し'),
        backgroundColor: AppColors.surfaceDark,
        actions: [
          asyncState.whenData((s) => s).valueOrNull != null
              ? _ActionMenu(deckId: deckId, state: asyncState.value!)
              : const SizedBox.shrink(),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('エラー: $e', style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(soloControllerProvider(deckId)),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
        data: (state) => _BoardLayout(deckId: deckId, state: state),
      ),
    );
  }
}

class _ActionMenu extends ConsumerWidget {
  const _ActionMenu({required this.deckId, required this.state});

  final String deckId;
  final SoloState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(soloControllerProvider(deckId).notifier);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) async {
        switch (action) {
          case 'draw1':
            await ctrl.drawOne();
          case 'draw5':
            await ctrl.drawN(5);
          case 'revealN':
            await _revealNToPalette(context, ctrl, state);
          case 'shuffle':
            await ctrl.shuffleDeck();
          case 'untapAll':
            await ctrl.untapAll();
          case 'reset':
            if (await _confirmReset(context)) await ctrl.resetGame(deckId);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'draw1', child: Text('1枚ドロー')),
        PopupMenuItem(value: 'draw5', child: Text('5枚ドロー')),
        PopupMenuItem(value: 'revealN', child: Text('N枚パレットへ')),
        PopupMenuItem(value: 'shuffle', child: Text('山札シャッフル')),
        PopupMenuItem(value: 'untapAll', child: Text('全てアンタップ')),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'reset',
          child: Text('ゲームリセット', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }

  Future<void> _revealNToPalette(
    BuildContext context,
    SoloController ctrl,
    SoloState state,
  ) async {
    final deckCount = state.zone('deck').length;
    if (deckCount == 0) return;
    int n = 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('パレットへ'),
          content: Row(
            children: [
              const Text('枚数: '),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: n > 1 ? () => setState(() => n--) : null,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              Text('$n', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: n < deckCount ? () => setState(() => n++) : null,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('パレットへ'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) await ctrl.revealToPalette(n);
  }

  Future<bool> _confirmReset(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゲームリセット'),
        content: const Text('盤面をリセットしますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('リセット'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _BoardLayout extends ConsumerWidget {
  const _BoardLayout({required this.deckId, required this.state});

  final String deckId;
  final SoloState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(soloControllerProvider(deckId).notifier);

    ZoneView buildZone(String key) => ZoneView(
          zoneDef: state.zoneDef(key),
          cards: state.zone(key),
          cardMap: state.cardMap,
          onCardTap: (zk, id) {
            if (zk == 'deck') {
              ctrl.drawOne();
            } else {
              ctrl.toggleTap(zk, id);
            }
          },
          onCardDoubleTap: (zk, id) => _showCardDetail(context, state, zk, id),
          onCardLongPress: (zk, id) => showCardLongPressMenu(
            context, ref,
            zoneKey: zk, instanceId: id, state: state, deckId: deckId,
          ),
          onDrop: (data, toZone) => ctrl.moveCard(
            instanceId: data.instanceId,
            fromZone: data.fromZone,
            toZone: toZone,
          ),
          onZoneTap: () => showZoneFullScreen(
            context, ref,
            zoneKey: key,
            deckId: deckId,
            forceShowFaceUp: key == 'deck',
          ),
        );

    return OrientationBuilder(
      builder: (context, orientation) => orientation == Orientation.landscape
          ? _LandscapeBoard(buildZone: buildZone)
          : _PortraitBoard(
              buildZone: buildZone,
              deckId: deckId,
              state: state,
            ),
    );
  }
}

// ── レイアウト（LayoutBuilder で相対サイズ）────────────────────

class _PortraitBoard extends StatelessWidget {
  const _PortraitBoard({
    required this.buildZone,
    required this.deckId,
    required this.state,
  });

  final ZoneView Function(String) buildZone;
  final String deckId;
  final SoloState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          // バトルゾーン（大）
          Expanded(
            flex: 5,
            child: buildZone('battle'),
          ),
          const SizedBox(height: 4),
          // ○サークル | シールド
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: CircleZoneWidget(deckId: deckId, state: state),
                ),
                const SizedBox(width: 4),
                Expanded(flex: 2, child: buildZone('shield')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 山札 | 手札
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(child: buildZone('deck')),
                const SizedBox(width: 4),
                Expanded(flex: 2, child: buildZone('hand')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // マナ | 墓地
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(child: buildZone('mana')),
                const SizedBox(width: 4),
                Expanded(child: buildZone('graveyard')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LandscapeBoard extends StatelessWidget {
  const _LandscapeBoard({required this.buildZone});

  final ZoneView Function(String) buildZone;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final sideW = (w * 0.13).clamp(60.0, 100.0);

        return Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              SizedBox(
                width: sideW,
                child: Column(children: [
                  Expanded(child: buildZone('deck')),
                  const SizedBox(height: 4),
                  Expanded(child: buildZone('graveyard')),
                ]),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(children: [
                  SizedBox(
                    height: (constraints.maxHeight * 0.25).clamp(60.0, 120.0),
                    child: buildZone('shield'),
                  ),
                  const SizedBox(height: 4),
                  Expanded(child: buildZone('battle')),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: (constraints.maxHeight * 0.25).clamp(60.0, 120.0),
                    child: buildZone('mana'),
                  ),
                ]),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: sideW * 1.2,
                child: Column(children: [
                  Expanded(child: buildZone('hyper')),
                  const SizedBox(height: 4),
                  Expanded(child: buildZone('hand')),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── DualScreen（一人対戦: 2デッキ切り替え）──────────────────────────────

class DualScreen extends ConsumerStatefulWidget {
  const DualScreen({super.key, required this.deck1Id, required this.deck2Id});

  final String deck1Id;
  final String deck2Id;

  @override
  ConsumerState<DualScreen> createState() => _DualScreenState();
}

class _DualScreenState extends ConsumerState<DualScreen> {
  int _activePlayer = 0; // 0 = P1, 1 = P2

  String get _activeDeckId =>
      _activePlayer == 0 ? widget.deck1Id : widget.deck2Id;

  static const _playerColors = [
    Color(0xFF1565C0), // P1: blue
    Color(0xFFC62828), // P2: red
  ];

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(soloControllerProvider(_activeDeckId));

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _playerColors[_activePlayer],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'P${_activePlayer + 1}の盤面',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          // 盤面切り替えボタン
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor:
                    _playerColors[1 - _activePlayer].withValues(alpha: 0.25),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => setState(() => _activePlayer ^= 1),
              child: Text(
                'P${2 - _activePlayer}へ',
                style: TextStyle(
                  color: _playerColors[1 - _activePlayer],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // アクションメニュー（SoloScreenと共通）
          if (asyncState.valueOrNull != null)
            _ActionMenu(deckId: _activeDeckId, state: asyncState.value!),
        ],
      ),
      body: IndexedStack(
        index: _activePlayer,
        children: [
          _DualBoard(deckId: widget.deck1Id),
          _DualBoard(deckId: widget.deck2Id),
        ],
      ),
    );
  }
}

/// IndexedStack内でゲーム状態を維持するボード
class _DualBoard extends ConsumerWidget {
  const _DualBoard({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(soloControllerProvider(deckId));
    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('エラー: $e', style: const TextStyle(color: AppColors.error)),
      ),
      data: (state) => _BoardLayout(deckId: deckId, state: state),
    );
  }
}

// T18: カード拡大表示（Hero + Material ラッパー）
void _showCardDetail(
  BuildContext context,
  SoloState state,
  String zoneKey,
  String instanceId,
) {
  final instance = state.zone(zoneKey)
      .where((c) => c.instanceId == instanceId)
      .firstOrNull;
  if (instance == null) return;
  final model = state.cardMap[instance.cardId];

  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Center(
        child: Hero(
          tag: 'card_${instance.instanceId}',
          child: Material( // Hero内のMaterialラッパー（テキスト描画崩れ防止）
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: AspectRatio(
                aspectRatio: 0.72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: instance.faceUp && model?.imagePath != null
                      ? buildFileImage(model!.imagePath, fit: BoxFit.contain)
                      : Container(
                          color: AppColors.cardBack,
                          child: const Center(
                            child: Icon(Icons.style, color: AppColors.textMuted, size: 80),
                          ),
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
