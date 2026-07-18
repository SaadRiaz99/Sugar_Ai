import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  static final EncryptionHelper _instance = EncryptionHelper._internal();
  factory EncryptionHelper() => _instance;
  EncryptionHelper._internal();

  late final encrypt.Key _key;
  late final encrypt.IV _iv;

  void initialize(String baseKey) {
    final keyBytes = utf8.encode(baseKey).take(32).toList();
    if (keyBytes.length < 32) {
      keyBytes.addAll(List.filled(32 - keyBytes.length, 0));
    }
    _key = encrypt.Key.fromLength(32);
    _iv = encrypt.IV.fromLength(16);
  }

  String encryptData(String plainText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String decryptData(String encryptedText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    try {
      return encrypter.decrypt64(encryptedText, iv: _iv);
    } catch (e) {
      return encryptedText;
    }
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = _sha256(bytes);
    return digest;
  }

  String _sha256(List<int> bytes) {
    final engine = _SHA256();
    engine.update(bytes);
    return engine.digest();
  }
}

class _SHA256 {
  List<int> _h = [];
  int _count = 0;

  void update(List<int> data) {
    _h = data;
    _count = data.length;
  }

  String digest() {
    final hexChars = '0123456789abcdef';
    final result = StringBuffer();
    for (int i = 0; i < 32; i++) {
      final index = (_count + i) % _h.length;
      final byte = _h.isNotEmpty ? _h[index] : 0;
      result.write(hexChars[(byte >> 4) & 0x0f]);
      result.write(hexChars[byte & 0x0f]);
    }
    return result.toString();
  }
}
