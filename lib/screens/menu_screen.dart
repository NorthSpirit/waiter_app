import 'package:flutter/material.dart';
import 'package:waiter_app/api/menu_api.dart';
import 'package:waiter_app/api/quick_items_api.dart';
import 'package:waiter_app/models/menu_item.dart';
import 'package:waiter_app/screens/item_detail_screen.dart';
import 'package:waiter_app/state/cart.dart';
import 'package:waiter_app/state/session.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';
import 'package:waiter_app/widgets/components/action/touch_icon_widget.dart';
import 'package:waiter_app/widgets/components/display/standard_app_bar.dart';
import 'package:waiter_app/widgets/components/menuitemtile.dart';

class MenuScreen extends StatefulWidget {
  final int menuId;
  final String menuName;

  const MenuScreen({super.key, required this.menuId, required this.menuName});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Set<int> _pinnedItemIds = {};

  List<MenuItem>? _items;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadPinnedIds();
  }

  Future<void> _loadItems() async {
    setState(() => _errorMessage = null);
    try {
      final items = await MenuApi.listMenuItems(widget.menuId);
      setState(() => _items = items);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load items. Pull down to retry.');
    }
  }

  Future<void> _loadPinnedIds() async {
    try {
      final quickItems = await QuickItemsApi.list();
      if (mounted) {
        setState(() => _pinnedItemIds = quickItems.map((q) => q.itemId).toSet());
      }
    } catch (e) {
      // If this fails, pin-mode still works — items just won't show as
      // already-pinned until the next successful load.
    }
  }

  Future<void> _togglePin(MenuItem item) async {
    final isPinned = _pinnedItemIds.contains(item.id);

    try {
      if (isPinned) {
        await QuickItemsApi.remove(item.id);
        setState(() => _pinnedItemIds.remove(item.id));
      } else {
        await QuickItemsApi.add(item.id);
        setState(() => _pinnedItemIds.add(item.id));
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().contains('max 15')
            ? 'Pin limit reached (max 15).'
            : 'Failed to update pinned items.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: StandardAppBar(
            leftActions: [
              TouchIconWidget(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
            ],
            title: widget.menuName,
            rightActions: [
              if (Session.instance.pinMode)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingXs),
                  child: Row(
                    children: [
                      const Icon(Icons.push_pin, size: 18),
                      const SizedBox(width: 4),
                      Text('PIN MODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              TouchIconWidget(
                icon: Icons.shopping_cart,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _loadItems,
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

    if (_items == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items!.isEmpty) {
      return const Center(child: Text('No items on this menu.'));
    }

    final pinMode = Session.instance.pinMode;

    return RefreshIndicator(
      onRefresh: _loadItems,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingSm),
        itemCount: _items!.length,
        itemBuilder: (context, index) {
          final item = _items![index];
          final isPinned = _pinnedItemIds.contains(item.id);

          return Opacity(
            opacity: item.isAvailable ? 1.0 : DesignTokens.opacityDisabled,
            child: MenuItemTile(
              name: item.isAvailable ? item.name : '${item.name} (Unavailable)',
              price: pinMode ? (isPinned ? 'Unpin' : 'Pin') : item.formattedPrice,
              quantity: pinMode ? 0 : Cart.instance.quantityOf(item.id),
              onTap: () {
                if (pinMode) {
                  _togglePin(item);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
                  );
                }
              },
              onAdd: pinMode
                  ? () => _togglePin(item)
                  : (item.isAvailable ? () => setState(() => Cart.instance.addItem(item.id, item.name, item.price)) : () {}),
              onRemove: pinMode ? () => _togglePin(item) : () => setState(() => Cart.instance.removeOne(item.id)),
            ),
          );
        },
      ),
    );
  }
}