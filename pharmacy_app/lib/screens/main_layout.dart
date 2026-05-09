import 'package:flutter/material.dart';
import 'package:pharmacy_app/database/database_helper.dart';
import 'package:pharmacy_app/screens/alerts_screen.dart';
import 'package:pharmacy_app/screens/backup_restore_screen.dart';
import 'package:pharmacy_app/screens/customers_screen.dart';
import 'package:pharmacy_app/screens/email_settings_screen.dart';
import 'package:pharmacy_app/screens/inventory_screen.dart';
import 'package:pharmacy_app/screens/pos_screen.dart';
import 'package:pharmacy_app/screens/sales_report_screen.dart';
import 'package:pharmacy_app/screens/shop_settings_screen.dart';
import 'package:pharmacy_app/screens/stock_in_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _isExtended = true;
  bool _dbReady = false;

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    await DatabaseHelper.seedSampleMedicines();
    await DatabaseHelper.seedSampleBatches();
    if (mounted) {
      setState(() => _dbReady = true);
    }
  }

  final List<Widget> _screens = [
    const AlertsScreen(),
    const PosScreen(),
    const InventoryScreen(),
    const CustomersScreen(),
    const StockInScreen(),
    const SalesReportScreen(),
    const _SettingsHub(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_dbReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: _isExtended,
            selectedIndex: _selectedIndex,
            minExtendedWidth: 200,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => setState(() => _isExtended = !_isExtended),
                  ),
                  if (_isExtended)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Pharmacy App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Alerts Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale),
                label: Text('POS Billing'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory),
                label: Text('Inventory'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Customers'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_box_outlined),
                selectedIcon: Icon(Icons.add_box),
                label: Text('Stock In'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Sales Report'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

class _SettingsHub extends StatelessWidget {
  const _SettingsHub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Shop Settings'),
            subtitle: const Text('Update shop name, address, GST, and phone'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShopSettingsScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email Settings'),
            subtitle: const Text('Configure Gmail SMTP for sending invoices'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmailSettingsScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Google Drive automated database backups'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
