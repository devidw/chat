import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

class DATA {
  static late Database db;

  static Future<void> init() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'my_database.db');

    DATA.db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE projects (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL
          )''');

        await db.execute('''
          CREATE TABLE chats (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              project_id INTEGER NOT NULL,
              model TEXT,
              FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
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
  }

  // **project apis**
  static Future<List<Map<String, dynamic>>> listProjects() async {
    return await db.query('projects');
  }

  static Future<int> createProject({String name = 'untitled project'}) async {
    return await db.insert('projects', {'name': name});
  }

  static Future<int> updateProject(
      {required int id, required String name}) async {
    return await db.update('projects', {'name': name},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteProject({required int id}) async {
    return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  // **chat apis**
  static Future<List<Map<String, dynamic>>> listChatsByProject(
      {required int projectId}) async {
    return await db
        .query('chats', where: 'project_id = ?', whereArgs: [projectId]);
  }

  static Future<int> createChat(
      {required int projectId, String name = 'untitled chat'}) async {
    return await db.insert('chats', {'name': name, 'project_id': projectId});
  }

  static Future<int> updateChat({required int id, required String name}) async {
    return await db.update('chats', {'name': name},
        where: 'id = ?', whereArgs: [id]);
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
