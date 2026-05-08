import 'package:flutter/material.dart';
import 'package:pharmacy_app/screens/inventory_screen.dart';
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
          ],
        ),
      ),
    );
  }
}
