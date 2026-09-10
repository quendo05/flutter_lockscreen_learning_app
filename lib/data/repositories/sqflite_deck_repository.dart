import 'package:sqflite/sqflite.dart';

import '../../domain/models/deck.dart';
import '../services/app_database.dart';
import 'deck_repository.dart';

/// A [DeckRepository] backed by SQLite, sharing the connection opened by
/// [AppDatabase].
class SqfliteDeckRepository implements DeckRepository {
  const SqfliteDeckRepository(this._database);

  final Database _database;

  static const _table = AppDatabase.decksTable;

  @override
  Future<List<Deck>> getAll() async {
    final rows = await _database.query(_table, orderBy: 'createdAt ASC');
    return rows.map(Deck.fromMap).toList();
  }

  @override
  Future<Deck?> getById(String id) async {
    final rows = await _database.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Deck.fromMap(rows.single);
  }

  @override
  Future<void> save(Deck deck) async {
    await _database.insert(
      _table,
      deck.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
