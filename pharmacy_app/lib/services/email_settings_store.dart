import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pharmacy_app/models/email_settings.dart';

class EmailSettingsStore {
  static const String _fileName = 'email_settings.json';

  static Future<EmailSettings?> load() async {
    final file = await _file();
    if (!await file.exists()) return null;

    final content = await file.readAsString();
    if (content.trim().isEmpty) return null;

    final decoded = jsonDecode(content);
    if (decoded is Map) {
      final map = decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return EmailSettings.fromMap(map);
    }

    return null;
  }

  static Future<void> save(EmailSettings settings) async {
    final file = await _file();
    final content = jsonEncode(settings.toMap());
    await file.writeAsString(content);
  }

  static Future<File> _file() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/$_fileName');
  }
}
