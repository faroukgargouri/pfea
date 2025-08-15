// lib/repositories/reclamation_repository.dart
import '../services/api_service.dart';
import '../services/local_cache.dart';
import '../utils/network_status.dart';

class ReclamationRepository {
  static const _box = 'reclamations';
  static const _key = 'all';

  static Future<List<Map<String, dynamic>>> getAll() async {
    if (await NetworkStatus.isOnline) {
      final remote = await ApiService.getAllReclamations();
      await LocalCache.saveList(_box, _key, remote);
      return remote;
    } else {
      return await LocalCache.readList(_box, _key);
    }
  }
}
