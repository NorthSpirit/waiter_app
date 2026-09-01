import 'package:flutter/material.dart';
import 'package:waiter_app/api/menu_api.dart';
import 'package:waiter_app/models/item_detail.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';
import 'package:waiter_app/widgets/components/action/touch_icon_widget.dart';
import 'package:waiter_app/widgets/components/display/standard_app_bar.dart';

class ItemDetailScreen extends StatefulWidget {
  final int itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  ItemDetail? _item;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final item = await MenuApi.getItemDetail(widget.itemId);
      setState(() => _item = item);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load item details.');
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
            title: _item?.name ?? 'Item Details',
          ),
          body: _buildBody(theme),
        );
      },
    );
  }

  Widget _buildBody(dynamic theme) {
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_item == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final item = _item!;

    return ListView(
      padding: EdgeInsets.all(DesignTokens.spacingMd),
      children: [
        if (item.imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            child: Image.network(item.imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
        const SizedBox(height: DesignTokens.spacingSm),
        Text(
          item.formattedPrice,
          style: TextStyle(color: theme.brandDark, fontSize: DesignTokens.fontH1, fontWeight: FontWeight.w700),
        ),
        if (!item.isAvailable)
          Padding(
            padding: EdgeInsets.only(top: DesignTokens.spacingXs),
            child: Text('Currently unavailable', style: TextStyle(color: theme.alert)),
          ),
        if (item.description.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.spacingSm),
          Text(item.description, style: TextStyle(color: theme.content, fontSize: DesignTokens.fontBody)),
        ],
        const SizedBox(height: DesignTokens.spacingMd),
        Text('Ingredients', style: TextStyle(color: theme.content, fontSize: DesignTokens.fontH2, fontWeight: FontWeight.w700)),
        const SizedBox(height: DesignTokens.spacingXs),
        if (item.ingredients.isEmpty)
          Text('No ingredients listed.', style: TextStyle(color: theme.content.withValues(alpha: DesignTokens.opacitySoft)))
        else
          ...item.ingredients.map((ing) => Padding(
                padding: EdgeInsets.only(bottom: DesignTokens.spacingXs),
                child: Text(
                  ing.measurement.isNotEmpty ? '${ing.name} (${ing.amount} ${ing.measurement})' : ing.name,
                  style: TextStyle(color: theme.content),
                ),
              )),
        const SizedBox(height: DesignTokens.spacingMd),
        Text('Allergens', style: TextStyle(color: theme.content, fontSize: DesignTokens.fontH2, fontWeight: FontWeight.w700)),
        const SizedBox(height: DesignTokens.spacingXs),
        if (item.allergens.isEmpty)
          Text('No known allergens.', style: TextStyle(color: theme.content.withValues(alpha: DesignTokens.opacitySoft)))
        else
          Wrap(
            spacing: DesignTokens.spacingXs,
            runSpacing: DesignTokens.spacingXs,
            children: item.allergens
                .map((a) => Chip(label: Text(a), backgroundColor: theme.brandLight.withValues(alpha: 0.3)))
                .toList(),
          ),
      ],
    );
  }
}