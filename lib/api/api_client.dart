import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:waiter_app/api/server_locator.dart';
import 'package:waiter_app/state/session.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    return _withRediscoveryRetry(() async {
      final baseUrl = Session.instance.baseUrl;
      if (baseUrl == null) {
        throw ApiException(0, 'Server not found. Please check your connection.');
      }

      final headers = {'Content-Type': 'application/json'};
      if (authenticated && Session.instance.token != null) {
        headers['Authorization'] = 'Bearer ${Session.instance.token}';
      }

      final response = await http
          .post(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 5));

      _captureRefreshedToken(response);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, data['error'] ?? 'Request failed');
      }
      return data;
    });
  }

  static Future<dynamic> get(String path, {bool authenticated = true}) async {
    return _withRediscoveryRetry(() async {
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

  /// If a request fails to even connect (timeout, socket error — i.e. the
  /// cached server address is probably stale, not just a normal 4xx/5xx),
  /// this drops the cache, re-runs discovery, and retries the request
  /// exactly once against whatever address discovery finds this time.
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

  static void _captureRefreshedToken(http.Response response) {
    final refreshed = response.headers['x-refreshed-token'];
    if (refreshed != null && refreshed.isNotEmpty) {
      Session.instance.updateToken(refreshed);
    }
  }
}