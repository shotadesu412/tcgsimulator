import 'dart:convert';
import 'package:flutter/widgets.dart';

Widget buildFileImage(String path, {BoxFit fit = BoxFit.cover}) {
  if (path.startsWith('data:')) {
    try {
      final base64Str = path.split(',').last;
      final bytes = base64Decode(base64Str);
      return Image.memory(bytes, fit: fit,
          errorBuilder: (_, __, ___) => const SizedBox.shrink());
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
  // ネットワーク URL
  if (path.startsWith('http')) {
    return Image.network(path, fit: fit,
        errorBuilder: (_, __, ___) => const SizedBox.shrink());
  }
  return const SizedBox.shrink();
}

bool isFileUri(String path) => false;
