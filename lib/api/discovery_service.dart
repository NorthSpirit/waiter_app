import 'dart:async';
import 'dart:convert';
import 'dart:io';

class DiscoveryService {
  static const int _discoveryPort = 41242;
  static const String _magic = 'COMMONTABLE_DISCOVER';
  static const int _httpPort = 41241;

  /// Tries UDP broadcast first (fast when it works), then falls back to
  /// a subnet sweep over plain TCP if broadcast gets no response — some
  /// routers pass ordinary unicast traffic fine but drop broadcast
  /// frames between wireless clients.
  static Future<String?> discoverServer({
    Duration broadcastTimeout = const Duration(seconds: 2),
  }) async {
    final broadcastResult = await _tryBroadcast(broadcastTimeout);
    if (broadcastResult != null) return broadcastResult;

    return await _trySubnetSweep();
  }

  static Future<String?> _tryBroadcast(Duration timeout) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      socket.send(
        utf8.encode(_magic),
        InternetAddress('255.255.255.255'),
        _discoveryPort,
      );

      final completer = Completer<String?>();

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final packet = socket!.receive();
          if (packet == null) return;
          try {
            final data = jsonDecode(utf8.decode(packet.data));
            final port = data['port'] as int;
            final ip = packet.address.address;
            if (!completer.isCompleted) {
              completer.complete('http://$ip:$port');
            }
          } catch (_) {}
        }
      });

      return await completer.future.timeout(timeout, onTimeout: () => null);
    } catch (_) {
      return null;
    } finally {
      socket?.close();
    }
  }

  /// Finds this device's own local IPv4 address, assumes a /24 subnet,
  /// and tries connecting to /api/discover on every candidate address
  /// in parallel (in small batches to avoid opening 254 sockets at once).
  static Future<String?> _trySubnetSweep() async {
    final localIp = await _getLocalIPv4();
    if (localIp == null) return null;

    final parts = localIp.split('.');
    if (parts.length != 4) return null;
    final subnetPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';

    const batchSize = 32;
    for (var start = 1; start <= 254; start += batchSize) {
      final end = (start + batchSize - 1).clamp(1, 254);
      final candidates = [for (var i = start; i <= end; i++) '$subnetPrefix.$i'];

      final result = await _probeCandidates(candidates);
      if (result != null) return result;
    }

    return null;
  }

  static Future<String?> _probeCandidates(List<String> ips) async {
    final completer = Completer<String?>();
    var remaining = ips.length;

    for (final ip in ips) {
      _probeOne(ip).then((found) {
        if (found && !completer.isCompleted) {
          completer.complete('http://$ip:$_httpPort');
        }
        remaining--;
        if (remaining == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    return completer.future;
  }

  static Future<bool> _probeOne(String ip) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(milliseconds: 400);
      final request = await client
          .getUrl(Uri.parse('http://$ip:$_httpPort/api/discover'))
          .timeout(const Duration(milliseconds: 500));
      final response = await request.close().timeout(const Duration(milliseconds: 500));
      final body = await response.transform(utf8.decoder).join();
      client.close();
      return response.statusCode == 200 && body == 'commontable';
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _getLocalIPv4() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return null;
  }
}