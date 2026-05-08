import 'package:flutter/material.dart';
import 'package:pharmacy_app/database/database_helper.dart';
import 'package:pharmacy_app/models/sales_summary.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  var _loading = true;
  List<SalesSummary> _daily = [];
  List<SalesSummary> _monthly = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      DatabaseHelper.getDailySalesSummary(),
      DatabaseHelper.getMonthlySalesSummary(),
    ]);
    setState(() {
      _daily = results[0] as List<SalesSummary>;
      _monthly = results[1] as List<SalesSummary>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sales Report'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Daily'),
              Tab(text: 'Monthly'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _ReportList(entries: _daily, emptyText: 'No daily sales.'),
                  _ReportList(
                    entries: _monthly,
                    emptyText: 'No monthly sales.',
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _loadReports,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ),
    );
  }
}

class _ReportList extends StatelessWidget {
  const _ReportList({required this.entries, required this.emptyText});

  final List<SalesSummary> entries;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(child: Text(emptyText));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          title: Text(entry.period),
          subtitle: Text('${entry.count} sales'),
          trailing: Text(entry.total.toStringAsFixed(2)),
        );
      },
    );
  }
}
