import 'package:flutter/material.dart';
import 'package:pharmacy_app/database/database_helper.dart';
import 'package:pharmacy_app/models/batch.dart';
import 'package:pharmacy_app/models/medicine.dart';

class StockInScreen extends StatefulWidget {
  const StockInScreen({super.key});

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
  var _loading = true;
  var _processing = false;
  List<Medicine> _medicines = [];
  Medicine? _selectedMedicine;
  List<Batch> _batches = [];

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    setState(() => _loading = true);
    final medicines = await DatabaseHelper.getMedicines();
    setState(() {
      _medicines = medicines;
      _selectedMedicine = medicines.isNotEmpty ? medicines.first : null;
      _loading = false;
    });

    await _loadBatches();
  }

  Future<void> _loadBatches() async {
    final medicine = _selectedMedicine;
    if (medicine == null || medicine.id == null) {
      setState(() => _batches = []);
      return;
    }

    final batches = await DatabaseHelper.getBatchesForMedicine(medicine.id!);
    if (mounted) {
      setState(() => _batches = batches);
    }
  }

  Future<void> _openStockDialog({Batch? existing}) async {
    final medicine = _selectedMedicine;
    if (medicine == null || medicine.id == null) return;

    final result = await showDialog<_StockEntry>(
      context: context,
      builder: (context) => _StockDialog(
        medicine: medicine,
        existing: existing,
      ),
    );

    if (result == null) return;

    setState(() => _processing = true);

    try {
      await DatabaseHelper.addStock(
        medicineId: medicine.id!,
        batchNumber: result.batchNumber,
        expiryDate: result.expiryDate,
        quantity: result.quantity,
        mrp: result.mrp,
        purchaseRate: result.purchaseRate,
      );
      await _loadBatches();
      _showSnack('Stock updated.');
    } catch (error) {
      _showSnack('Stock update failed: $error');
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock In')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<Medicine>(
                    value: _selectedMedicine,
                    decoration: const InputDecoration(labelText: 'Medicine'),
                    items: _medicines
                        .map(
                          (medicine) => DropdownMenuItem<Medicine>(
                            value: medicine,
                            child: Text(medicine.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      setState(() => _selectedMedicine = value);
                      await _loadBatches();
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            _processing ? null : () => _openStockDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('New batch'),
                      ),
                      const SizedBox(width: 12),
                      if (_processing)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _batches.isEmpty
                        ? const Center(child: Text('No batches yet.'))
                        : ListView.separated(
                            itemCount: _batches.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final batch = _batches[index];
                              return ListTile(
                                title: Text('Batch ${batch.batchNumber}'),
                                subtitle: Text(
                                  'Expiry: ${batch.expiryDate} • Qty: ${batch.quantity} • MRP: ${batch.mrp}',
                                ),
                                trailing: IconButton(
                                  tooltip: 'Add stock',
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: _processing
                                      ? null
                                      : () => _openStockDialog(
                                            existing: batch,
                                          ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StockDialog extends StatefulWidget {
  const _StockDialog({required this.medicine, this.existing});

  final Medicine medicine;
  final Batch? existing;

  @override
  State<_StockDialog> createState() => _StockDialogState();
}

class _StockDialogState extends State<_StockDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _batchNumberController;
  late final TextEditingController _expiryController;
  late final TextEditingController _quantityController;
  late final TextEditingController _mrpController;
  late final TextEditingController _purchaseRateController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _batchNumberController = TextEditingController(
      text: existing?.batchNumber ?? '',
    );
    _expiryController = TextEditingController(
      text: existing?.expiryDate ?? '',
    );
    _quantityController = TextEditingController(text: '1');
    _mrpController = TextEditingController(
      text: existing?.mrp.toString() ?? '',
    );
    _purchaseRateController = TextEditingController(
      text: existing?.purchaseRate.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _batchNumberController.dispose();
    _expiryController.dispose();
    _quantityController.dispose();
    _mrpController.dispose();
    _purchaseRateController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final initial = DateTime.tryParse(_expiryController.text.trim());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (picked == null) return;
    _expiryController.text = _formatDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New batch' : 'Add stock'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _batchNumberController,
                  decoration: const InputDecoration(labelText: 'Batch number'),
                  readOnly: widget.existing != null,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Batch number is required';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _expiryController,
                  decoration: const InputDecoration(
                    labelText: 'Expiry date',
                    hintText: 'YYYY-MM-DD',
                  ),
                  readOnly: true,
                  onTap: _pickExpiryDate,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Expiry date is required';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _quantityController,
                  decoration:
                      const InputDecoration(labelText: 'Quantity to add'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final qty = int.tryParse(value ?? '');
                    if (qty == null || qty <= 0) {
                      return 'Enter a valid quantity';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _mrpController,
                  decoration: const InputDecoration(labelText: 'MRP'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final mrp = double.tryParse(value ?? '');
                    if (mrp == null || mrp <= 0) {
                      return 'Enter a valid MRP';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _purchaseRateController,
                  decoration: const InputDecoration(labelText: 'Purchase rate'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final rate = double.tryParse(value ?? '');
                    if (rate == null || rate <= 0) {
                      return 'Enter a valid purchase rate';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;

            final entry = _StockEntry(
              batchNumber: _batchNumberController.text.trim(),
              expiryDate: _expiryController.text.trim(),
              quantity: int.parse(_quantityController.text.trim()),
              mrp: double.parse(_mrpController.text.trim()),
              purchaseRate: double.parse(_purchaseRateController.text.trim()),
            );

            Navigator.pop(context, entry);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _StockEntry {
  const _StockEntry({
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
    required this.mrp,
    required this.purchaseRate,
  });

  final String batchNumber;
  final String expiryDate;
  final int quantity;
  final double mrp;
  final double purchaseRate;
}
