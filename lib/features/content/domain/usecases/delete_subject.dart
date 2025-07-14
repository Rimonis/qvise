// lib/features/content/domain/usecases/delete_subject.dart
import 'package:dartz/dartz.dart';
import 'package:qvise/core/error/app_error.dart';
import 'package:qvise/core/usecases/usecase.dart';
import '../repositories/content_repository.dart';

class DeleteSubjectParams {
  final String subjectName;

  DeleteSubjectParams({required this.subjectName});
}

class DeleteSubject implements VoidUseCase<DeleteSubjectParams> {
  final ContentRepository repository;

  DeleteSubject(this.repository);

  @override
  Future<Either<AppError, void>> call(DeleteSubjectParams params) async {
    return await repository.deleteSubject(params.subjectName);
  }
}

// ===== Artifact 6 =====
name: qvise
description: A smart study app for efficient learning
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.10
  riverpod_annotation: ^2.3.4

  # Architecture & Functional Programming
  dartz: ^0.10.1
  equatable: ^2.0.5  # Added missing dependency
  uuid: ^4.3.3

  # Code Generation
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6

  # Local Database
  sqflite: ^2.3.0
  path: ^1.8.3

  # Network & Connectivity
  http: ^1.1.0
  internet_connection_checker: ^1.0.0+1

  # UI & Theming
  cupertino_icons: ^1.0.6
  google_fonts: ^6.1.0

  # File & Media Handling
  file_picker: ^6.1.1
  image_picker: ^1.0.7
  path_provider: ^2.1.1

  # Utilities
  intl: ^0.19.0
  logger: ^2.0.2+1
  device_info_plus: ^9.1.2
  package_info_plus: ^5.0.1

  # Authentication & Security
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^5.0.0  # Added missing dependency
  crypto: ^3.0.3

  # Additional utilities
  collection: ^1.17.2

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.7
  freezed: ^2.4.7
  json_serializable: ^6.7.1
  riverpod_generator: ^2.3.11

  # Linting & Analysis
  flutter_lints: ^3.0.1
  very_good_analysis: ^5.1.0

  # Testing
  mockito: ^5.4.4
  mocktail: ^1.0.3

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/icons/
    - assets/config/

  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700

// ===== Artifact 7 =====