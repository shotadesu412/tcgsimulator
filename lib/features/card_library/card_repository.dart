import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/card_dao.dart';
import '../../domain/models/card_model.dart';

class CardRepository {
  CardRepository(this._dao);
  final CardDao _dao;

  List<CardModel> findAll() => _dao.findAll();
  CardModel? findById(String id) => _dao.findById(id);
}

final cardRepositoryProvider = Provider<CardRepository>(
  (ref) => CardRepository(ref.watch(cardDaoProvider)),
);
