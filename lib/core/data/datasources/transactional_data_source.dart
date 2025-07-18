// lib/core/data/datasources/transactional_data_source.dart

import 'package:qvise/core/data/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

abstract class TransactionalDataSource {
  Transaction? _currentTransaction;

  void setTransaction(Transaction? transaction) {
    _currentTransaction = transaction;
  }

  Future<DatabaseExecutor> get database async {
    if (_currentTransaction != null) {
      return _currentTransaction!;
    }
    return AppDatabase.database;
  }
}
