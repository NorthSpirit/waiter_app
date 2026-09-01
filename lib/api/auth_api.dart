import 'package:waiter_app/api/api_client.dart';

class AuthApi {
  static Future<Map<String, dynamic>> restaurantLogin(
    String restaurantName,
    String password,
  ) {
    return ApiClient.post('/api/waiter/login', {
      'restaurant_name': restaurantName,
      'password': password,
    });
  }

  static Future<Map<String, dynamic>> employeeLogin(
    int restaurantId,
    String employeeName,
    String password,
  ) {
    return ApiClient.post('/api/waiter/login/employee', {
      'restaurant_id': restaurantId,
      'employee_name': employeeName,
      'password': password,
    });
  }
}