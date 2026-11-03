import 'package:flutter/material.dart';
import 'package:waiter_app/api/auth_api.dart';
import 'package:waiter_app/api/api_client.dart';
import 'package:waiter_app/api/server_locator.dart';
import 'package:waiter_app/screens/waiter_login_screen.dart';
import 'package:waiter_app/state/session.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';
import 'package:waiter_app/widgets/components/action/misc_button_widget.dart';
import 'package:waiter_app/widgets/components/action/touch_icon_widget.dart';
import 'package:waiter_app/widgets/components/display/standard_app_bar.dart';
import 'package:waiter_app/widgets/components/inputs/text_field_input.dart';
import 'package:waiter_app/state/saved_credentials.dart';

class LoginPrime extends StatefulWidget {
  const LoginPrime({super.key});

  @override
  State<LoginPrime> createState() => _LoginPrimeState();
}

class _LoginPrimeState extends State<LoginPrime> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _errorMessage = null);

    //Missing name or pass
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter restaurant name');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter password');
      return;
    }

    //sets the spinner thingy
    setState(() => _isLoading = true);

    try {
      // Locate the server first, if it hasn't already.
      Session.instance.baseUrl ??= await ServerLocator.locate();
      if (Session.instance.baseUrl == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not find CommonTable server on this network.';
        });
        return;
      }

      //Get restaurant stuff (logo, what the waiter creds are ) from name/pass inputs
      final result = await AuthApi.restaurantLogin(name, password);

      //Set session, based on what was returned.
      Session.instance.restaurantId = result['restaurant_id'] as int;
      Session.instance.restaurantName = result['restaurant_name'] as String;
      Session.instance.restaurantLogoUrl = result['logo_url'] as String? ?? '';

      await SavedCredentials.saveRestaurant(name, password);


      //If it is not mounted, checks if the screen exists
      if (!mounted) return;

      //Removes the spinner.
      setState(() => _isLoading = false);

      //Opens next screen - waiter login
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WaiterLoginScreen(
            restaurantName: Session.instance.restaurantName!,
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (context, _) {
        final theme = ThemeManager.instance.currentTheme;

        return Scaffold(
          appBar: StandardAppBar(
            rightActions: [
              TouchIconWidget(
                icon: Icons.palette,
                onTap: () {
                  final names = ThemeManager.instance.themeNames;
                  if (names.isEmpty) return;
                  final current = names.indexOf(
                    ThemeManager.instance.currentTheme.name,
                  );
                  final next = names[(current + 1) % names.length];
                  ThemeManager.instance.setTheme(next);
                },
              ),
              TouchIconWidget(icon: Icons.language, onTap: () {}),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              child: Column(
                children: [
                  const SizedBox(height: DesignTokens.spacingLg),
                  Column(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        width: 120,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.restaurant,
                            size: 80,
                            color: theme.brandDark,
                          );
                        },
                      ),
                      const SizedBox(height: DesignTokens.spacingSm),
                      Text(
                        'CommonTable',
                        style: TextStyle(
                          color: theme.brandDark,
                          fontSize: DesignTokens.fontDisplay,
                          fontWeight: FontWeight.w700,
                          letterSpacing: DesignTokens.letterSpacingWide,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacingXl),
                  Container(
                    padding: EdgeInsets.all(DesignTokens.spacingMd),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusLg,
                      ),
                      border: Border.all(
                        color: theme.brandDark,
                        width: DesignTokens.borderThin,
                      ),
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Restaurant Sign In',
                            style: TextStyle(
                              color: theme.content,
                              fontSize: DesignTokens.fontH2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacingMd),
                        TextFieldInput(
                          controller: _nameController,
                          label: 'Restaurant Name',
                        ),
                        TextFieldInput(
                          controller: _passwordController,
                          label: 'Password',
                          isPassword: true,
                          hintText: 'Enter your password',
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: DesignTokens.spacingSm),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: theme.alert,
                                fontSize: DesignTokens.fontCaption,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: DesignTokens.spacingMd),
                        SizedBox(
                          width: double.infinity,
                          child: MiscButtonWidget(
                            label: 'Sign In',
                            onPressed: _handleSignIn,
                            isLoading: _isLoading,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacingSm),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingLg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}