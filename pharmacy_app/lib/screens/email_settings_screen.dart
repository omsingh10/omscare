import 'package:flutter/material.dart';
import 'package:pharmacy_app/models/email_settings.dart';
import 'package:pharmacy_app/services/email_settings_store.dart';

class EmailSettingsScreen extends StatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  State<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends State<EmailSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fromNameController = TextEditingController();

  var _loading = true;
  var _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fromNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await EmailSettingsStore.load();
    if (settings != null) {
      _emailController.text = settings.smtpEmail;
      _passwordController.text = settings.appPassword;
      _fromNameController.text = settings.fromName;
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = EmailSettings(
      smtpEmail: _emailController.text.trim(),
      appPassword: _passwordController.text.trim(),
      fromName: _fromNameController.text.trim(),
    );

    await EmailSettingsStore.save(settings);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email settings saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const Text(
                      'Use a Gmail App Password (not your normal password).',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Gmail address',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Gmail app password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'App password is required';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _fromNameController,
                      decoration: const InputDecoration(
                        labelText: 'Sender name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Sender name is required';
                        }
                        return null;
                      },
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
