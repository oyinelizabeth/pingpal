import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalStorageService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

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

  static Future<void> saveMessage(Map<String, dynamic> msg) async {
    final db = await database;
    await db.insert(
      'messages',
      msg,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<List<Map<String, dynamic>>> getMessagesForTrail(String trailId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'trailId = ?',
      whereArgs: [trailId],
      orderBy: 'timestamp ASC',
    );
  }

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
}
