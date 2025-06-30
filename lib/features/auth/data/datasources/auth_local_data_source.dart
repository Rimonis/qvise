import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearCachedUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Database database;

  AuthLocalDataSourceImpl({required this.database});

  static Future<Database> createDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'app_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE users(id TEXT PRIMARY KEY, data TEXT)',
        );
      },
      version: 1,
    );
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
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
    await database.insert(
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
    await database.delete('users');
  }
}

