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
    //If there were previous shenanigans, the error message might have an error, so clear it just in case.
    setState(() => _errorMessage = null);
    try {
      //Call the server and attempt to get the items of the menu picked. Menu id comes from the previous screen
      final items = await MenuApi.listMenuItems(widget.menuId);
      setState(() => _items = items);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load items. Pull down to retry.');
    }
  }

  //Waiters have the ability to save their pinned items as basically a quick menu
  Future<void> _loadPinnedIds() async {
    try {
      //Like with all the other stuff, calls the server to attempt to get the quick items for the waiter/manager.
      final quickItems = await QuickItemsApi.list();
      if (mounted) {
        //Saves the IDs of pinned items, used to label tiles as Pin/Unpin.
        setState(() => _pinnedItemIds = quickItems.map((q) => q.itemId).toSet());
      }
    } catch (e) {
      // If this fails, pin-mode still works — items just won't show as already-pinned until it is successful reopened.
    }
  }

  //Option to pin/unpin, it goes to pin/unpin mode, from the setting
  Future<void> _togglePin(MenuItem item) async {
    //Checks if the list of pinned items has that item’s ID
    final isPinned = _pinnedItemIds.contains(item.id);

    try {
      //Checks if the item is pinned
      if (isPinned) {
        //Calls the server requesting to remove from pins.
        await QuickItemsApi.remove(item.id);
        setState(() => _pinnedItemIds.remove(item.id));
      } else {
        //Item is not pinned yet, so call the server to add it to the pinned list.
        //If it was a misclick, tapping the same button again unpins it.
        await QuickItemsApi.add(item.id);
        setState(() => _pinnedItemIds.add(item.id));
      }
    } catch (e) {
      if (mounted) {
        //Waiters are limited to 15 items in the pin mode, because it should be the list of quick access, not the "I want it all" list
        //When the limit is hit, the server's error says "max 15", so the app checks for that text.
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
                  //Returns to the previous screen, where the order button is.
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

    //Pin mode is changed in options, thus, saved in the session state and gotten from the session state
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
                    //Creates a new screen with item id already handed.
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