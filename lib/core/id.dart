import 'package:uuid/uuid.dart';

// T03: ID生成
const _uuid = Uuid();

String generateId() => _uuid.v4();
