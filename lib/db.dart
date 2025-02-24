import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class DATA {
  static late Database db;
  static late String dbPath;
  static bool _initialized = false;

  static Future<void> mbInit() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    dbPath = prefs.getString('db_path') ?? '';
    if (dbPath.isEmpty) {
      throw Exception('Database path not found in settings');
    }

    DATA.db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chats (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              parent_id INTEGER,
              model TEXT,
              FOREIGN KEY (parent_id) REFERENCES chats (id) ON DELETE CASCADE
          )''');

        await db.execute('''
          CREATE TABLE messages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              role TEXT NOT NULL,
              content TEXT NOT NULL,
              chat_id INTEGER NOT NULL,
              created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
              model TEXT,
              FOREIGN KEY (chat_id) REFERENCES chats (id) ON DELETE CASCADE
          )''');
      },
    );

    _initialized = true;
  }

  // **chat apis**
  static Future<List<Map<String, dynamic>>> listChats({int? parentId}) async {
    return await db.query(
      'chats',
      where: parentId == null ? 'parent_id IS NULL' : 'parent_id = ?',
      whereArgs: parentId == null ? [] : [parentId],
    );
  }

  static Future<int> createChat({
    String name = 'untitled chat',
    int? parentId,
  }) async {
    return await db.insert('chats', {
      'name': name,
      'parent_id': parentId,
    });
  }

  static Future<int> updateChat({
    required int id,
    String? name,
  }) async {
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    return await db.update('chats', updates, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteChat({required int id}) async {
    return await db.delete('chats', where: 'id = ?', whereArgs: [id]);
  }

  // **message apis**
  static Future<List<Map<String, dynamic>>> listMessagesByChat(
      {required int chatId}) async {
    return await db
        .query('messages', where: 'chat_id = ?', whereArgs: [chatId]);
  }

  static Future<int> createMessage({
    required String role,
    required String content,
    required int chatId,
    String? model,
  }) async {
    return await db.insert('messages', {
      'role': role,
      'content': content,
      'chat_id': chatId,
      'model': model,
    });
  }

  static Future<int> deleteMessage({required int id}) async {
    return await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'my_database.db');

    await File(path).delete();
    print('database deleted at: $path');
  }
}
