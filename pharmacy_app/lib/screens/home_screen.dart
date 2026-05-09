import 'package:flutter/material.dart';
import 'package:pharmacy_app/screens/backup_restore_screen.dart';
import 'package:pharmacy_app/screens/customers_screen.dart';
import 'package:pharmacy_app/screens/email_settings_screen.dart';
import 'package:pharmacy_app/screens/inventory_screen.dart';
import 'package:pharmacy_app/screens/pos_screen.dart';
import 'package:pharmacy_app/screens/sales_report_screen.dart';
import 'package:pharmacy_app/screens/shop_settings_screen.dart';
import 'package:pharmacy_app/screens/stock_in_screen.dart';
import '../database/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.runDbCheck = true});

  final bool runDbCheck;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.runDbCheck) {
      _checkDb();
    }
  }

  void _checkDb() async {
    final db = await DatabaseHelper.database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    print('Tables: $tables');
    await DatabaseHelper.seedSampleMedicines();
    await DatabaseHelper.seedSampleBatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pharmacy Manager')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('App is running. Database ready.'),
            const SizedBox(height: 16),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const InventoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Inventory'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PosScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.point_of_sale_outlined),
                label: const Text('POS'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CustomersScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.people_outline),
                label: const Text('Customers'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const StockInScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Stock In'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SalesReportScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart_outlined),
                label: const Text('Sales Report'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ShopSettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.store_outlined),
                label: const Text('Shop Settings'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EmailSettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.email_outlined),
                label: const Text('Email Settings'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BackupRestoreScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_sync_outlined),
                label: const Text('Backup & Restore'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
