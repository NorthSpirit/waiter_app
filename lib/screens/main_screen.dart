import 'package:flutter/material.dart';
import 'package:waiter_app/api/menu_api.dart';
import 'package:waiter_app/models/menu.dart';
import 'package:waiter_app/screens/menu_screen.dart';
import 'package:waiter_app/screens/order_review_screen.dart';
import 'package:waiter_app/screens/quick_items_screen.dart';
import 'package:waiter_app/screens/search_screen.dart';
import 'package:waiter_app/screens/settings_screen.dart';
import 'package:waiter_app/screens/table_picker_screen.dart';
import 'package:waiter_app/state/cart.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';
import 'package:waiter_app/widgets/components/action/misc_button_widget.dart';
import 'package:waiter_app/widgets/components/action/touch_icon_widget.dart';
import 'package:waiter_app/widgets/components/display/info_list_tile.dart';
import 'package:waiter_app/widgets/components/display/standard_app_bar.dart';
import 'package:waiter_app/screens/order_status_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<RestaurantMenu>? _menus;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    setState(() => _errorMessage = null);
    try {
      //Attempt to call the server and get the existing menus.
      final menus = await MenuApi.listMenus();
      setState(() => _menus = menus);
    } catch (e) {
      setState(
        () => _errorMessage = 'Failed to load menus. Pull down to retry.',
      );
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
              Expanded(
                child: AnimatedBuilder(
                  animation: Cart.instance,
                  builder: (context, _) {
                    return GestureDetector(
                      onLongPress: Cart.instance.started
                          ? () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Clear Order?'),
                                  content: const Text(
                                    'This will remove all items and the selected table/take-out from this order.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Clear'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                Cart.instance.clear();
                              }
                            }
                          : null,
                      child: MiscButtonWidget(
                        label: !Cart.instance.started
                            ? 'STATUS'
                            : (Cart.instance.tableId == null
                                  ? 'Take-Out — ${Cart.instance.itemCount} item(s)'
                                  : 'Table ${Cart.instance.tableNumber} — ${Cart.instance.itemCount} item(s)'),
                        onPressed: () async {
                          if (!Cart.instance.started) {
                            await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TablePickerScreen(),
                              ),
                            );
                          } else {
                            await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OrderReviewScreen(),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
            rightActions: [
              TouchIconWidget(
                icon: Icons.receipt_long,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrderStatusScreen(),
                    ),
                  );
                },
              ),
              TouchIconWidget(
                icon: Icons.search,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
              ),
              TouchIconWidget(
                icon: Icons.settings,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              InfoListTile(
                icon: Icons.push_pin,
                title: 'Pinned items',
                arrowType: TrailingArrowType.chevron,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuickItemsScreen()),
                  );
                },
              ),
              const SizedBox(height: DesignTokens.spacingSm),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: theme.brandLight.withValues(
                          alpha: DesignTokens.opacitySoft,
                        ),
                        width: DesignTokens.borderHairline,
                      ),
                      bottom: BorderSide(
                        color: theme.brandLight.withValues(
                          alpha: DesignTokens.opacitySoft,
                        ),
                        width: DesignTokens.borderHairline,
                      ),
                    ),
                  ),
                  child: _buildMenuList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuList() {
    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _loadMenus,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingLg),
              child: Text(_errorMessage!, textAlign: TextAlign.center),
            ),
          ],
        ),
      );
    }

    if (_menus == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_menus!.isEmpty) {
      return const Center(child: Text('No menus available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadMenus,
      child: Padding(
        padding: EdgeInsets.only(bottom: DesignTokens.spacingLg),
        child: ListView.builder(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingSm),
          itemCount: _menus!.length,
          itemBuilder: (context, index) {
            final menu = _menus![index];
            return InfoListTile(
              title: menu.name,
              subtitle: menu.description.isNotEmpty ? menu.description : null,
              arrowType: TrailingArrowType.chevron,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MenuScreen(menuId: menu.id, menuName: menu.name), // Hands the menu id and name for the next screen.
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
