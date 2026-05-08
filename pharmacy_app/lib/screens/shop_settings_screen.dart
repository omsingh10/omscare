import 'package:flutter/material.dart';
import 'package:pharmacy_app/database/database_helper.dart';
import 'package:pharmacy_app/models/shop_info.dart';

class ShopSettingsScreen extends StatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  State<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends State<ShopSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstController = TextEditingController();
  final _prefixController = TextEditingController();

  var _loading = true;
  var _nextInvoiceNo = 1;

  @override
  void initState() {
    super.initState();
    _loadShopInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    _prefixController.dispose();
    super.dispose();
  }

  Future<void> _loadShopInfo() async {
    final info = await DatabaseHelper.getShopInfo();
    _nameController.text = info.name;
    _addressController.text = info.address ?? '';
    _phoneController.text = info.phone ?? '';
    _gstController.text = info.gstNo ?? '';
    _prefixController.text = info.invoicePrefix;
    _nextInvoiceNo = info.nextInvoiceNo;

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final info = ShopInfo(
      name: _nameController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      gstNo: _gstController.text.trim().isEmpty
          ? null
          : _gstController.text.trim(),
      invoicePrefix: _prefixController.text.trim().isEmpty
          ? 'INV'
          : _prefixController.text.trim(),
      nextInvoiceNo: _nextInvoiceNo,
    );

    await DatabaseHelper.saveShopInfo(info);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shop details saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Shop name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Shop name is required';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      maxLines: 2,
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    TextFormField(
                      controller: _gstController,
                      decoration: const InputDecoration(labelText: 'GSTIN'),
                    ),
                    TextFormField(
                      controller: _prefixController,
                      decoration: const InputDecoration(
                        labelText: 'Invoice prefix',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
