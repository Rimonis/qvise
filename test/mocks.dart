// test/mocks.dart
import 'package:mockito/annotations.dart';
import 'package:qvise/features/content/data/datasources/content_local_data_source.dart';
import 'package:qvise/features/content/data/datasources/content_remote_data_source.dart';
import 'package:qvise/features/content/domain/repositories/content_repository.dart';
import 'package:qvise/features/files/data/datasources/file_local_data_source.dart';
import 'package:qvise/features/flashcards/shared/data/datasources/flashcard_local_data_source.dart';
import 'package:qvise/features/flashcards/shared/data/datasources/flashcard_remote_data_source.dart';
import 'package:qvise/features/flashcards/shared/domain/repositories/flashcard_repository.dart';
import 'package:qvise/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:qvise/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:qvise/features/auth/domain/repositories/auth_repository.dart';
import 'package:qvise/core/data/unit_of_work.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';

@GenerateMocks([
  ContentLocalDataSource,
  ContentRemoteDataSource,
  ContentRepository,
  FlashcardLocalDataSource,
  FlashcardRemoteDataSource,
  FlashcardRepository,
  AuthLocalDataSource,
  AuthRemoteDataSource,
  AuthRepository,
  IUnitOfWork,
  InternetConnectionChecker,
  FirebaseAuth,
  User,
  Database,
  Transaction,
  FileLocalDataSource
])
void main() {}