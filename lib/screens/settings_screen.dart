import 'package:flutter/material.dart';
import 'package:waiter_app/api/quick_items_api.dart';
import 'package:waiter_app/screens/chat_screen.dart';
import 'package:waiter_app/screens/login_prime.dart';
import 'package:waiter_app/state/saved_credentials.dart';
import 'package:waiter_app/state/session.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';
import 'package:waiter_app/widgets/components/action/touch_icon_widget.dart';
import 'package:waiter_app/widgets/components/display/info_list_tile.dart';
import 'package:waiter_app/widgets/components/display/standard_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoggingOut = false;
  bool _isClearingPinned = false;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    await SavedCredentials.clearRestaurant();
    Session.instance.clear();

    if (!mounted) return;
    setState(() => _isLoggingOut = false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPrime()),
      (route) => false,
    );
  }

  Future<void> _handleClearPinned() async {
    if (_isClearingPinned) return;
    setState(() => _isClearingPinned = true);

    try {
      final items = await QuickItemsApi.list();
      for (final item in items) {
        await QuickItemsApi.remove(item.itemId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pinned items cleared.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to clear pinned items.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isClearingPinned = false);
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
              TouchIconWidget(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
            ],
            title: 'Settings',
          ),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              InfoListTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'Not yet available',
                onTap: null,
              ),
              Divider(height: DesignTokens.borderHairline, color: theme.brandLight.withValues(alpha: DesignTokens.opacitySoft)),

              InfoListTile(
                icon: Icons.palette,
                title: 'Colour',
                arrowType: TrailingArrowType.chevron,
                onTap: () {
                  final names = ThemeManager.instance.themeNames;
                  if (names.isEmpty) return;
                  final current = names.indexOf(ThemeManager.instance.currentTheme.name);
                  final next = names[(current + 1) % names.length];
                  ThemeManager.instance.setTheme(next);
                },
              ),
              Divider(height: DesignTokens.borderHairline, color: theme.brandLight.withValues(alpha: DesignTokens.opacitySoft)),

              InfoListTile(
                icon: Icons.push_pin_outlined,
                title: 'Clear Pinned',
                subtitle: _isClearingPinned ? 'Clearing...' : null,
                onTap: _isClearingPinned ? null : _handleClearPinned,
              ),
              InfoListTile(
                icon: Icons.push_pin,
                title: 'Pin Mode',
                subtitle: Session.instance.pinMode ? 'On — tapping an item pins it' : 'Off',
                trailing: Switch(
                  value: Session.instance.pinMode,
                  onChanged: (value) => setState(() => Session.instance.pinMode = value),
                  activeColor: theme.brandDark,
                ),
              ),
              Divider(height: DesignTokens.borderHairline, color: theme.brandLight.withValues(alpha: DesignTokens.opacitySoft)),

              InfoListTile(
                icon: Icons.chat_bubble_outline,
                title: 'Message',
                arrowType: TrailingArrowType.chevron,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  );
                },
              ),
              Divider(height: DesignTokens.borderHairline, color: theme.brandLight.withValues(alpha: DesignTokens.opacitySoft)),

              InfoListTile(
                icon: Icons.logout,
                title: _isLoggingOut ? 'Logging out...' : 'Log Out',
                onTap: _isLoggingOut ? null : _handleLogout,
              ),
            ],
          ),
        );
      },
    );
  }
}