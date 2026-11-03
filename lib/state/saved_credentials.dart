import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// User's credentials saved by the app
// allowing to skip restaurant login screen next time the app is launched
// and also fill in the waiter's credentials (not by-pass) for quality of life
// restaurant password is saved encrypted by the flutter_secure_storage package (uses the phone's),
// restaurant name in plain shared_preferences.
// and waiter's password is not saved at all
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

  // Clears the remembered restaurant login, for example, if someone switches restaurant on the device.
  // For example in the scenarios, where food hall shares the devices.
  // It is also used in the main, if for whatever reason saved password no longer works (mayhaps admin changed it or whatever)
  static Future<void> clearRestaurant() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_restaurantNameKey);
    await _secureStorage.delete(key: _restaurantPasswordKey);
  }
}