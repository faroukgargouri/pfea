import 'dart:convert';
import 'package:http/http.dart' as http;

/// ====== CHANGE THIS to match your ASP.NET server ======
const String baseUrl = 'http://192.168.0.110:5274';

class ApiClient {
  final http.Client _client;
  ApiClient() : _client = http.Client(); // NOTE: no 'const' here (fixes your error)

  Future<List<dynamic>> getList(String pathWithQuery) async {
    final uri = Uri.parse('$baseUrl$pathWithQuery');
    final res = await _client.get(uri);
    if (res.statusCode >= 400) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final body = res.body.isEmpty ? '[]' : res.body;
    final decoded = json.decode(body);
    if (decoded is List) return decoded;
    throw Exception('Expected a JSON array but got: $decoded');
  }

  Future<Map<String, dynamic>> getObject(String pathWithQuery) async {
    final uri = Uri.parse('$baseUrl$pathWithQuery');
    final res = await _client.get(uri);
    if (res.statusCode >= 400) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final body = res.body.isEmpty ? '{}' : res.body;
    final decoded = json.decode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Expected a JSON object but got: $decoded');
  }
}
