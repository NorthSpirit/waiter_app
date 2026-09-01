import 'package:flutter/material.dart';
import 'package:waiter_app/api/order_api.dart';
import 'package:waiter_app/models/order_status.dart';
import 'package:waiter_app/state/cart.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';
import 'package:waiter_app/widgets/components/action/touch_icon_widget.dart';
import 'package:waiter_app/widgets/components/display/standard_app_bar.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  List<OrderStatus>? _orders;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _errorMessage = null);
    try {
      final orders = await OrderApi.listMyOrders();
      setState(() => _orders = orders);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load your orders.');
    }
  }

  Future<void> _handleCancel(OrderStatus order) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Cancel this order, or cancel and copy its items to your cart to resubmit for a different table?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'keep'),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Yes, Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'copy'),
            child: const Text('Yes, Cancel & Copy'),
          ),
        ],
      ),
    );

    if (choice == null || choice == 'keep') return;

    try {
      await OrderApi.cancelOrder(order.orderId);

      if (choice == 'copy') {
        Cart.instance.clear();
        for (final item in order.items) {
          for (var i = 0; i < item.quantity; i++) {
            Cart.instance.addItem(item.itemId, item.name, item.price);
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled — items copied to your cart. Pick a table to resubmit.')),
          );
        }
      }

      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel — order may already be in preparation.')),
        );
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
            title: 'My Active Orders',
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
    if (_orders == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orders!.isEmpty) {
      return const Center(child: Text('No active orders right now.'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: EdgeInsets.all(DesignTokens.spacingMd),
        itemCount: _orders!.length,
        itemBuilder: (context, index) {
          final order = _orders![index];
          final canCancel = order.status == 'pending';

          return Container(
            margin: EdgeInsets.only(bottom: DesignTokens.spacingMd),
            padding: EdgeInsets.all(DesignTokens.spacingMd),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.tableNumber == null ? 'Take-Out' : 'Table ${order.tableNumber}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: DesignTokens.fontH3),
                    ),
                    Text(order.status.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: DesignTokens.fontCaption)),
                  ],
                ),
                Text('Order #${order.orderNumber} — ${order.createdAt}', style: TextStyle(fontSize: DesignTokens.fontCaption, color: Colors.grey.shade600)),
                const SizedBox(height: DesignTokens.spacingSm),
                for (final item in order.items)
                  Text('${item.quantity}x ${item.name}', style: const TextStyle(fontSize: DesignTokens.fontBody)),
                if (order.notes.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.spacingXs),
                  Text('Note: ${order.notes}', style: TextStyle(fontSize: DesignTokens.fontCaption, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                ],
                if (canCancel)
                  Padding(
                    padding: EdgeInsets.only(top: DesignTokens.spacingSm),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _handleCancel(order),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Cancel Order'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.only(top: DesignTokens.spacingXs),
                    child: Text(
                      'Already in preparation — no longer editable.',
                      style: TextStyle(fontSize: DesignTokens.fontCaption, fontStyle: FontStyle.italic, color: Colors.grey.shade500),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}