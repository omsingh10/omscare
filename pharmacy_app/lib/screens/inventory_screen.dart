import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pharmacy_app/database/database_helper.dart';
import 'package:pharmacy_app/models/medicine.dart';
import 'package:pharmacy_app/screens/batch_screen.dart';
import 'package:pharmacy_app/services/csv_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  var _loading = true;
  var _processing = false;
  List<Medicine> _medicines = [];

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
      _loading = false;
    });
  }

  Future<void> _openMedicineDialog({Medicine? existing}) async {
    final result = await showDialog<Medicine>(
      context: context,
      builder: (context) => _MedicineDialog(existing: existing),
    );

    if (result == null) return;

    if (existing == null) {
      await DatabaseHelper.insertMedicine(result);
    } else {
      await DatabaseHelper.updateMedicine(result);
    }

    await _loadMedicines();
  }

  Future<void> _confirmDelete(Medicine medicine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete medicine'),
        content: Text('Delete ${medicine.name}? This cannot be undone.'),
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

    await DatabaseHelper.deleteMedicine(medicine.id!);
    await _loadMedicines();
  }

  Future<void> _openBatches(Medicine medicine) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BatchScreen(medicine: medicine),
      ),
    );
    await _loadMedicines();
  }

  Future<void> _importCsv() async {
    if (_processing) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _processing = true);

    try {
      final content = await File(path).readAsString();
      final medicines = CsvService.parseMedicinesCsv(content);

      if (medicines.isEmpty) {
        _showSnack('No valid rows found in CSV.');
        return;
      }

      final inserted = await DatabaseHelper.insertMedicines(
        medicines,
        ignoreConflicts: true,
      );

      await _loadMedicines();
      _showSnack('Imported $inserted of ${medicines.length} medicines.');
    } catch (error) {
      _showSnack('Import failed: $error');
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _exportCsv() async {
    if (_processing) return;

    final path = await FilePicker.saveFile(
      dialogTitle: 'Save medicines CSV',
      fileName: 'medicines.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (path == null) return;

    setState(() => _processing = true);

    try {
      final medicines = await DatabaseHelper.getMedicines();
      final csv = CsvService.buildMedicinesCsv(medicines);
      await File(path).writeAsString(csv);
      _showSnack('Exported ${medicines.length} medicines.');
    } catch (error) {
      _showSnack('Export failed: $error');
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _seedSamples() async {
    if (_processing) return;

    setState(() => _processing = true);

    try {
      final insertedMedicines =
          await DatabaseHelper.seedSampleMedicines(force: true);
      final insertedBatches =
          await DatabaseHelper.seedSampleBatches(force: true);

      await _loadMedicines();
      _showSnack(
        'Added $insertedMedicines medicines and $insertedBatches batches.',
      );
    } catch (error) {
      _showSnack('Seed failed: $error');
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
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            tooltip: 'Seed samples',
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: _processing ? null : _seedSamples,
          ),
          IconButton(
            tooltip: 'Import CSV',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: _processing ? null : _importCsv,
          ),
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _processing ? null : _exportCsv,
          ),
          if (_processing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMedicineDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add medicine'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _medicines.isEmpty
              ? const Center(child: Text('No medicines yet.'))
              : RefreshIndicator(
                  onRefresh: _loadMedicines,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _medicines.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final medicine = _medicines[index];
                      final subtitle = _buildSubtitle(medicine);
                      return ListTile(
                        title: Text(medicine.name),
                        subtitle: subtitle.isEmpty ? null : Text(subtitle),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Batches',
                              icon: const Icon(Icons.inventory_2_outlined),
                              onPressed: () => _openBatches(medicine),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _openMedicineDialog(
                                existing: medicine,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: medicine.id == null
                                  ? null
                                  : () => _confirmDelete(medicine),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _buildSubtitle(Medicine medicine) {
    final parts = <String>[];
    if (medicine.genericName != null && medicine.genericName!.isNotEmpty) {
      parts.add(medicine.genericName!);
    }
    if (medicine.manufacturer != null && medicine.manufacturer!.isNotEmpty) {
      parts.add(medicine.manufacturer!);
    }
    if (medicine.barcode != null && medicine.barcode!.isNotEmpty) {
      parts.add('Barcode: ${medicine.barcode}');
    }
    return parts.join(' • ');
  }
}

class _MedicineDialog extends StatefulWidget {
  const _MedicineDialog({this.existing});

  final Medicine? existing;

  @override
  State<_MedicineDialog> createState() => _MedicineDialogState();
}

class _MedicineDialogState extends State<_MedicineDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _genericController;
  late final TextEditingController _categoryController;
  late final TextEditingController _manufacturerController;
  late final TextEditingController _hsnController;
  late final TextEditingController _gstController;
  late final TextEditingController _packController;
  late final TextEditingController _mrpController;
  late final TextEditingController _barcodeController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _genericController = TextEditingController(
      text: existing?.genericName ?? '',
    );
    _categoryController = TextEditingController(
      text: existing?.category ?? '',
    );
    _manufacturerController = TextEditingController(
      text: existing?.manufacturer ?? '',
    );
    _hsnController = TextEditingController(text: existing?.hsnCode ?? '');
    _gstController = TextEditingController(
      text: (existing?.gstRate ?? 12.0).toString(),
    );
    _packController = TextEditingController(text: existing?.packSize ?? '');
    _mrpController = TextEditingController(
      text: existing?.defaultMrp?.toString() ?? '',
    );
    _barcodeController = TextEditingController(text: existing?.barcode ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genericController.dispose();
    _categoryController.dispose();
    _manufacturerController.dispose();
    _hsnController.dispose();
    _gstController.dispose();
    _packController.dispose();
    _mrpController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add medicine' : 'Edit medicine'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _genericController,
                  decoration: const InputDecoration(labelText: 'Generic name'),
                ),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextFormField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(labelText: 'Manufacturer'),
                ),
                TextFormField(
                  controller: _hsnController,
                  decoration: const InputDecoration(labelText: 'HSN code'),
                ),
                TextFormField(
                  controller: _gstController,
                  decoration: const InputDecoration(labelText: 'GST rate'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                TextFormField(
                  controller: _packController,
                  decoration: const InputDecoration(labelText: 'Pack size'),
                ),
                TextFormField(
                  controller: _mrpController,
                  decoration: const InputDecoration(labelText: 'Default MRP'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(labelText: 'Barcode'),
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
            final gstRate = double.tryParse(_gstController.text.trim()) ?? 12.0;
            final defaultMrp = double.tryParse(_mrpController.text.trim());
            final medicine = Medicine(
              id: widget.existing?.id,
              name: _nameController.text.trim(),
              genericName: _genericController.text.trim().isEmpty
                  ? null
                  : _genericController.text.trim(),
              category: _categoryController.text.trim().isEmpty
                  ? null
                  : _categoryController.text.trim(),
              manufacturer: _manufacturerController.text.trim().isEmpty
                  ? null
                  : _manufacturerController.text.trim(),
              hsnCode: _hsnController.text.trim().isEmpty
                  ? null
                  : _hsnController.text.trim(),
              gstRate: gstRate,
              packSize: _packController.text.trim().isEmpty
                  ? null
                  : _packController.text.trim(),
              defaultMrp: defaultMrp,
              barcode: _barcodeController.text.trim().isEmpty
                  ? null
                  : _barcodeController.text.trim(),
            );
            Navigator.pop(context, medicine);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
