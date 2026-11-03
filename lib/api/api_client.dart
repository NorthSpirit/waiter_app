import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:waiter_app/api/server_locator.dart';
import 'package:waiter_app/state/session.dart';

// A small helper method, to provide status exception as a string, readable for the app (UI-friendly)
// Status code is not printed, only the message.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

// Central place for all of the HTTP calls for the CommonTable server (either local or configured)
class ApiClient {
  
  // Sends a POST requests with a JSON body (waiter app has only JSON integration).
  // And returns a decoded JSON as a Map.
  static Future<Map<String, dynamic>> post(
    // Path of the method, basically, base URL with whichever method is needed appended to it.
    String path,
    Map<String, dynamic> body, {
    // Checks if the token is needed for whatever method.
    bool authenticated = false,
  }) async {
    return _withRediscoveryRetry(() async {
      final baseUrl = Session.instance.baseUrl;

      //Doesn't even retry if there is no URL
      if (baseUrl == null) {
        throw ApiException(0, 'Server not found. Please check your connection.');
      }

      // Once again, waiter app is meant to use JSON as intended
      final headers = {'Content-Type': 'application/json'};
      if (authenticated && Session.instance.token != null) {
        // Attaches the login token from the session state (same one used everywhere)
        headers['Authorization'] = 'Bearer ${Session.instance.token}';
      }

      // Since waiter app is primarily used in the local wifi, timer is set to a relatively short 5 seconds
      // After which, it gives up 
      final response = await http
          .post(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 5));

      // Saves the token sent by the server
      _captureRefreshedToken(response);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Checks if it's either a client error or a server error
      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, data['error'] ?? 'Request failed');
      }
      return data;
    });
  }

  // Sends a GET method, which should be the most often type by volume, like, get menus, get items from said menus, get quick items and so on...
  // Returns dynamic (basically it means, I don't know yet during the compilation, so I'll check during runtime)
  // Because JSON can be either be a Map or a list
  static Future<dynamic> get(String path, {bool authenticated = true}) async {
    return _withRediscoveryRetry(() async {

      // Same pattern as above: check base URL, build headers, send, check response
      final baseUrl = Session.instance.baseUrl;
      if (baseUrl == null) {
        throw ApiException(0, 'Server not found. Please check your connection.');
      }

      final headers = <String, String>{};
      if (authenticated && Session.instance.token != null) {
        headers['Authorization'] = 'Bearer ${Session.instance.token}';
      }

      final response = await http
          .get(Uri.parse('$baseUrl$path'), headers: headers)
          .timeout(const Duration(seconds: 5));

      _captureRefreshedToken(response);

      final data = jsonDecode(response.body);
      if (response.statusCode >= 400) {
        final message = (data is Map && data['error'] != null) ? data['error'] : 'Request failed';
        throw ApiException(response.statusCode, message);
      }
      return data;
    });
  }

  // Sends a DELETE request, so far at this point, waiter can only delete their own quick item (as in unpin it)
  // Doesn't return anything, if it succeeded.
  static Future<void> delete(String path) async {
    return _withRediscoveryRetry(() async {
      final baseUrl = Session.instance.baseUrl;
      if (baseUrl == null) {
        throw ApiException(0, 'Server not found. Please check your connection.');
      }

      final headers = <String, String>{};
      if (Session.instance.token != null) {
        headers['Authorization'] = 'Bearer ${Session.instance.token}';
      }

      final response = await http
          .delete(Uri.parse('$baseUrl$path'), headers: headers)
          .timeout(const Duration(seconds: 5));

      _captureRefreshedToken(response);

      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, 'Request failed');
      }
    });
  }

  // If a request fails to even connect (timeout, socket error, whatever)
  // Like, it could be a stale server adress, not a normal 4##/5###
  // this skips the cached  address, re-runs discovery, saves the new adress and retries the request once.
  // In hosted/demo mode, it retries the same URL the app was built with (SERVER_URL), since there is no discovery to find another one.
  static Future<T> _withRediscoveryRetry<T>(Future<T> Function() attempt) async {
    try {
      return await attempt();
    } on ApiException {
      rethrow; // A real HTTP error (401, 404, etc.) — not a connectivity problem.
    } catch (_) {
      final freshUrl = await ServerLocator.rediscover();
      if (freshUrl == null) {
        throw ApiException(0, 'Could not reach CommonTable server. Please check your connection.');
      }
      Session.instance.baseUrl = freshUrl;
      return await attempt();
    }
  }

  // Saves a new updated session token
  static void _captureRefreshedToken(http.Response response) {
    final refreshed = response.headers['x-refreshed-token'];
    if (refreshed != null && refreshed.isNotEmpty) {
      Session.instance.updateToken(refreshed);
    }
  }
}