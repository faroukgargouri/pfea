import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Caches a salted hash of the user's password + the user payload so we can
/// authenticate OFFLINE with the same email/password later.
class AuthCache {
  // Encrypted storage on Android/iOS
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kEmail   = 'auth_email';
  static const _kSalt    = 'auth_salt';
  static const _kPwdHash = 'auth_pwd_hash';
  static const _kUser    = 'auth_user_json';

  /// Save identity after a **successful ONLINE** login.
  static Future<void> saveIdentity({
    required String email,
    required String password,
    required Map<String, dynamic> userJson,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // random 16-byte salt
    final saltBytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final saltB64   = base64Encode(saltBytes);

    // hash = sha256( salt || utf8(password) )
    final hashBytes = sha256.convert([...saltBytes, ...utf8.encode(password)]).bytes;
    final hashB64   = base64Encode(hashBytes);

    await _storage.write(key: _kEmail,   value: normalizedEmail);
    await _storage.write(key: _kSalt,    value: saltB64);
    await _storage.write(key: _kPwdHash, value: hashB64);
    await _storage.write(key: _kUser,    value: jsonEncode(userJson));
  }

  /// Try OFFLINE login. Returns the cached user json if email/password match.
  static Future<Map<String, dynamic>?> tryOfflineLogin({
    required String email,
    required String password,
  }) async {
    final cachedEmail = await _storage.read(key: _kEmail);
    final saltB64     = await _storage.read(key: _kSalt);
    final hashB64     = await _storage.read(key: _kPwdHash);
    final userStr     = await _storage.read(key: _kUser);

    if (cachedEmail == null || saltB64 == null || hashB64 == null || userStr == null) {
      return null; // nothing cached yet
    }
    if (cachedEmail != email.trim().toLowerCase()) return null;

    final salt   = base64Decode(saltB64);
    final expect = hashB64;
    final got    = base64Encode(sha256.convert([...salt, ...utf8.encode(password)]).bytes);

    if (got != expect) return null; // wrong password

    return jsonDecode(userStr) as Map<String, dynamic>;
  }

  static Future<void> signOut() async {
    await _storage.deleteAll();
  }
}
