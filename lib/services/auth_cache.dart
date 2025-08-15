import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class AuthCache {
  static const _storage = FlutterSecureStorage();

  static const _kEmail = 'auth_email';
  static const _kPwdHash = 'auth_pwd_hash';
  static const _kUserJson = 'auth_user_json';

  static Future<void> saveIdentity({
    required String email,
    required String password,
    required Map<String, dynamic> userJson,
  }) async {
    final hash = _hash(password);
    await _storage.write(key: _kEmail, value: email);
    await _storage.write(key: _kPwdHash, value: hash);
    await _storage.write(key: _kUserJson, value: jsonEncode(userJson));
  }

  static Future<Map<String, dynamic>?> tryOfflineLogin({
    required String email,
    required String password,
  }) async {
    final savedEmail = await _storage.read(key: _kEmail);
    final savedHash = await _storage.read(key: _kPwdHash);
    final savedUser = await _storage.read(key: _kUserJson);

    if (savedEmail == null || savedHash == null || savedUser == null) {
      return null;
    }

    if (savedEmail.toLowerCase().trim() != email.toLowerCase().trim()) {
      return null;
    }

    final inputHash = _hash(password);
    if (inputHash != savedHash) return null;

    return jsonDecode(savedUser) as Map<String, dynamic>;
  }

  static String _hash(String s) {
    final bytes = utf8.encode(s);
    return sha256.convert(bytes).toString();
  }
}
