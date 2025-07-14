// lib/core/security/field_encryption.dart

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class FieldEncryption {
  static const String _keyPrefix = 'qvise_encryption_';
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits

  late final Uint8List _encryptionKey;
  late final Random _random;

  FieldEncryption() {
    _random = Random.secure();
    _encryptionKey = _generateOrRetrieveKey();
  }

  /// Encrypt sensitive text data
  String encryptText(String plaintext) {
    if (plaintext.isEmpty) return plaintext;
    
    try {
      final iv = _generateIV();
      final plainBytes = utf8.encode(plaintext);
      final encryptedBytes = _xorEncrypt(plainBytes, _encryptionKey, iv);
      
      // Combine IV + encrypted data
      final combined = Uint8List(iv.length + encryptedBytes.length);
      combined.setRange(0, iv.length, iv);
      combined.setRange(iv.length, combined.length, encryptedBytes);
      
      return base64.encode(combined);
    } catch (e) {
      if (kDebugMode) {
        print('Encryption error: $e');
      }
      return plaintext; // Return original if encryption fails
    }
  }

  /// Decrypt sensitive text data
  String decryptText(String encryptedText) {
    if (encryptedText.isEmpty) return encryptedText;
    
    try {
      final combined = base64.decode(encryptedText);
      
      if (combined.length <= _ivLength) {
        return encryptedText; // Invalid format, return as-is
      }
      
      final iv = combined.sublist(0, _ivLength);
      final encryptedBytes = combined.sublist(_ivLength);
      
      final decryptedBytes = _xorDecrypt(encryptedBytes, _encryptionKey, iv);
      return utf8.decode(decryptedBytes);
    } catch (e) {
      if (kDebugMode) {
        print('Decryption error: $e');
      }
      return encryptedText; // Return original if decryption fails
    }
  }

  /// Hash sensitive data (one-way)
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate secure hash with salt
  String hashWithSalt(String data, {String? salt}) {
    salt ??= _generateSalt();
    final combined = '$data$salt';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return '${digest.toString()}:$salt';
  }

  /// Verify hash with salt
  bool verifyHash(String data, String hashedData) {
    try {
      final parts = hashedData.split(':');
      if (parts.length != 2) return false;
      
      final expectedHash = parts[0];
      final salt = parts[1];
      
      final actualHash = hashWithSalt(data, salt: salt);
      return actualHash.split(':')[0] == expectedHash;
    } catch (e) {
      return false;
    }
  }

  /// Encrypt sensitive flashcard content
  String encryptFlashcardContent(String content) {
    // For flashcards, we might want lighter encryption for performance
    if (content.length > 1000) {
      // For very long content, just encrypt key parts
      return _encryptSelectively(content);
    }
    return encryptText(content);
  }

  /// Decrypt flashcard content
  String decryptFlashcardContent(String encryptedContent) {
    return decryptText(encryptedContent);
  }

  /// Generate or retrieve encryption key
  Uint8List _generateOrRetrieveKey() {
    // In a real app, you'd store this securely using flutter_secure_storage
    // For now, we'll generate a consistent key based on a seed
    final seed = 'qvise_app_encryption_seed_2024';
    final seedBytes = utf8.encode(seed);
    final digest = sha256.convert(seedBytes);
    
    // Extend to required length
    final key = Uint8List(_keyLength);
    final digestBytes = digest.bytes;
    
    for (int i = 0; i < _keyLength; i++) {
      key[i] = digestBytes[i % digestBytes.length];
    }
    
    return key;
  }

  /// Generate random initialization vector
  Uint8List _generateIV() {
    final iv = Uint8List(_ivLength);
    for (int i = 0; i < _ivLength; i++) {
      iv[i] = _random.nextInt(256);
    }
    return iv;
  }

  /// Generate random salt
  String _generateSalt() {
    final saltBytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      saltBytes[i] = _random.nextInt(256);
    }
    return base64.encode(saltBytes);
  }

  /// Simple XOR encryption (for demonstration - use AES in production)
  Uint8List _xorEncrypt(List<int> data, Uint8List key, Uint8List iv) {
    final encrypted = Uint8List(data.length);
    final combinedKey = Uint8List(key.length + iv.length);
    combinedKey.setRange(0, key.length, key);
    combinedKey.setRange(key.length, combinedKey.length, iv);
    
    for (int i = 0; i < data.length; i++) {
      encrypted[i] = data[i] ^ combinedKey[i % combinedKey.length];
    }
    
    return encrypted;
  }

  /// Simple XOR decryption
  Uint8List _xorDecrypt(List<int> encryptedData, Uint8List key, Uint8List iv) {
    return _xorEncrypt(encryptedData, key, iv); // XOR is symmetric
  }

  /// Selectively encrypt parts of long content
  String _encryptSelectively(String content) {
    try {
      // Encrypt first 100 and last 100 characters, leave middle as hash
      final start = content.substring(0, min(100, content.length));
      final end = content.length > 200 ? content.substring(content.length - 100) : '';
      final middle = content.length > 200 ? content.substring(100, content.length - 100) : '';
      
      final encryptedStart = encryptText(start);
      final encryptedEnd = end.isNotEmpty ? encryptText(end) : '';
      final hashedMiddle = middle.isNotEmpty ? hashData(middle) : '';
      
      // Format: START|HASH|END
      return '$encryptedStart|$hashedMiddle|$encryptedEnd';
    } catch (e) {
      return encryptText(content); // Fallback to full encryption
    }
  }

  /// Check if text is encrypted (basic heuristic)
  bool isEncrypted(String text) {
    try {
      // Check if it's valid base64 and has reasonable length for encrypted content
      final decoded = base64.decode(text);
      return decoded.length > _ivLength && text.length > 20;
    } catch (e) {
      return false;
    }
  }

  /// Migrate unencrypted data to encrypted
  String migrateToEncrypted(String data) {
    if (isEncrypted(data)) return data;
    return encryptText(data);
  }

  /// Get encryption info for debugging
  Map<String, dynamic> getEncryptionInfo() {
    return {
      'keyLength': _keyLength,
      'ivLength': _ivLength,
      'algorithm': 'XOR (Demo)', // In production: 'AES-256-CBC'
      'version': '1.0',
    };
  }
}

/// Extension for easy encryption/decryption
extension FieldEncryptionExtension on String {
  String encrypt(FieldEncryption encryption) => encryption.encryptText(this);
  String decrypt(FieldEncryption encryption) => encryption.decryptText(this);
  String hash(FieldEncryption encryption) => encryption.hashData(this);
}

/// Mixin for models that need encryption
mixin EncryptedModel {
  static late FieldEncryption _encryption;
  
  static void setEncryption(FieldEncryption encryption) {
    _encryption = encryption;
  }
  
  String encryptField(String value) => _encryption.encryptText(value);
  String decryptField(String value) => _encryption.decryptText(value);
  String hashField(String value) => _encryption.hashData(value);
}

/// Secure data container
class SecureData {
  final String _encryptedValue;
  final FieldEncryption _encryption;

  SecureData._(this._encryptedValue, this._encryption);

  factory SecureData.create(String plainValue, FieldEncryption encryption) {
    return SecureData._(encryption.encryptText(plainValue), encryption);
  }

  factory SecureData.fromEncrypted(String encryptedValue, FieldEncryption encryption) {
    return SecureData._(encryptedValue, encryption);
  }

  String get value => _encryption.decryptText(_encryptedValue);
  String get encrypted => _encryptedValue;

  @override
  String toString() => '***ENCRYPTED***'; // Never expose the actual value

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecureData && other._encryptedValue == _encryptedValue;
  }

  @override
  int get hashCode => _encryptedValue.hashCode;
}

// Import for min function
import 'dart:math' show min;
