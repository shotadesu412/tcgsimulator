import 'package:flutter_riverpod/flutter_riverpod.dart';

/// カードをドラッグ中かどうかのグローバル状態
final isDraggingProvider = StateProvider<bool>((ref) => false);
