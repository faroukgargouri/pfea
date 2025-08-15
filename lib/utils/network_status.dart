// lib/utils/network_status.dart
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkStatus {
  static Future<bool> get isOnline async {
    final res = await Connectivity().checkConnectivity();
    return res.contains(ConnectivityResult.mobile) ||
           res.contains(ConnectivityResult.wifi) ||
           res.contains(ConnectivityResult.ethernet);
  }

  static Stream<bool> get stream async* {
    yield* Connectivity().onConnectivityChanged.map((list) =>
      list.contains(ConnectivityResult.mobile) ||
      list.contains(ConnectivityResult.wifi) ||
      list.contains(ConnectivityResult.ethernet)
    );
  }
}
