// lib/features/files/data/datasources/file_remote_data_source.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/file_model.dart';

abstract class FileRemoteDataSource {
  Future<FileModel> uploadFile(FileModel fileToUpload);
  Future<void> deleteFile(String fileId, String userId);
  Future<void> deleteFilesByLesson(String lessonId, String userId);
  Future<void> deleteFilesByLessonIds(List<String> lessonIds, String userId);
}

class FileRemoteDataSourceImpl implements FileRemoteDataSource {
  final FirebaseFirestore _firestore;
  final dynamic _storage; // Using dynamic until firebase_storage is added

  FileRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required dynamic storage,
  }) : _firestore = firestore, _storage = storage;

  CollectionReference<Map<String, dynamic>> _filesCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('files');

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
    final docRef = _filesCollection(fileToUpload.userId).doc(syncedFile.id);
    await docRef.set(syncedFile.toJson());

    return syncedFile;
  }

  @override
  Future<void> deleteFile(String fileId, String userId) async {
    // Delete from Firestore
    await _filesCollection(userId).doc(fileId).delete();

    // Real implementation would delete from Firebase Storage here
    /*
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
    final batch = _firestore.batch();
    final querySnapshot = await _filesCollection(userId)
        .where('lesson_id', isEqualTo: lessonId)
        .get();
        
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
      // In real implementation, add storage deletion here
    }
    await batch.commit();
  }

  @override
  Future<void> deleteFilesByLessonIds(List<String> lessonIds, String userId) async {
    if (lessonIds.isEmpty) return;
    
    final batch = _firestore.batch();
    final querySnapshot = await _filesCollection(userId)
        .where('lesson_id', whereIn: lessonIds)
        .get();
        
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
      // In real implementation, add storage deletion here
    }
    await batch.commit();
  }
}
