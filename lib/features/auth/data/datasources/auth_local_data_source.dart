// lib/features/auth/data/datasources/auth_local_data_source.dart
import 'dart:convert';
import 'package:qvise/core/data/database/app_database.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearCachedUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  // FIXED: Use shared AppDatabase instead of separate database
  Future<Database> get _database async => AppDatabase.database;

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final db = await _database;
      
      // Create users table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users(
          id TEXT PRIMARY KEY, 
          data TEXT
        )
      ''');

      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        final userData = jsonDecode(maps.first['data'] as String);
        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    final db = await _database;
    
    // Ensure table exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id TEXT PRIMARY KEY, 
        data TEXT
      )
    ''');

    await db.insert(
      'users',
      {
        'id': user.id,
        'data': jsonEncode(user.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clearCachedUser() async {
    final db = await _database;
    await db.delete('users');
  }
}