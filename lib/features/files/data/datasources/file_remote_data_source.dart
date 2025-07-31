// lib/features/files/data/datasources/file_remote_data_source.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/file_model.dart';

abstract class FileRemoteDataSource {
  Future<FileModel> uploadFile(FileModel fileToUpload);
  Future<void> deleteFile(String fileId, String userId);
  Future<void> deleteFilesByLesson(String lessonId, String userId); // Added for cascade delete
  Future<void> deleteFilesByLessonIds(List<String> lessonIds, String userId); // Added for bulk operations
}

class FileRemoteDataSourceImpl implements FileRemoteDataSource {
  final FirebaseFirestore _firestore;
  final dynamic _storage; // Using dynamic until firebase_storage is added

  FileRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required dynamic storage,
  }) : _firestore = firestore, _storage = storage;

  @override
  Future<FileModel> uploadFile(FileModel fileToUpload) async {
    // For now, this is a mock implementation
    // Once firebase_storage is added to pubspec.yaml, uncomment the real implementation
    
    // Mock: Just update the sync status without actually uploading
    final syncedFile = fileToUpload.copyWith(
      remoteUrl: 'mock://storage.googleapis.com/bucket/${fileToUpload.id}',
      syncStatus: 'synced',
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    // Save metadata to Firestore
    final docRef = _firestore
        .collection('users')
        .doc(fileToUpload.userId)
        .collection('files')
        .doc(syncedFile.id);
    await docRef.set(syncedFile.toJson());

    return syncedFile;

    /* Real implementation (uncomment when firebase_storage is added):
    final file = File(fileToUpload.filePath);
    if (!await file.exists()) {
      throw Exception('File not found at path: ${fileToUpload.filePath}');
    }

    final userId = fileToUpload.userId;
    final fileName = '${fileToUpload.id}.${fileToUpload.name.split('.').last}';
    final storageRef = _storage.ref('users/$userId/files/$fileName');
    
    // 1. Upload file to Firebase Storage
    final uploadTask = storageRef.putFile(file);
    final snapshot = await uploadTask.whenComplete(() => {});
    final remoteUrl = await snapshot.ref.getDownloadURL();

    // 2. Update model with remote URL and sync status
    final syncedFile = fileToUpload.copyWith(
      remoteUrl: remoteUrl,
      syncStatus: 'synced',
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    // 3. Save metadata to Firestore
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('files')
        .doc(syncedFile.id);
    await docRef.set(syncedFile.toJson());

    return syncedFile;
    */
  }

  @override
  Future<void> deleteFile(String fileId, String userId) async {
    // Delete from Firestore
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('files')
        .doc(fileId)
        .delete();

    // For mock, we don't need to delete from storage
    // Real implementation would delete from Firebase Storage here
    /* Real implementation (uncomment when firebase_storage is added):
    try {
      final storageRef = _storage.ref('users/$userId/files/$fileId');
      await storageRef.delete();
    } catch (e) {
      // File might not exist in storage, which is fine
      print('Could not delete file from storage: $e');
    }
    */
  }

  @override
  Future<void> deleteFilesByLesson(String lessonId, String userId) async {
    try {
      // Get all files for this lesson
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('files')
          .where('lesson_id', isEqualTo: lessonId)
          .get();

      // Delete each file (both metadata and storage)
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        
        // For mock, we don't delete from storage
        // Real implementation would delete from Firebase Storage here
        /* Real implementation (uncomment when firebase_storage is added):
        try {
          final fileId = doc.id;
          final storageRef = _storage.ref('users/$userId/files/$fileId');
          await storageRef.delete();
        } catch (e) {
          // File might not exist in storage, which is fine
          print('Could not delete file from storage: $e');
        }
        */
      }
      
      await batch.commit();
    } catch (e) {
      print('Non-critical failure: Could not delete remote files for lesson $lessonId: $e');
    }
  }

  @override
  Future<void> deleteFilesByLessonIds(List<String> lessonIds, String userId) async {
    if (lessonIds.isEmpty) return;
    
    try {
      // Process in chunks to avoid Firestore query limits
      const chunkSize = 10; // Firestore 'in' query limit
      
      for (int i = 0; i < lessonIds.length; i += chunkSize) {
        final chunk = lessonIds.skip(i).take(chunkSize).toList();
        
        final querySnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('files')
            .where('lesson_id', whereIn: chunk)
            .get();

        // Delete each file (both metadata and storage)
        final batch = _firestore.batch();
        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
          
          // For mock, we don't delete from storage
          // Real implementation would delete from Firebase Storage here
          /* Real implementation (uncomment when firebase_storage is added):
          try {
            final fileId = doc.id;
            final storageRef = _storage.ref('users/$userId/files/$fileId');
            await storageRef.delete();
          } catch (e) {
            // File might not exist in storage, which is fine
            print('Could not delete file from storage: $e');
          }
          */
        }
        
        await batch.commit();
      }
    } catch (e) {
      print('Non-critical failure: Could not delete remote files for lessons: $e');
    }
  }
}