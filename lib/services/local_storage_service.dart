import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalStorageService {
  static Database? _database;

  // Provides a singleton SQLite database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialises the local SQLite database for offline message storage
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pingpal_chat.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY,
            trailId TEXT,
            userId TEXT,
            text TEXT,
            timestamp INTEGER,
            isSentByMe INTEGER
          )
        ''');
      },
    );
  }

  // Saves a chat message locally for offline access
  static Future<void> saveMessage(Map<String, dynamic> msg) async {
    final db = await database;
    await db.insert(
      'messages',
      msg,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Retrieves all messages for a specific Pingtrail in chronological order
  static Future<List<Map<String, dynamic>>> getMessagesForTrail(String trailId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'trailId = ?',
      whereArgs: [trailId],
      orderBy: 'timestamp ASC',
    );
  }

  // Gets the most recent message timestamp for incremental sync
  static Future<int?> getLastTimestamp(String trailId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      columns: ['timestamp'],
      where: 'trailId = ?',
      whereArgs: [trailId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['timestamp'] as int;
    }
    return null;
  }

  // Clears all locally stored messages
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('messages');
  }
}
