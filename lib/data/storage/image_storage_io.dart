import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/logger.dart';
import '../../core/result.dart';

const _kMaxLongEdge = 1024;

class ImageStorageImpl {
  static Directory? _dir;

  static Future<Directory> _getDir() async {
    _dir ??= Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'card_images'),
    );
    if (!await _dir!.exists()) await _dir!.create(recursive: true);
    return _dir!;
  }

  Future<Result<String>> saveBytes(String cardId, Uint8List bytes) async {
    try {
      final resized = await _resize(bytes);
      final dir = await _getDir();
      final dest = File(p.join(dir.path, '$cardId.jpg'));
      await dest.writeAsBytes(resized);
      return Ok(dest.path);
    } catch (e, st) {
      AppLogger.e('Image save failed', error: e, stackTrace: st);
      return Err(e);
    }
  }

  Future<void> delete(String cardId) async {
    try {
      final dir = await _getDir();
      final file = File(p.join(dir.path, '$cardId.jpg'));
      if (await file.exists()) await file.delete();
    } catch (e) {
      AppLogger.w('Image delete failed', error: e);
    }
  }

  static Future<Uint8List> _resize(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw const FormatException('画像デコード失敗');
    final longEdge =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    if (longEdge <= _kMaxLongEdge) {
      return Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
    }
    final scale = _kMaxLongEdge / longEdge;
    final resized = img.copyResize(
      decoded,
      width: (decoded.width * scale).round(),
      height: (decoded.height * scale).round(),
    );
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }
}
