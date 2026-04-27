import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/result.dart';

// プラットフォーム別実装を条件付きimport
import 'image_storage_web.dart'
    if (dart.library.io) 'image_storage_io.dart';

// T06: ローカル画像ストレージ（Web/モバイル共通インターフェース）

class ImageStorage {
  final _impl = ImageStorageImpl();

  /// 画像バイト列を保存してパス（またはdata URL）を返す
  Future<Result<String>> saveBytes(String cardId, Uint8List bytes) =>
      _impl.saveBytes(cardId, bytes);

  /// カード画像を削除
  Future<void> delete(String cardId) => _impl.delete(cardId);
}

final imageStorageProvider = Provider<ImageStorage>((ref) => ImageStorage());
