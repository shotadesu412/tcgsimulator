import 'dart:io';
import 'package:flutter/widgets.dart';

Widget buildFileImage(String path, {BoxFit fit = BoxFit.cover}) {
  return Image.file(
    File(path),
    fit: fit,
    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
  );
}

bool isFileUri(String path) =>
    !path.startsWith('http') && !path.startsWith('data:');
