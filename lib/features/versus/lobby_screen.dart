import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

// S07: 対戦ロビー — T23 (Phase 5)
// MVP フェーズでは UI スタブのみ。Firebase実装はT22-T25。

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('対戦')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('ルームを作成'),
              onPressed: _createRoom,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            const Text('ルームコードで参加', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                hintText: '6桁のコードを入力',
                prefixIcon: Icon(Icons.vpn_key),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(6),
              ],
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _joinRoom,
              child: const Text('参加'),
            ),
            const Spacer(),
            const Text(
              '※ 対戦機能はPhase 5で実装予定です',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _createRoom() {
    // TODO T23: Firebase anonymous auth + Firestore room creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('対戦機能は準備中です')),
    );
  }

  void _joinRoom() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('6桁のコードを入力してください')),
      );
      return;
    }
    // TODO T23: join room
    context.push('/versus/$code');
  }
}
