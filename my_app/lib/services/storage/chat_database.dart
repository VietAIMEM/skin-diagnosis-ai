import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../models/chat_message.dart';

/// Local SQLite persistence for chat history.
class ChatDatabase {
  static const _dbName = 'skinai_chat.db';
  static const _dbVersion = 1;
  static const _table = 'messages';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            role TEXT NOT NULL,
            text TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            imagePath TEXT,
            diagnosisResult TEXT,
            error INTEGER NOT NULL DEFAULT 0,
            loading INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<List<ChatMessage>> loadMessages({int limit = 200}) async {
    final db = await database;
    final rows = await db.query(
      _table,
      orderBy: 'timestamp ASC',
      limit: limit,
    );
    return rows.map(_rowToMessage).toList();
  }

  Future<void> insertMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      _table,
      _messageToMap(message),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMessage(ChatMessage message) async {
    final db = await database;
    await db.update(
      _table,
      _messageToMap(message),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<void> deleteMessage(String id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_table);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Map<String, dynamic> _messageToMap(ChatMessage m) {
    return {
      'id': m.id,
      'role': m.role.wireValue,
      'text': m.text,
      'timestamp': m.timestamp.toIso8601String(),
      'imagePath': m.imagePath,
      'diagnosisResult': m.diagnosisResult != null
          ? jsonEncode(m.diagnosisResult)
          : null,
      'error': m.error ? 1 : 0,
      'loading': m.loading ? 1 : 0,
    };
  }

  ChatMessage _rowToMessage(Map<String, dynamic> row) {
    final role = MessageRole.values.firstWhere(
      (r) => r.wireValue == row['role'],
      orElse: () => MessageRole.system,
    );
    Map<String, dynamic>? diagnosis;
    if (row['diagnosisResult'] != null) {
      diagnosis = jsonDecode(row['diagnosisResult'] as String)
          as Map<String, dynamic>;
    }
    return ChatMessage(
      id: row['id'] as String,
      role: role,
      text: row['text'] as String? ?? '',
      timestamp:
          DateTime.tryParse(row['timestamp'] as String? ?? '') ?? DateTime.now(),
      imagePath: row['imagePath'] as String?,
      diagnosisResult: diagnosis,
      error: (row['error'] as int? ?? 0) == 1,
      loading: (row['loading'] as int? ?? 0) == 1,
    );
  }
}
