import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../deck/deck_select_dialog.dart';

// S01: ホーム画面

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BoardKit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              _HomeButton(
                icon: Icons.person,
                label: '一人回し',
                color: AppColors.primary,
                onTap: () => _startSolo(context),
              ),
              const SizedBox(height: 12),
              _HomeButton(
                icon: Icons.swap_horiz,
                label: '一人対戦（2デッキ）',
                color: const Color(0xFF1A237E),
                onTap: () => _startDual(context),
              ),
              const SizedBox(height: 12),
              _HomeButton(
                icon: Icons.people,
                label: '対戦',
                color: AppColors.primaryLight,
                onTap: () => context.push(AppRoutes.versusLobby),
              ),
              const SizedBox(height: 16),
              _HomeButton(
                icon: Icons.library_books,
                label: 'デッキ管理',
                color: AppColors.surfaceLight,
                onTap: () => context.push(AppRoutes.deckList),
              ),
              const SizedBox(height: 16),
              _HomeButton(
                icon: Icons.style,
                label: 'カードライブラリ',
                color: AppColors.surfaceLight,
                onTap: () => context.push(AppRoutes.cardLibrary),
              ),
              const Spacer(),
              // 広告枠予約 (AdMob用)
              const _AdPlaceholder(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startSolo(BuildContext context) async {
    final deckId = await showDeckSelectDialog(context);
    if (deckId != null && context.mounted) {
      context.push('/solo/$deckId');
    }
  }

  Future<void> _startDual(BuildContext context) async {
    final deck1Id = await showDeckSelectDialog(
      context,
      title: 'P1のデッキを選択',
    );
    if (deck1Id == null || !context.mounted) return;

    final deck2Id = await showDeckSelectDialog(
      context,
      title: 'P2のデッキを選択',
    );
    if (deck2Id == null || !context.mounted) return;

    context.push('/dual/$deck1Id/$deck2Id');
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        icon: Icon(icon, size: 28),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}

class _AdPlaceholder extends StatelessWidget {
  const _AdPlaceholder();

  @override
  Widget build(BuildContext context) {
    // TODO: AdMob banner insertion point
    return const SizedBox(height: 56);
  }
}
