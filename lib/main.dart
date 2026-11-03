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

// Decides where to land the user on app launch:
// if a restaurant login was remembered, silently verify it's still valid and skip straight to the waiter login screen;
// otherwise show the normal restaurant login.
// This re-verifies against the server a stale/invalid saved password will fall back to the manual login screen.
class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  // Filled in if reading the saved login fails, so the reason is shown on screen instead of an endless spinner.
  String? _startupError;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    // Checks if the restaurant cretendtials were used in the app before
    // If reading them fails or takes more than 5 seconds, shows the reason on screen (see build)
    ({String name, String password})? saved;
    try {
      saved = await SavedCredentials.getRestaurant().timeout(const Duration(seconds: 5));
    } catch (e) {
      if (mounted) setState(() => _startupError = 'Could not read saved login:\n$e');
      return;
    }

    // If it's basically first time log-in (nothing saved), just redirects to the login screen for the restaurant
    if (saved == null) {
      _goToLoginPrime();
      return;
    }

    // If there were something before, attempt the log in with those
    try {
      // Calls the server and attempts to use the credentials provided
      final result = await AuthApi.restaurantLogin(saved.name, saved.password);
      // the result of the call is used for restaurant id, name and logo (logo is used on the next screen)
      Session.instance.restaurantId = result['restaurant_id'] as int;
      Session.instance.restaurantName = result['restaurant_name'] as String;
      Session.instance.restaurantLogoUrl = result['logo_url'] as String? ?? '';
      // With successful restaurant login, it allows to go to the waiter login.
      // Since instance state is globally used, no need to pass credentials down to the screen.
      _goToWaiterLogin();
    } on ApiException {
      // Saved password no longer valid — fall back to manual login.
      await SavedCredentials.clearRestaurant();
      _goToLoginPrime();
    } catch (_) {
      // Connectivity issue (could be internet, could be server) — same fallback.
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
    // If something went wrong reading the saved login, shows what, with a button to continue to the normal login.
    if (_startupError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_startupError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _goToLoginPrime,
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}