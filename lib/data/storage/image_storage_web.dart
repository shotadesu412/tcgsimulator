import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../core/logger.dart';
import '../../core/result.dart';

const _kMaxLongEdge = 1024;

class ImageStorageImpl {
  Future<Result<String>> saveBytes(String cardId, Uint8List bytes) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return Err(const FormatException('デコード失敗'));

      final longEdge =
          decoded.width > decoded.height ? decoded.width : decoded.height;
      final Uint8List resized;
      if (longEdge <= _kMaxLongEdge) {
        resized = Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
      } else {
        final scale = _kMaxLongEdge / longEdge;
        final r = img.copyResize(
          decoded,
          width: (decoded.width * scale).round(),
          height: (decoded.height * scale).round(),
        );
        resized = Uint8List.fromList(img.encodeJpg(r, quality: 85));
      }
      // WebではDataURLとして返す
      final dataUrl = 'data:image/jpeg;base64,${base64Encode(resized)}';
      return Ok(dataUrl);
    } catch (e, st) {
      AppLogger.e('Image save failed (web)', error: e, stackTrace: st);
      return Err(e);
    }
  }

  Future<void> delete(String cardId) async {
    // Web: Hive側でCardModelのimagePathを空にする処理はDAO層で行う
  }
}
