import 'package:flutter/material.dart';
import 'package:waiter_app/api/quick_items_api.dart';
import 'package:waiter_app/models/quick_item.dart';
import 'package:waiter_app/screens/item_detail_screen.dart';
import 'package:waiter_app/state/cart.dart';
import 'package:waiter_app/state/session.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';
import 'package:waiter_app/widgets/components/action/touch_icon_widget.dart';
import 'package:waiter_app/widgets/components/display/standard_app_bar.dart';
import 'package:waiter_app/widgets/components/menuitemtile.dart';

class QuickItemsScreen extends StatefulWidget {
  const QuickItemsScreen({super.key});

  @override
  State<QuickItemsScreen> createState() => _QuickItemsScreenState();
}

class _QuickItemsScreenState extends State<QuickItemsScreen> {
  List<QuickItem>? _items;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _errorMessage = null);
    try {
      final items = await QuickItemsApi.list();
      setState(() => _items = items);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load pinned items.');
    }
  }

  Future<void> _unpin(int itemId) async {
    try {
      await QuickItemsApi.remove(itemId);
      _load();
    } catch (e) {
      // Ignore — list will just show the stale state until next refresh.
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
            title: 'Pinned Items',
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
            ],
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingLg),
          child: Text('No pinned items yet. Enable Pin Mode from Settings to add some.'),
        ),
      );
    }

    final pinMode = Session.instance.pinMode;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _items!.length,
        itemBuilder: (context, index) {
          final item = _items![index];
          return MenuItemTile(
            name: item.name,
            price: pinMode ? 'Unpin' : item.formattedPrice,
            quantity: pinMode ? 0 : Cart.instance.quantityOf(item.itemId),
            onTap: () {
              if (pinMode) {
                _unpin(item.itemId);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.itemId)),
                );
              }
            },
            onAdd: pinMode
                ? () => _unpin(item.itemId)
                : () => setState(() => Cart.instance.addItem(item.itemId, item.name, item.price)),
            onRemove: pinMode ? () {} : () => setState(() => Cart.instance.removeOne(item.itemId)),
          );
        },
      ),
    );
  }
}