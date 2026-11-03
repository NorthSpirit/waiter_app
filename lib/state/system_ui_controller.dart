import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';

// Keeps the Android status/nav bar hidden during the normal use
// So it wouldn't clutter the screen
// However, it still allows the waiter to see the battery, if it goes low, so it wouldn't surprise anyone.
class SystemUiController {
  static const int _showThreshold = 10;
  static const int _hideThreshold = 15;
  static const Duration _pollInterval = Duration(minutes: 2);

  static final Battery _battery = Battery();
  static Timer? _pollTimer;
  static StreamSubscription<BatteryState>? _stateSubscription;
  static bool _barsVisible = false;

  static Future<void> start() async {
    await _hideBars();
    await _checkBattery();

    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkBattery());

    // Basically, plug/unplug is reacted to instantly, without waiting for the next poll.
    _stateSubscription = _battery.onBatteryStateChanged.listen((_) {
      _checkBattery();
    });
  }

  static void stop() {
    _pollTimer?.cancel();
    _stateSubscription?.cancel();
  }

  // There is a slight deliberate gap to avoid flickering
  // The bar is shown at 10%, but hidden again at 15% (as in it is charging and reaches 15 again)
  static Future<void> _checkBattery() async {
    final level = await _battery.batteryLevel;

    if (!_barsVisible && level <= _showThreshold) {
      await _showBars();
    } else if (_barsVisible && level >= _hideThreshold) {
      await _hideBars();
    }
  }

  // Both set the _barsVisible flag, 
  // Which _checkBattery reads, so that between 10% and 15% the bars keep their current state (the anti-flicker gap).
  static Future<void> _hideBars() async {
    _barsVisible = false;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  static Future<void> _showBars() async {
    _barsVisible = true;
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }
}