import 'package:flutter/material.dart';
import 'package:pharmacy_app/services/drive_backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  var _loading = false;
  String _statusMessage = 'Ready';

  Future<void> _backup() async {
    setState(() {
      _loading = true;
      _statusMessage = 'Backing up database to Google Drive...';
    });

    try {
      await DriveBackupService.backupDatabase();
      setState(() {
        _statusMessage = 'Backup successful!';
      });
      _showSnack('Backup completed successfully.');
    } catch (e) {
      setState(() {
        _statusMessage = 'Backup failed: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _restore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: const Text(
            'This will overwrite your current database with the latest backup from Google Drive. You MUST restart the application after this process completes. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _loading = true;
      _statusMessage = 'Downloading and restoring database from Google Drive...';
    });

    try {
      await DriveBackupService.restoreLatestBackup();
      setState(() {
        _statusMessage = 'Restore successful! Please restart the app.';
      });
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Restore Complete'),
          content: const Text('The database has been restored. Please completely close and restart the application to see the changes.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Restore failed: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
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
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Automated and manual Google Drive backup.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loading ? null : _backup,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Backup Now', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
              onPressed: _loading ? null : _restore,
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Restore Latest Backup', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
