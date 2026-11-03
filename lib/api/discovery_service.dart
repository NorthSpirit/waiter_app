import 'dart:async';
import 'dart:convert';
import 'dart:io';

// A class to attempt to find the local network CommonTable server
// Avoiding the waiter having to type in the IP anywhere (in fact, it's impossible to do it manually)
// Works in 2 steps: at first uses an UPD broadcast
// And if it doesn't work, tries every IP in the subnet in the brute-force manner
class DiscoveryService {

  // UPD Listening port for the CommonTable is always the same - 41242 and it is not adviced to change it ever
  static const int _discoveryPort = 41242;

  // The hello phrase (magic string) CommonTable server recognises. Anything other than it is ignored.
  static const String _magic = 'COMMONTABLE_DISCOVER';

  // CommonTable's TCP port of the HTTP API, same with the 41242 one, always the same.
  static const int _httpPort = 41241;

  // Tries the UDP broadcast first, if it works, it's fast
  // If it fails, it attempts to brute-force Sweep
  static Future<String?> discoverServer({
    Duration broadcastTimeout = const Duration(seconds: 2),
  }) async {
    final broadcastResult = await _tryBroadcast(broadcastTimeout);
    if (broadcastResult != null) return broadcastResult;

    // Broadcast method has failed - attempt the brute-force
    return await _trySubnetSweep();
  }

  // The first, clean strategy - shout "COMMONTABLE_DISCOVER" at the whole network
  // and wait until server replies with it's HTTP port.
  static Future<String?> _tryBroadcast(Duration timeout) async {
    RawDatagramSocket? socket;
    try {

      // Port 0 means, the OS picks any available port and the server will reply using the same port.
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      // Dart has sending to the broadcast is blocked by default, so it has to enabled.
      socket.broadcastEnabled = true;

      // 255.255.255.255 is the braodcast address - all the devices on the local network segment will receive it.
      socket.send(
        utf8.encode(_magic),
        InternetAddress('255.255.255.255'),
        _discoveryPort,
      );

      // Completer allows to use Future - instead of dart blocking the process, it becomes "Something will eventually reply or it will timeout"
      final completer = Completer<String?>();

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final packet = socket!.receive();
          if (packet == null) return;
          try {
            // CommonTable uses JSON, so JSON is expected
            final data = jsonDecode(utf8.decode(packet.data));
            
            // Port is parsed from the message body, since broadcast and actually used one might not match
            final port = data['port'] as int;

            // Server IP is parsed from the packet's source address for reliability.
            final ip = packet.address.address;

            // Firt valid reply always wins
            if (!completer.isCompleted) {
              completer.complete('http://$ip:$port');
            }
          } catch (_) {} // In case it's malformed or unrelated
        }
      });

      // Gives up after timeout ticks up.
      return await completer.future.timeout(timeout, onTimeout: () => null);
    } catch (_) {
      // Any socket error (no network, permission denied, the internet has exploded, whatever else) = no result.
      return null;
    } finally {
      socket?.close(); // Closes the socket, regardless of the result in order not to hoard it.
    }
  }

  // Finds this device's own local IPv4 address 
  // and attempts to connect to the /api/discover on every available candidate
  // uses small baches, for one reason, not to go one by one
  // on the other, not to open 254 sockets at once.
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

  // Probes a list of IPs concurrently and returns if one of them is the CommomnTable server (or a null, if all batch failed)
  static Future<String?> _probeCandidates(List<String> ips) async {
    final completer = Completer<String?>();
    var remaining = ips.length;

    for (final ip in ips) {
      _probeOne(ip).then((found) {
        if (found && !completer.isCompleted) {
          completer.complete('http://$ip:$_httpPort');
        }
        remaining--;

        // If nothing had matched correctly returns null from this batch
        if (remaining == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    return completer.future;
  }

  // First, only checks if there is a CommonTable server on said IP and returns true or false.
  static Future<bool> _probeOne(String ip) async {
    try {
      final client = HttpClient();

      // Timeouts are short in here deliberately - nearly all of the addresses are empty,
      // and with the default (long) timeout, scanning all of them would take minutes.
      client.connectionTimeout = const Duration(milliseconds: 400);
      final request = await client
          .getUrl(Uri.parse('http://$ip:$_httpPort/api/discover'))
          .timeout(const Duration(milliseconds: 500));
      final response = await request.close().timeout(const Duration(milliseconds: 500));
      final body = await response.transform(utf8.decoder).join();
      client.close();

      // Bruteforce expects specifically 200 OK response code with a text "commontable" so it wouldn't get mistaken for anything else
      return response.statusCode == 200 && body == 'commontable';
    } catch (_) {

      // Connection refused, timeout, host unreachable... = not what I need.
      return false;
    }
  }

  // Helper method used to figure out, which subnet to scan.
  static Future<String?> _getLocalIPv4() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false, // Skip 127.0.0.1
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