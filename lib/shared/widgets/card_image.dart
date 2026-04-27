import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../utils/file_image_helper.dart';

// 共通カード画像ウィジェット（Web/モバイル両対応）

class CardImageWidget extends StatelessWidget {
  const CardImageWidget({
    super.key,
    this.imagePath,
    this.imageUrl,
    this.faceUp = true,
    this.tapped = false,
    this.borderColor,
    this.width,
    this.height,
  });

  final String? imagePath;
  final String? imageUrl;
  final bool faceUp;
  final bool tapped;
  final Color? borderColor;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (!faceUp) {
      image = _cardBack();
    } else if (imagePath != null && imagePath!.isNotEmpty) {
      image = buildFileImage(imagePath!, fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      image = Image.network(imageUrl!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    } else {
      image = _placeholder();
    }

    Widget result = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: image,
    );

    if (borderColor != null) {
      result = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor!, width: 2),
        ),
        child: result,
      );
    }

    return SizedBox(width: width, height: height, child: result);
  }

  Widget _cardBack() => Container(
        color: AppColors.cardBack,
        child: const Center(
          child: Icon(Icons.style, color: AppColors.textMuted, size: 32),
        ),
      );

  Widget _placeholder() => Container(
        color: AppColors.surfaceLight,
        child: const Center(
          child: Icon(Icons.image_not_supported, color: AppColors.textMuted),
        ),
      );
}
