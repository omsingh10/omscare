import 'package:flutter/material.dart';
import 'package:pharmacy_app/database/database_helper.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  var _loading = true;
  List<Map<String, dynamic>> _lowStock = [];
  List<Map<String, dynamic>> _expiring = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      DatabaseHelper.getLowStockMedicines(threshold: 10),
      DatabaseHelper.getExpiringBatches(days: 90),
    ]);
    setState(() {
      _lowStock = results[0];
      _expiring = results[1];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alerts Dashboard'),
          bottom: TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Low Stock'),
                    if (_lowStock.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Badge(
                        label: Text('${_lowStock.length}'),
                        backgroundColor: Colors.orange,
                      ),
                    ]
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Expiring Soon'),
                    if (_expiring.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Badge(
                        label: Text('${_expiring.length}'),
                        backgroundColor: Colors.red,
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _LowStockList(items: _lowStock),
                  _ExpiringList(items: _expiring),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _loadAlerts,
          tooltip: 'Refresh Alerts',
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

class _LowStockList extends StatelessWidget {
  const _LowStockList({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('All stock levels are optimal!'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        final qty = item['total_quantity'] as num;
        final color = qty <= 0 ? Colors.red : Colors.orange;

        return ListTile(
          leading: Icon(Icons.warning_amber_rounded, color: color, size: 32),
          title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Barcode: ${item['barcode']}'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color),
            ),
            child: Text(
              'Stock: $qty',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}

class _ExpiringList extends StatelessWidget {
  const _ExpiringList({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No batches expiring within the next 90 days.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        final expiryDateStr = item['expiry_date'] as String;
        final expiryDate = DateTime.tryParse(expiryDateStr) ?? DateTime.now();
        final daysLeft = expiryDate.difference(DateTime.now()).inDays;
        
        Color color;
        String status;
        if (daysLeft < 0) {
          color = Colors.red;
          status = 'Expired';
        } else if (daysLeft <= 30) {
          color = Colors.deepOrange;
          status = 'Expires in $daysLeft days';
        } else {
          color = Colors.orange;
          status = 'Expires in $daysLeft days';
        }

        return ListTile(
          leading: Icon(Icons.date_range, color: color, size: 32),
          title: Text(item['medicine_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Batch: ${item['batch_number']} • Qty: ${item['quantity']}'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color),
            ),
            child: Text(
              status,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
