import 'package:sqflite/sqflite.dart';

import '../../domain/models/deck.dart';
import '../services/app_database.dart';
import 'settings_repository.dart';

/// A [SettingsRepository] backed by SQLite, sharing the connection opened by
/// [AppDatabase].
///
/// Reads and writes the single row [AppDatabase.settingsRowId], which the
/// schema seeds. Nothing here creates that row: a missing one would mean the
/// database was not opened through [AppDatabase], and quietly inventing it
/// would hide that.
class SqfliteSettingsRepository implements SettingsRepository {
  const SqfliteSettingsRepository(this._database);

  final Database _database;

  static const _table = AppDatabase.settingsTable;

  @override
  Future<String> getActiveDeckId() async {
    final rows = await _database.query(
      _table,
      columns: ['activeDeckId'],
      where: 'id = ?',
      whereArgs: [AppDatabase.settingsRowId],
      limit: 1,
    );

    if (rows.isEmpty) return defaultDeckId;
    return rows.single['activeDeckId']! as String;
  }

  @override
  Future<void> setActiveDeckId(String deckId) async {
    if (deckId.isEmpty) {
      throw ArgumentError.value(deckId, 'deckId', 'Must not be empty.');
    }

    await _database.update(
      _table,
      {'activeDeckId': deckId},
      where: 'id = ?',
      whereArgs: [AppDatabase.settingsRowId],
    );
  }
}
