// lib/core/services/user_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

abstract class UserService {
  Future<String> getCurrentUserId();
  String? getCurrentUserIdSync();
}

class UserServiceImpl implements UserService {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  UserServiceImpl({required firebase_auth.FirebaseAuth firebaseAuth})
      : _firebaseAuth = firebaseAuth;

  @override
  Future<String> getCurrentUserId() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  @override
  String? getCurrentUserIdSync() {
    return _firebaseAuth.currentUser?.uid;
  }
}