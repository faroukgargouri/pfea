// lib/data/api_config.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Host base (NO trailing /api here).
/// - Web/Desktop/iOS sim → HTTPS localhost:7040
/// - Android emulator → HTTP 10.0.2.2:5274 (avoid self-signed cert issues)
String get apiBaseUrl {
  if (kIsWeb) return 'https://localhost:7040';
  // On Android, localhost = the emulator; 10.0.2.2 maps to host PC.
  if (!kIsWeb && Platform.isAndroid) return 'https://6f7f50205560.ngrok-free.app';
  // iOS simulator & desktop
  return 'https://localhost:7040';
}

/// API root INCLUDING `/api` (used by ApiService)
String get apiRoot => '$apiBaseUrl/api';
