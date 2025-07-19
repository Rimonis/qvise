// lib/features/files/data/datasources/file_remote_data_source.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/file_model.dart';

abstract class FileRemoteDataSource {
  Future<FileModel> uploadFile(FileModel fileToUpload);
  Future<void> deleteFile(String fileId, String userId);
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
}