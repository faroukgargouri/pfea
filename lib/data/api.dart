import 'dart:convert';
import 'package:flutter_application_1/data/api_config.dart';
import 'package:http/http.dart' as http;

Future<dynamic> getJson(String path, [Map<String, String>? q]) async {
  final base = apiBaseUrl;
  final uri = Uri.parse('$base$path').replace(queryParameters: q);
  final res = await http.get(uri);
  if (res.statusCode >= 400) {
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }
  return json.decode(res.body);
}
