// lib/repositories/product_repository.dart
import '../services/api_service.dart';
import '../services/local_cache.dart';
import '../utils/network_status.dart';
import '../models/product.dart';

class ProductRepository {
  static const _box = 'products';
  static const _key = 'all';

  static Future<List<Product>> getAll() async {
    if (await NetworkStatus.isOnline) {
      final remote = await ApiService.getProducts();
      await LocalCache.saveList(_box, _key, remote.map((p) => p.toJson()).toList());
      return remote;
    } else {
      final cached = await LocalCache.readList(_box, _key);
      return cached.map((m) => Product.fromJson(m)).toList();
    }
  }
}
