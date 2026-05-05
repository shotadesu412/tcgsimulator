import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../core/id.dart';
import '../../data/db/card_dao.dart';
import '../../data/storage/image_storage.dart';
import '../../domain/models/card_model.dart';
import '../../shared/widgets/card_image.dart';

// S05: カード登録/編集画面

class CardEditScreen extends ConsumerStatefulWidget {
  const CardEditScreen({super.key, required this.cardId});

  final String cardId; // 'new' or existing id

  @override
  ConsumerState<CardEditScreen> createState() => _CardEditScreenState();
}

class _CardEditScreenState extends ConsumerState<CardEditScreen> {
  final _nameController = TextEditingController();
  final _textController = TextEditingController();
  CardModel? _existing;
  Uint8List? _pickedBytes;
  Uint8List? _pickedBackBytes;
  bool _loading = false;
  Set<String> _selectedCivs = {};
  int _cost = 0;

  bool get isNew => widget.cardId == 'new';

  @override
  void initState() {
    super.initState();
    if (!isNew) {
      final card = ref.read(cardDaoProvider).findById(widget.cardId);
      if (card != null) {
        _existing = card;
        _nameController.text = card.name;
        _textController.text = card.cardText;
        _cost = card.cost;
        _selectedCivs = Set.from(card.civList);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'カード登録' : 'カード編集'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('保存'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像（任意）
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: 144,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.zoneBorder),
                  ),
                  child: _buildImagePreview(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.photo_library, size: 18),
                label: Text(_pickedBytes != null || (_existing?.imagePath.isNotEmpty ?? false)
                    ? '表面画像を変更'
                    : '表面画像を選択（任意）'),
                onPressed: _pickImage,
              ),
            ),
            const SizedBox(height: 16),

            // 裏面画像（両面カード用）
            const Text(
              '裏面画像（両面カード・超次元用、任意）',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: _pickBackImage,
                  child: Container(
                    height: 100,
                    width: 72,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.zoneBorder),
                    ),
                    child: _buildBackImagePreview(),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.photo_library, size: 16),
                      label: Text(
                        _pickedBackBytes != null ||
                                (_existing?.backImagePath.isNotEmpty ?? false)
                            ? '裏面画像を変更'
                            : '裏面画像を選択',
                        style: const TextStyle(fontSize: 13),
                      ),
                      onPressed: _pickBackImage,
                    ),
                    if (_pickedBackBytes != null ||
                        (_existing?.backImagePath.isNotEmpty ?? false))
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: AppColors.error),
                        label: const Text('裏面画像を削除',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.error)),
                        onPressed: () =>
                            setState(() => _pickedBackBytes = null),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // カード名
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'カード名 *',
                hintText: '例: ボルメテウス・ホワイト・ドラゴン',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),

            // コスト
            Row(
              children: [
                const Text('コスト', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _cost > 0 ? () => setState(() => _cost--) : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                Container(
                  width: 44,
                  alignment: Alignment.center,
                  child: Text(
                    '$_cost',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _cost++),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 文明
            const Text('文明', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: kCivilizations.map((civ) {
                final selected = _selectedCivs.contains(civ);
                final color = kCivColors[civ]!;
                return FilterChip(
                  label: Text(civ),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedCivs.add(civ);
                      } else {
                        _selectedCivs.remove(civ);
                      }
                    });
                  },
                  selectedColor: color.withValues(alpha: 0.25),
                  checkmarkColor: color,
                  labelStyle: TextStyle(
                    color: selected ? color : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: selected ? color : AppColors.zoneBorder,
                    width: selected ? 1.5 : 1,
                  ),
                  backgroundColor: AppColors.surfaceLight,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // カードテキスト
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'カードテキスト（任意）',
                hintText: '効果テキストを入力',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_pickedBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(_pickedBytes!, fit: BoxFit.cover),
      );
    }
    if (_existing != null && _existing!.imagePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CardImageWidget(imagePath: _existing!.imagePath),
      );
    }
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 40, color: AppColors.textMuted),
        SizedBox(height: 8),
        Text(
          '画像を選択\n（任意）',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() => _pickedBytes = bytes);
    }
  }

  Future<void> _pickBackImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() => _pickedBackBytes = bytes);
    }
  }

  Widget _buildBackImagePreview() {
    if (_pickedBackBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(_pickedBackBytes!, fit: BoxFit.cover),
      );
    }
    if (_existing != null && _existing!.backImagePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CardImageWidget(imagePath: _existing!.backImagePath),
      );
    }
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.flip, size: 24, color: AppColors.textMuted),
        SizedBox(height: 4),
        Text('裏面', textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カード名を入力してください')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final storage = ref.read(imageStorageProvider);
      final dao = ref.read(cardDaoProvider);

      final cardId = isNew ? generateId() : widget.cardId;
      String imagePath = _existing?.imagePath ?? '';
      String backImagePath = _existing?.backImagePath ?? '';

      if (_pickedBytes != null) {
        final result = await storage.saveBytes(cardId, _pickedBytes!);
        if (result.isOk) imagePath = result.value;
      }
      if (_pickedBackBytes != null) {
        final result = await storage.saveBytes('${cardId}_back', _pickedBackBytes!);
        if (result.isOk) backImagePath = result.value;
      } else if (_pickedBackBytes == null && (_existing?.backImagePath.isEmpty ?? true)) {
        backImagePath = '';
      }

      final civilization = _selectedCivs.join(',');

      if (isNew) {
        final card = CardModel()
          ..id = cardId
          ..name = name
          ..imagePath = imagePath
          ..createdAt = DateTime.now()
          ..tags = []
          ..civilization = civilization
          ..cost = _cost
          ..cardText = _textController.text.trim()
          ..backImagePath = backImagePath;
        await dao.upsert(card);
      } else {
        final card = _existing!
          ..name = name
          ..imagePath = imagePath
          ..civilization = civilization
          ..cost = _cost
          ..cardText = _textController.text.trim()
          ..backImagePath = backImagePath;
        await dao.upsert(card);
      }

      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
