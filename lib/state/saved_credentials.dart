import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists just enough to skip the restaurant login screen on future
/// app launches, and to pre-fill (not skip) the waiter's own login.
///
/// Restaurant password is kept in encrypted secure storage since it's a
/// real credential; restaurant/waiter names are plain text since they're
/// not secrets. The waiter's PIN is never persisted anywhere — re-entering
/// it every launch is the deliberate security boundary here.
class SavedCredentials {
  static const _secureStorage = FlutterSecureStorage();

  static const _restaurantNameKey = 'saved_restaurant_name';
  static const _restaurantPasswordKey = 'saved_restaurant_password';
  static const _waiterNameKey = 'saved_waiter_name';

  static Future<void> saveRestaurant(String name, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_restaurantNameKey, name);
    await _secureStorage.write(key: _restaurantPasswordKey, value: password);
  }

  static Future<({String name, String password})?> getRestaurant() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_restaurantNameKey);
    final password = await _secureStorage.read(key: _restaurantPasswordKey);
    if (name == null || password == null) return null;
    return (name: name, password: password);
  }

  static Future<void> saveWaiterName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_waiterNameKey, name);
  }

  static Future<String?> getWaiterName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_waiterNameKey);
  }

  /// Clears the remembered restaurant login — used when explicitly
  /// switching restaurants, not on a normal per-shift logout.
  static Future<void> clearRestaurant() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_restaurantNameKey);
    await _secureStorage.delete(key: _restaurantPasswordKey);
  }
}