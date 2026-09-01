import 'package:flutter/material.dart';
import 'package:waiter_app/api/api_client.dart';
import 'package:waiter_app/api/auth_api.dart';
import 'package:waiter_app/screens/login_prime.dart';
import 'package:waiter_app/screens/waiter_login_screen.dart';
import 'package:waiter_app/state/saved_credentials.dart';
import 'package:waiter_app/state/session.dart';
import 'package:waiter_app/state/system_ui_controller.dart';
import 'package:waiter_app/theme/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.instance.loadThemes();
  await SystemUiController.start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Waiter App',
          theme: ThemeManager.instance.currentTheme.toThemeData(),
          home: const AppEntryPoint(),
        );
      },
    );
  }
}

/// Decides where to land the user on app launch: if a restaurant login
/// was remembered, silently verify it's still valid and skip straight to
/// the waiter login screen; otherwise show the normal restaurant login.
///
/// This re-verifies against the server rather than trusting the cached
/// credential blindly — a stale/invalid saved password should fall back
/// to the manual login screen, not get stuck.
class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final saved = await SavedCredentials.getRestaurant();
    if (saved == null) {
      _goToLoginPrime();
      return;
    }

    try {
      final result = await AuthApi.restaurantLogin(saved.name, saved.password);
      Session.instance.restaurantId = result['restaurant_id'] as int;
      Session.instance.restaurantName = result['restaurant_name'] as String;
      Session.instance.restaurantLogoUrl = result['logo_url'] as String? ?? '';
      _goToWaiterLogin();
    } on ApiException {
      // Saved password no longer valid (changed on the server, etc.) —
      // fall back to manual login rather than getting stuck.
      await SavedCredentials.clearRestaurant();
      _goToLoginPrime();
    } catch (_) {
      // Connectivity issue — same fallback, don't trap the user here.
      _goToLoginPrime();
    }
  }

  void _goToLoginPrime() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPrime()),
    );
  }

  void _goToWaiterLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WaiterLoginScreen(restaurantName: Session.instance.restaurantName!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}