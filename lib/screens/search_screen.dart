import 'dart:async';
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
import 'package:waiter_app/widgets/components/inputs/text_field_input.dart';
import 'package:waiter_app/widgets/components/menuitemtile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  //Nullable timer to grant waiter some grace, between key presses
  Timer? _debounce;

  List<MenuItem>? _results;
  Set<int> _pinnedItemIds = {};
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPinnedIds();
  }

  Future<void> _loadPinnedIds() async {
    try {
      final quickItems = await QuickItemsApi.list();
      if (mounted) {
        setState(() => _pinnedItemIds = quickItems.map((q) => q.itemId).toSet());
      }
    } catch (e) {
      // Pin Mode still works even if this fails to load initially.
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  //Does stuff it the input field value had changed, basically you typed something else
  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = null;
        _errorMessage = null;
      });
      return;
    }

    //Waits until typing pauses for 350ms, then searches. Avoids a server call on every keystroke or slow fingers situation.
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    setState(() {
      //Tells that is searching, so screen wouldn't feel weird while search is going, just adds the spinner.
      _isSearching = true;
      _errorMessage = null;
    });
    try {
      //Sends the request with the search, based on name (in internship version, for now only by name exists)
      final results = await MenuApi.search(query);
      //Sets the results
      if (mounted) setState(() => _results = results);
    } catch (e) {
      //Search failed for whatever reason, could be server derp could be some other problems.
      if (mounted) setState(() => _errorMessage = 'Search failed.');
    } finally {
      //Search is done for now.
      if (mounted) setState(() => _isSearching = false);
    }
  }

  //Same pinning logic as in the menu screen.
  Future<void> _togglePin(MenuItem item) async {
    //Checks if the list of pinned items has that item’s ID
    final isPinned = _pinnedItemIds.contains(item.id);
    try {
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
        //Once again, limits how many items there are, no more than 15 items.
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
            title: 'Search',
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
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(DesignTokens.spacingMd),
                child: TextFieldInput(
                  controller: _controller,
                  label: '',
                  hintText: 'Search items...',
                  onChanged: _onChanged,
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_results == null) {
      return const Center(child: Text('Start typing to search.'));
    }
    if (_results!.isEmpty) {
      return const Center(child: Text('No matching items.'));
    }

    final pinMode = Session.instance.pinMode;

    return AnimatedBuilder(
      animation: Cart.instance,
      builder: (context, _) {
        return ListView.builder(
          itemCount: _results!.length,
          itemBuilder: (context, index) {
            final item = _results![index];
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
                    : (item.isAvailable ? () => Cart.instance.addItem(item.id, item.name, item.price) : () {}),
                onRemove: pinMode ? () => _togglePin(item) : () => Cart.instance.removeOne(item.id),
              ),
            );
          },
        );
      },
    );
  }
}