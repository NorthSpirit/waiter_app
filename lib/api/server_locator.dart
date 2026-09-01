import 'package:shared_preferences/shared_preferences.dart';
import 'package:waiter_app/api/discovery_service.dart';

const String? kFixedServerUrl = bool.hasEnvironment('SERVER_URL')
    ? String.fromEnvironment('SERVER_URL')
    : null;

class ServerLocator {
  static const _cacheKey = 'server_base_url';

  static Future<String?> locate() async {
    if (kFixedServerUrl != null) {
      return kFixedServerUrl;
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);

    if (cached != null) {
      return cached;
    }

    final discovered = await DiscoveryService.discoverServer();
    if (discovered != null) {
      await prefs.setString(_cacheKey, discovered);
    }
    return discovered;
  }

  static Future<String?> rediscover() async {
    if (kFixedServerUrl != null) {
      return kFixedServerUrl;
    }

    final prefs = await SharedPreferences.getInstance();
    final discovered = await DiscoveryService.discoverServer();
    if (discovered != null) {
      await prefs.setString(_cacheKey, discovered);
    }
    return discovered;
  }
}