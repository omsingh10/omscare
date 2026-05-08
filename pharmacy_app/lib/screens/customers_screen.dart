import 'package:flutter/material.dart';
import 'package:pharmacy_app/database/database_helper.dart';
import 'package:pharmacy_app/models/customer.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  var _loading = true;
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loading = true);
    final customers = await DatabaseHelper.getCustomers();
    setState(() {
      _customers = customers;
      _loading = false;
    });
  }

  Future<void> _openCustomerDialog({Customer? existing}) async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (context) => _CustomerDialog(existing: existing),
    );

    if (result == null) return;

    if (existing == null) {
      await DatabaseHelper.insertCustomer(result);
    } else {
      await DatabaseHelper.updateCustomer(result);
    }

    await _loadCustomers();
  }

  Future<void> _confirmDelete(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete customer'),
        content: Text('Delete ${customer.name}? This cannot be undone.'),
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

    await DatabaseHelper.deleteCustomer(customer.id!);
    await _loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCustomerDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add customer'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _customers.isEmpty
              ? const Center(child: Text('No customers yet.'))
              : RefreshIndicator(
                  onRefresh: _loadCustomers,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _customers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final customer = _customers[index];
                      final subtitle = _buildSubtitle(customer);
                      return ListTile(
                        title: Text(customer.name),
                        subtitle: subtitle.isEmpty ? null : Text(subtitle),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _openCustomerDialog(
                                existing: customer,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: customer.id == null
                                  ? null
                                  : () => _confirmDelete(customer),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _buildSubtitle(Customer customer) {
    final parts = <String>[];
    if (customer.phone != null && customer.phone!.isNotEmpty) {
      parts.add(customer.phone!);
    }
    if (customer.email != null && customer.email!.isNotEmpty) {
      parts.add(customer.email!);
    }
    return parts.join(' • ');
  }
}

class _CustomerDialog extends StatefulWidget {
  const _CustomerDialog({this.existing});

  final Customer? existing;

  @override
  State<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<_CustomerDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _phoneController = TextEditingController(text: existing?.phone ?? '');
    _emailController = TextEditingController(text: existing?.email ?? '');
    _addressController = TextEditingController(
      text: existing?.address ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add customer' : 'Edit customer'),
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
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
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
            final customer = Customer(
              id: widget.existing?.id,
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
              email: _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim(),
              address: _addressController.text.trim().isEmpty
                  ? null
                  : _addressController.text.trim(),
            );
            Navigator.pop(context, customer);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
