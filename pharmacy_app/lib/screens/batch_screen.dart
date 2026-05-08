import 'package:flutter/material.dart';
import 'package:pharmacy_app/database/database_helper.dart';
import 'package:pharmacy_app/models/batch.dart';
import 'package:pharmacy_app/models/medicine.dart';

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key, required this.medicine});

  final Medicine medicine;

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  var _loading = true;
  List<Batch> _batches = [];

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() => _loading = true);
    final batches = await DatabaseHelper.getBatchesForMedicine(
      widget.medicine.id!,
    );
    setState(() {
      _batches = batches;
      _loading = false;
    });
  }

  Future<void> _openBatchDialog({Batch? existing}) async {
    final result = await showDialog<Batch>(
      context: context,
      builder: (context) => _BatchDialog(
        medicine: widget.medicine,
        existing: existing,
      ),
    );

    if (result == null) return;

    if (existing == null) {
      await DatabaseHelper.insertBatch(result);
    } else {
      await DatabaseHelper.updateBatch(result);
    }

    await _loadBatches();
  }

  Future<void> _confirmDelete(Batch batch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete batch'),
        content: Text('Delete batch ${batch.batchNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await DatabaseHelper.deleteBatch(batch.id!);
    await _loadBatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Batches - ${widget.medicine.name}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBatchDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add batch'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _batches.isEmpty
              ? const Center(child: Text('No batches yet.'))
              : RefreshIndicator(
                  onRefresh: _loadBatches,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _batches.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final batch = _batches[index];
                      return ListTile(
                        title: Text('Batch ${batch.batchNumber}'),
                        subtitle: Text(
                          'Expiry: ${batch.expiryDate} • Qty: ${batch.quantity} • MRP: ${batch.mrp}',
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _openBatchDialog(
                                existing: batch,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: batch.id == null
                                  ? null
                                  : () => _confirmDelete(batch),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _BatchDialog extends StatefulWidget {
  const _BatchDialog({required this.medicine, this.existing});

  final Medicine medicine;
  final Batch? existing;

  @override
  State<_BatchDialog> createState() => _BatchDialogState();
}

class _BatchDialogState extends State<_BatchDialog> {
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
    _quantityController = TextEditingController(
      text: existing?.quantity.toString() ?? '',
    );
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
      title: Text(widget.existing == null ? 'Add batch' : 'Edit batch'),
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
                  decoration: const InputDecoration(labelText: 'Quantity'),
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
            final batch = Batch(
              id: widget.existing?.id,
              medicineId: widget.medicine.id!,
              batchNumber: _batchNumberController.text.trim(),
              expiryDate: _expiryController.text.trim(),
              quantity: int.parse(_quantityController.text.trim()),
              mrp: double.parse(_mrpController.text.trim()),
              purchaseRate: double.parse(_purchaseRateController.text.trim()),
            );
            Navigator.pop(context, batch);
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
