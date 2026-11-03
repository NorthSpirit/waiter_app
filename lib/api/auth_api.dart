import 'package:waiter_app/api/api_client.dart';

// Server calls for logging in
// In the system, both the person and the restaurant are protected by a password
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

  // Restaurant login requests (POST method):
  // Restaurant name and restaurant password
  // returns:
  // Status 200 OK
  // And the Restaurant name, ID and the logo

  // Truth be told, in the whole project "password" and "pin" are used interchangably
  // Partly because, waiter app was started first, way before anything else
  // And first name for it was "Pin", but server allows to set long passwords with numbers and symbols and letters
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

// Employee login requests (POST method):
// Restaurant ID (not the name), password of the employee, as well as the name of the employee
// returns:
// Status 200 OK
// Session token and session expiration date
// Employee ID
// Name
// Role (waiter/manager/chef)