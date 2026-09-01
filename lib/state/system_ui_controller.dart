import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';

/// Keeps the Android status/nav bars hidden during normal use, but shows
/// them automatically once battery drops to a critical level, so the
/// waiter can still see the real battery indicator when it matters.
/// Uses hysteresis (show at 10%, hide again at 15%) to avoid the bars
/// flickering in and out right at the threshold.
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

    // React immediately to plug-in/unplug rather than waiting for the
    // next poll — charging state changes are cheap to listen for and
    // catch the common "oh no, low battery, let me plug in" moment fast.
    _stateSubscription = _battery.onBatteryStateChanged.listen((_) {
      _checkBattery();
    });
  }

  static void stop() {
    _pollTimer?.cancel();
    _stateSubscription?.cancel();
  }

  static Future<void> _checkBattery() async {
    final level = await _battery.batteryLevel;

    if (!_barsVisible && level <= _showThreshold) {
      await _showBars();
    } else if (_barsVisible && level >= _hideThreshold) {
      await _hideBars();
    }
  }

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