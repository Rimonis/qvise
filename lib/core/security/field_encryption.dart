// lib/core/security/field_encryption.dart
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final fieldEncryptionProvider = Provider((ref) => FieldEncryption());

class FieldEncryption {
  static const _keyStorageKey = 'qvise_field_encryption_key';
  final _secureStorage = const FlutterSecureStorage();
  encrypt.Encrypter? _encrypter;
  encrypt.Key? _key;

  Future<void> _initialize() async {
    if (_encrypter!= null) return;

    String? base64Key = await _secureStorage.read(key: _keyStorageKey);
    if (base64Key == null) {
      _key = encrypt.Key.fromSecureRandom(32);
      await _secureStorage.write(key: _keyStorageKey, value: _key!.base64);
    } else {
      _key = encrypt.Key.fromBase64(base64Key);
    }
    _encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.gcm));
  }

  Future<String?> encryptField(String? plaintext) async {
    if (plaintext == null |

| plaintext.isEmpty) return null;
    await _initialize();
    final iv = encrypt.IV.fromSecureRandom(12); // GCM standard IV size is 12 bytes
    final encrypted = _encrypter!.encrypt(plaintext, iv: iv);
    // Store IV along with the encrypted data for decryption
    return '${iv.base64}:${encrypted.base64}';
  }

  Future<String?> decryptField(String? encryptedText) async {
    if (encryptedText == null |

| encryptedText.isEmpty) return null;
    await _initialize();
    try {
      final parts = encryptedText.split(':');
      if (parts.length!= 2) throw Exception('Invalid encrypted format');
      
      final iv = encrypt.IV.fromBase64(parts);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
      return _encrypter!.decrypt(encrypted, iv: iv);
    } catch (e) {
      // Handle decryption failure, e.g., log error and return null
      print('Decryption failed: $e');
      return null;
    }
  }
}