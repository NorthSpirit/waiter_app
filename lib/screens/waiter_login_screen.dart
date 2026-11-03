import 'package:flutter/material.dart';
import 'package:waiter_app/api/api_client.dart';
import 'package:waiter_app/api/auth_api.dart';
import 'package:waiter_app/screens/main_screen.dart';
import 'package:waiter_app/state/saved_credentials.dart';
import 'package:waiter_app/state/session.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';
import 'package:waiter_app/widgets/components/action/misc_button_widget.dart';
import 'package:waiter_app/widgets/components/action/touch_icon_widget.dart';
import 'package:waiter_app/widgets/components/display/standard_app_bar.dart';
import 'package:waiter_app/widgets/components/inputs/text_field_input.dart';

class WaiterLoginScreen extends StatefulWidget {
  final String restaurantName;

  const WaiterLoginScreen({super.key, required this.restaurantName});

  @override
  State<WaiterLoginScreen> createState() => _WaiterLoginScreenState();
}

class _WaiterLoginScreenState extends State<WaiterLoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedName();
  }

  //Gets waiter's name if it's saved before for quality of life
  Future<void> _loadSavedName() async {
    final savedName = await SavedCredentials.getWaiterName();
    if (savedName != null && mounted) {
      _nameController.text = savedName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();

    //Clears error, just in case there was one before, like a failed attempt prior to this one.
    setState(() => _errorMessage = null);

    //Name or password check - if there is anything at all
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name');
      return;
    }
    if (pin.isEmpty) {
      setState(() => _errorMessage = 'Please enter PIN');
      return;
    }

    //Spinner up
    setState(() => _isLoading = true);

    try {
      //Try calling the server to confirm the credentials, if they are correct
      final result = await AuthApi.employeeLogin(
        Session.instance.restaurantId!,
        name,
        pin,
      );

      //If it's correct, sets session token and staff member's role (role matters, cause it might be a waiter or a manager)
      Session.instance.token = result['token'] as String;
      Session.instance.employeeId = result['employee_id'] as int;
      Session.instance.employeeName = result['name'] as String;
      Session.instance.role = result['role'] as String;

      //For quality of life, save waiter's name for the future
      await SavedCredentials.saveWaiterName(name);

      if (!mounted) return;

      //Spinner down
      setState(() => _isLoading = false);

      //Replace this screen with the next one - the main screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } on ApiException catch (e) { //Credentials were not confirmed or some other rejection by the server.
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() { //Some other problem, mayhaps server is down or the internet is down.
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
            leftActions: [
              TouchIconWidget(
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              ),
            ],
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
                      Session.instance.restaurantLogoFullUrl.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                Session.instance.restaurantLogoFullUrl,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.restaurant,
                                    size: 80,
                                    color: theme.brandDark,
                                  );
                                },
                              ),
                            )
                          : Image.asset(
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
                        widget.restaurantName,
                        style: TextStyle(
                          color: theme.brandDark,
                          fontSize: DesignTokens.fontDisplay,
                          fontWeight: FontWeight.w700,
                          letterSpacing: DesignTokens.letterSpacingWide,
                        ),
                      ),
                      Text(
                        'Waiter Login',
                        style: TextStyle(
                          color: theme.content.withValues(
                            alpha: DesignTokens.opacitySoft,
                          ),
                          fontSize: DesignTokens.fontBody,
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
                            'Waiter Sign In',
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
                          label: 'Your Name',
                        ),
                        TextFieldInput(
                          controller: _pinController,
                          label: 'PIN',
                          isPassword: true,
                          hintText: 'Enter your PIN',
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