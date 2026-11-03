import 'package:shared_preferences/shared_preferences.dart';
import 'package:waiter_app/api/discovery_service.dart';

// A compilation time override, which allows to set online URL for demo
// Even if the whole system is still very much still meant to be used from local WIFI
// To set it, you have to do it like this:
// --dart-define=SERVER_URL=http://172.232.142.127:41241
// Changing URL with whatever the actual server uses, also, PORT 41241 is generally intended one for the system
// So it is advised not to change it
const String? kFixedServerUrl = bool.hasEnvironment('SERVER_URL')
    ? String.fromEnvironment('SERVER_URL')
    : null;

// Finds the backend CommonTable server
class ServerLocator {

  // Key under which the saved URL lives in the shared preferences (a package of flutter)
  static const _cacheKey = 'server_base_url';

  // Build-time override wins over everything, if it's already set in thhe override, discoery and caching is not used
  static Future<String?> locate() async {
    if (kFixedServerUrl != null) {
      return kFixedServerUrl;
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);

    // Try to use the URL, which is already cached first
    // So it wouldn't be set again and again each time the app is launched
    if (cached != null) {
      return cached;
    }

    // Finally, if there is nothing cached, scan the network and attempt to set one
    final discovered = await DiscoveryService.discoverServer();
    if (discovered != null) {
      await prefs.setString(_cacheKey, discovered);
    }
    return discovered;
  }

  // A method to force a fresh discovery ignoring the cached ones, in the scenario, where server can't login with what it has.
  // Note, in the Demo/Online build, it doesn't matter, since URL is set in
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