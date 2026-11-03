import 'package:flutter/material.dart';
import 'package:waiter_app/api/table_api.dart';
import 'package:waiter_app/models/waiter_table.dart';
import 'package:waiter_app/state/cart.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';
import 'package:waiter_app/widgets/components/action/touch_icon_widget.dart';
import 'package:waiter_app/widgets/components/display/info_list_tile.dart';
import 'package:waiter_app/widgets/components/display/standard_app_bar.dart';

class TablePickerScreen extends StatefulWidget {
  const TablePickerScreen({super.key});

  @override
  State<TablePickerScreen> createState() => _TablePickerScreenState();
}

class _TablePickerScreenState extends State<TablePickerScreen> {
  List<WaiterTable>? _tables;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Upon loading up, calls the server to receive full table list and sets the state with them
  Future<void> _load() async {
    try {
      final tables = await TableApi.listTables();
      setState(() => _tables = tables);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load tables.');
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
              TouchIconWidget(icon: Icons.arrow_back, onTap: () => Navigator.pop(context, false)),
            ],
            title: 'Select Table',
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
    if (_tables == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Take-out is always available, even if tables in the larger system aren't even created.
        // The takeout is slightly divided from the proper tables for convenience
        InfoListTile(
          title: 'Take-Out (no table)',
          subtitle: 'For orders with no table assigned',
          arrowType: TrailingArrowType.chevron,
          onTap: () {
            Cart.instance.setTable(null, null);
            Navigator.pop(context, true);
          },
        ),
        const Divider(),
        Expanded(
          child: _tables!.isEmpty
              ? const Center(child: Text('No tables found.'))
              : ListView.builder(
                  itemCount: _tables!.length,
                  itemBuilder: (context, index) {
                    final table = _tables![index];
                    return InfoListTile(
                      title: 'Table ${table.number}',
                      subtitle: table.hasActiveOrder
                          // Shows the capacity of the table, which is for quality of life
                          // And also shows, if the table is free - as in, if it does have an order for this restaurant
                          // No if it has a customer in general, since payments are split per restaurant.
                          ? 'Capacity ${table.capacity} — ${table.status} — you have an open order here'
                          : 'Capacity ${table.capacity} — ${table.status}',
                      arrowType: TrailingArrowType.chevron,
                      onTap: () {
                        // Clicking the table sets state and returns
                        Cart.instance.setTable(table.id, table.number);
                        Navigator.pop(context, true);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}