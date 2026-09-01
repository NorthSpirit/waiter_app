import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:waiter_app/api/api_client.dart';
import 'package:waiter_app/api/order_api.dart';
import 'package:waiter_app/screens/table_picker_screen.dart';
import 'package:waiter_app/state/cart.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';
import 'package:waiter_app/widgets/components/action/misc_button_widget.dart';
import 'package:waiter_app/widgets/components/action/touch_icon_widget.dart';
import 'package:waiter_app/widgets/components/display/standard_app_bar.dart';

class OrderReviewScreen extends StatefulWidget {
  const OrderReviewScreen({super.key});

  @override
  State<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  bool _isSubmitting = false;
  String? _errorMessage;

  final String _idempotencyKey = const Uuid().v4();

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await OrderApi.submit(_idempotencyKey);
      Cart.instance.clear();
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to submit — will retry safely if you try again.';
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
              TouchIconWidget(icon: Icons.arrow_back, onTap: () => Navigator.pop(context, false)),
            ],
            title: Cart.instance.tableId == null ? 'Take-Out Order' : 'Table ${Cart.instance.tableNumber}',
            rightActions: [
              TouchIconWidget(
                icon: Icons.delete_outline,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Order?'),
                      content: const Text('This will remove all items and the selected table/take-out from this order. This cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    Cart.instance.clear();
                    if (context.mounted) Navigator.pop(context, false);
                  }
                },
              ),
              TouchIconWidget(
                icon: Icons.swap_horiz,
                onTap: () async {
                  if (Cart.instance.items.isNotEmpty) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Change Table?'),
                        content: const Text('Your current cart items will be kept, but assigned to the new table.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Change Table')),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                  }

                  if (!context.mounted) return;
                  final picked = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const TablePickerScreen()),
                  );
                  if (picked == true && context.mounted) {
                    setState(() {});
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(DesignTokens.spacingMd),
                  children: [
                    for (final item in Cart.instance.items)
                      Padding(
                        padding: EdgeInsets.only(bottom: DesignTokens.spacingSm),
                        child: Row(
                          children: [
                            Expanded(child: Text('${item.quantity}x ${item.name}', style: TextStyle(color: theme.content))),
                            Text('€${item.lineTotal.toStringAsFixed(2)}', style: TextStyle(color: theme.brandDark, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    if (Cart.instance.isEmpty) const Text('Cart is empty.'),
                  ],
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.all(DesignTokens.spacingSm),
                  child: Text(_errorMessage!, style: TextStyle(color: theme.alert)),
                ),
              Padding(
                padding: EdgeInsets.all(DesignTokens.spacingMd),
                child: Row(
                  children: [
                    Text('Total: €${Cart.instance.total.toStringAsFixed(2)}', style: TextStyle(color: theme.content, fontSize: DesignTokens.fontH2, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    MiscButtonWidget(
                      label: 'Submit Order',
                      isLoading: _isSubmitting,
                      onPressed: Cart.instance.isEmpty ? null : _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}