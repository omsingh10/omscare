import 'package:flutter/material.dart';
import 'package:pharmacy_app/database/database_helper.dart';
import 'package:pharmacy_app/models/batch.dart';
import 'package:pharmacy_app/models/customer.dart';
import 'package:pharmacy_app/models/email_settings.dart';
import 'package:pharmacy_app/models/medicine.dart';
import 'package:pharmacy_app/models/sale.dart';
import 'package:pharmacy_app/models/sale_item.dart';
import 'package:pharmacy_app/models/shop_info.dart';
import 'package:pharmacy_app/screens/email_settings_screen.dart';
import 'package:pharmacy_app/services/email_service.dart';
import 'package:pharmacy_app/services/email_settings_store.dart';
import 'package:pharmacy_app/services/invoice_pdf_service.dart';
import 'package:printing/printing.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _barcodeController = TextEditingController();
  final _discountController = TextEditingController(text: '0');

  var _loading = true;
  var _saving = false;
  var _processing = false;

  List<Medicine> _allMedicines = [];
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  String _paymentMode = 'Cash';
  ShopInfo? _shopInfo;

  final List<_CartItem> _cart = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      DatabaseHelper.getMedicines(),
      DatabaseHelper.getCustomers(),
      DatabaseHelper.getShopInfo(),
    ]);
    setState(() {
      _allMedicines = results[0] as List<Medicine>;
      _customers = results[1] as List<Customer>;
      _shopInfo = results[2] as ShopInfo;
      _loading = false;
    });
  }

  Future<void> _handleBarcode(String raw) async {
    final parsed = _parseBarcodeInput(raw);
    if (parsed == null) return;

    final medicine = await DatabaseHelper.getMedicineByBarcode(parsed.barcode);
    if (medicine == null) {
      _showSnack('No medicine found for barcode ${parsed.barcode}');
      return;
    }

    await _addMedicineToCart(medicine, quantity: parsed.quantity);
  }

  Future<void> _addMedicineToCart(
    Medicine medicine, {
    int quantity = 1,
  }) async {
    if (quantity <= 0) return;
    if (medicine.id == null) {
      _showSnack('Medicine must be saved before adding to cart.');
      return;
    }

    final batches = await DatabaseHelper.getBatchesForMedicine(medicine.id!);
    final available = batches.where((batch) => batch.quantity > 0).toList();

    if (available.isEmpty) {
      _showSnack('No stock available for ${medicine.name}.');
      return;
    }

    final batch = available.first;
    final existingIndex = _cart.indexWhere(
      (item) => item.batch.id == batch.id,
    );

    if (existingIndex != -1) {
      final item = _cart[existingIndex];
      if (item.quantity + quantity > batch.quantity) {
        _showSnack('Not enough stock for batch ${batch.batchNumber}.');
        return;
      }
      setState(() => item.quantity += quantity);
      return;
    }

    setState(() {
      _cart.add(
        _CartItem(
          medicine: medicine,
          batch: batch,
          quantity: quantity,
          rate: batch.mrp,
        ),
      );
    });
  }

  Future<void> _openMedicinePicker() async {
    if (_processing) return;

    final selected = await showDialog<Medicine>(
      context: context,
      builder: (context) {
        var query = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final filtered = _filterMedicines(query);
            return AlertDialog(
              title: const Text('Add medicine'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search medicine',
                      ),
                      onChanged: (value) {
                        setState(() => query = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 320,
                      child: filtered.isEmpty
                          ? const Center(child: Text('No matches'))
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final medicine = filtered[index];
                                return ListTile(
                                  title: Text(medicine.name),
                                  subtitle: _buildMedicineSubtitle(medicine),
                                  onTap: () => Navigator.pop(
                                    context,
                                    medicine,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected == null) return;
    await _addMedicineToCart(selected);
  }

  _ParsedBarcode? _parseBarcodeInput(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final match = RegExp(r'^(.*?)(?:\s*[xX\*]\s*)(\d+)$').firstMatch(
      trimmed,
    );

    if (match != null) {
      final code = match.group(1)?.trim();
      final qtyRaw = match.group(2);
      final qty = int.tryParse(qtyRaw ?? '') ?? 1;
      if (code == null || code.isEmpty) return null;
      return _ParsedBarcode(barcode: code, quantity: qty);
    }

    return _ParsedBarcode(barcode: trimmed, quantity: 1);
  }

  List<Medicine> _filterMedicines(String query) {
    if (query.trim().isEmpty) return _allMedicines;
    final lower = query.trim().toLowerCase();
    return _allMedicines
        .where((medicine) =>
            medicine.name.toLowerCase().contains(lower) ||
            (medicine.genericName ?? '').toLowerCase().contains(lower))
        .toList();
  }

  Widget? _buildMedicineSubtitle(Medicine medicine) {
    final parts = <String>[];
    if (medicine.genericName != null && medicine.genericName!.isNotEmpty) {
      parts.add(medicine.genericName!);
    }
    if (medicine.manufacturer != null && medicine.manufacturer!.isNotEmpty) {
      parts.add(medicine.manufacturer!);
    }
    if (parts.isEmpty) return null;
    return Text(parts.join(' • '));
  }

  Future<void> _editQuantity(_CartItem item) async {
    final controller = TextEditingController(text: item.quantity.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update quantity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Quantity (max ${item.batch.quantity})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value <= 0) {
                Navigator.pop(context);
                return;
              }
              Navigator.pop(context, value);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null) return;
    if (result > item.batch.quantity) {
      _showSnack('Only ${item.batch.quantity} in stock.');
      return;
    }

    setState(() => item.quantity = result);
  }

  Future<void> _previewCurrentInvoice() async {
    if (_cart.isEmpty) {
      _showSnack('Cart is empty.');
      return;
    }

    final data = _buildInvoiceData(
      invoiceNo: 'PREVIEW',
      items: _cloneCart(_cart),
    );

    await _previewInvoice(data);
  }

  Future<void> _previewInvoice(InvoiceData data) async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) => InvoicePdfService.buildPdf(data),
      );
    } catch (error) {
      _showSnack('Invoice preview failed: $error');
    }
  }

  Future<void> _completeSale() async {
    if (_saving) return;
    if (_cart.isEmpty) {
      _showSnack('Cart is empty.');
      return;
    }

    setState(() => _saving = true);

    try {
      final invoiceNo = await DatabaseHelper.getNextInvoiceNo();
      final cartSnapshot = _cloneCart(_cart);
      final subtotal = _subtotal;
      final discount = _discount;
      final netAmount = _netAmount;

      final sale = Sale(
        customerId: _selectedCustomer?.id,
        invoiceNo: invoiceNo,
        totalAmount: subtotal,
        discount: discount,
        netAmount: netAmount,
        paymentMode: _paymentMode,
      );

      final items = _cart.map((item) {
        return SaleItem(
          saleId: 0,
          medicineId: item.medicine.id!,
          batchId: item.batch.id!,
          quantity: item.quantity,
          rate: item.rate,
          gstPercentage: item.medicine.gstRate,
          total: item.total,
        );
      }).toList();

      await DatabaseHelper.createSaleWithItems(sale: sale, items: items);

      final invoiceData = _buildInvoiceData(
        invoiceNo: invoiceNo,
        items: cartSnapshot,
      );

      setState(() {
        _cart.clear();
        _discountController.text = '0';
      });

      _showSnack('Sale saved. Invoice $invoiceNo');
      final shouldPrint = await _promptPrint();
      if (shouldPrint == true) {
        await _previewInvoice(invoiceData);
      }

      final recipient = await _promptEmailAddress(
        initial: _selectedCustomer?.email,
      );
      if (recipient != null) {
        await _sendInvoiceEmail(invoiceData, recipient);
      }
    } catch (error) {
      _showSnack('Save failed: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<bool?> _promptPrint() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Print invoice'),
        content: const Text('Would you like to print the invoice now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Print'),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptEmailAddress({String? initial}) async {
    final controller = TextEditingController(text: initial ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email invoice'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Recipient email',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty || !value.contains('@')) {
                Navigator.pop(context);
                return;
              }
              Navigator.pop(context, value);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _sendInvoiceEmail(InvoiceData data, String recipient) async {
    final settings = await EmailSettingsStore.load();
    if (!_isEmailSettingsValid(settings)) {
      final open = await _promptEmailSettings();
      if (open == true && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const EmailSettingsScreen(),
          ),
        );
      }
      return;
    }

    try {
      final pdfBytes = await InvoicePdfService.buildPdf(data);
      await EmailService.sendInvoice(
        settings: settings!,
        recipientEmail: recipient,
        subject: 'Invoice ${data.invoiceNo}',
        body: 'Please find attached invoice ${data.invoiceNo}.',
        pdfBytes: pdfBytes,
        fileName: 'invoice_${data.invoiceNo}.pdf',
      );
      _showSnack('Invoice emailed to $recipient');
    } catch (error) {
      _showSnack('Email failed: $error');
    }
  }

  bool _isEmailSettingsValid(EmailSettings? settings) {
    if (settings == null) return false;
    if (settings.smtpEmail.trim().isEmpty) return false;
    if (settings.appPassword.trim().isEmpty) return false;
    return true;
  }

  Future<bool?> _promptEmailSettings() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email not configured'),
        content: const Text(
          'Set Gmail and app password in Email Settings to send invoices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }

  double get _subtotal {
    return _subtotalFor(_cart);
  }

  double get _taxTotal {
    return _taxByRate.values.fold(0.0, (sum, value) => sum + value);
  }

  double get _taxableAmount {
    final value = _netAmount - _taxTotal;
    return value < 0 ? 0 : value;
  }

  double get _discount {
    return double.tryParse(_discountController.text.trim()) ?? 0;
  }

  double get _netAmount {
    final value = _subtotal - _discount;
    return value < 0 ? 0 : value;
  }

  Map<double, double> get _taxByRate {
    return _taxByRateFor(_cart, _discount);
  }

  double _subtotalFor(List<_CartItem> items) {
    return items.fold(0, (sum, item) => sum + item.total);
  }

  Map<double, double> _taxByRateFor(
    List<_CartItem> items,
    double discount,
  ) {
    final subtotal = _subtotalFor(items);
    if (subtotal <= 0) return {};

    final ratio = discount <= 0 ? 0 : (discount / subtotal).clamp(0, 1);
    final taxMap = <double, double>{};

    for (final item in items) {
      final rate = item.medicine.gstRate;
      if (rate <= 0) continue;

      final lineTotal = item.total;
      final lineNet = lineTotal - (lineTotal * ratio);
      final base = lineNet / (1 + (rate / 100));
      final tax = lineNet - base;
      taxMap[rate] = (taxMap[rate] ?? 0) + tax;
    }

    return taxMap;
  }

  InvoiceData _buildInvoiceData({
    required String invoiceNo,
    required List<_CartItem> items,
  }) {
    final discount = double.tryParse(_discountController.text.trim()) ?? 0;
    final subtotal = _subtotalFor(items);
    final netAmount =
        (subtotal - discount).clamp(0, double.infinity).toDouble();
    final taxByRate = _taxByRateFor(items, discount);
    final taxTotal = taxByRate.values.fold(
      0.0,
      (sum, value) => sum + value,
    );
    final taxable = (netAmount - taxTotal).clamp(0, double.infinity).toDouble();

    final invoiceItems = items
        .map(
          (item) => InvoiceLine(
            name: item.medicine.name,
            batchNumber: item.batch.batchNumber,
            quantity: item.quantity,
            rate: item.rate,
            gstRate: item.medicine.gstRate,
            total: item.total,
          ),
        )
        .toList();

    final taxLines = taxByRate.entries
        .map((entry) => TaxLine(rate: entry.key, amount: entry.value))
        .toList()
      ..sort((a, b) => a.rate.compareTo(b.rate));

    final shopInfo = _shopInfo ?? const ShopInfo(name: 'Pharmacy Manager');

    return InvoiceData(
      invoiceNo: invoiceNo,
      invoiceDate: DateTime.now(),
      shopName: shopInfo.name,
      shopAddress: shopInfo.address,
      shopPhone: shopInfo.phone,
      shopGst: shopInfo.gstNo,
      customerName: _selectedCustomer?.name,
      customerPhone: _selectedCustomer?.phone,
      items: invoiceItems,
      subtotal: subtotal,
      discount: discount,
      taxableAmount: taxable,
      taxLines: taxLines,
      taxTotal: taxTotal,
      netAmount: netAmount,
    );
  }

  List<_CartItem> _cloneCart(List<_CartItem> items) {
    return items
        .map(
          (item) => _CartItem(
            medicine: item.medicine,
            batch: item.batch,
            quantity: item.quantity,
            rate: item.rate,
          ),
        )
        .toList();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Point of Sale')),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Scan barcode',
                      hintText: 'Example: 8901234567890*2',
                      prefixIcon: Icon(Icons.qr_code_scanner),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) async {
                      await _handleBarcode(value);
                      _barcodeController.clear();
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openMedicinePicker,
                        icon: const Icon(Icons.search),
                        label: const Text('Add by search'),
                      ),
                      OutlinedButton.icon(
                        onPressed:
                            _cart.isEmpty ? null : _previewCurrentInvoice,
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Preview invoice'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _cart.isEmpty
                            ? null
                            : () => setState(() => _cart.clear()),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear cart'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(child: Text('Cart is empty.'))
                        : ListView.separated(
                            itemCount: _cart.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _cart[index];
                              return ListTile(
                                title: Text(item.medicine.name),
                                subtitle: Text(
                                  'Batch ${item.batch.batchNumber} • Qty ${item.quantity} • Rate ${item.rate.toStringAsFixed(2)}',
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit quantity',
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _editQuantity(item),
                                    ),
                                    IconButton(
                                      tooltip: 'Remove',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => setState(
                                        () => _cart.removeAt(index),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, color: Colors.grey.shade300),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<Customer?>(
                    value: _selectedCustomer,
                    decoration: const InputDecoration(labelText: 'Customer'),
                    items: [
                      const DropdownMenuItem<Customer?>(
                        value: null,
                        child: Text('Walk-in'),
                      ),
                      ..._customers.map(
                        (customer) => DropdownMenuItem<Customer?>(
                          value: customer,
                          child: Text(customer.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCustomer = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _paymentMode,
                    decoration:
                        const InputDecoration(labelText: 'Payment mode'),
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Card', child: Text('Card')),
                      DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                      DropdownMenuItem(value: 'Credit', child: Text('Credit')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _paymentMode = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Discount'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SummaryRow(
                            label: 'Subtotal',
                            value: _subtotal,
                          ),
                          _SummaryRow(
                            label: 'Discount',
                            value: _discount,
                          ),
                          _SummaryRow(
                            label: 'Taxable amount',
                            value: _taxableAmount,
                          ),
                          ..._buildTaxBreakdown(),
                          const Divider(),
                          _SummaryRow(
                            label: 'Net amount',
                            value: _netAmount,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _completeSale,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(_saving ? 'Saving...' : 'Complete sale'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItem {
  _CartItem({
    required this.medicine,
    required this.batch,
    required this.quantity,
    required this.rate,
  });

  final Medicine medicine;
  final Batch batch;
  int quantity;
  final double rate;

  double get total => quantity * rate;
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value.toStringAsFixed(2)),
        ],
      ),
    );
  }
}

extension on _PosScreenState {
  List<Widget> _buildTaxBreakdown() {
    final entries = _taxByRate.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) {
      return [
        _SummaryRow(label: 'GST', value: 0),
      ];
    }

    return [
      for (final entry in entries)
        _SummaryRow(
          label: 'GST ${entry.key.toStringAsFixed(1)}%',
          value: entry.value,
        ),
      _SummaryRow(label: 'GST total', value: _taxTotal),
    ];
  }
}

class _ParsedBarcode {
  const _ParsedBarcode({required this.barcode, required this.quantity});

  final String barcode;
  final int quantity;
}
