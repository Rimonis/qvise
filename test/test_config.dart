// test/test_config.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initialize test environment
void setupTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize FFI for sqflite
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Common test setup that should be called in main() of each test file
void commonTestSetup() {
  setupTestEnvironment();
}