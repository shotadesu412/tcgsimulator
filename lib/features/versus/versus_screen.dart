import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';

// S08: 対戦プレイ画面 — T25-T26 (Phase 5 スタブ)

class VersusScreen extends ConsumerWidget {
  const VersusScreen({super.key, required this.roomCode});

  final String roomCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('対戦 #$roomCode')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text(
              '対戦機能はPhase 5で実装予定',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
