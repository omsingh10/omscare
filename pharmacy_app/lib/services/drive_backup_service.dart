import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DriveBackupService {
  static const _scopes = [drive.DriveApi.driveFileScope];
  static const _folderName = 'Pharmacy_Backups';

  static Future<AuthClient> _getClient() async {
    final jsonString = await rootBundle.loadString('assets/service_account.json');
    final credentials = ServiceAccountCredentials.fromJson(jsonDecode(jsonString));
    return await clientViaServiceAccount(credentials, _scopes);
  }

  static Future<String> _getOrCreateFolder(drive.DriveApi api) async {
    final query = "mimeType='application/vnd.google-apps.folder' and name='$_folderName' and trashed=false";
    final fileList = await api.files.list(q: query, spaces: 'drive');
    
    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files!.first.id!;
    }

    final folder = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final created = await api.files.create(folder);
    return created.id!;
  }

  static Future<String> get _dbPath async {
    final path = await getDatabasesPath();
    return join(path, 'pharmacy.db');
  }

  static Future<void> backupDatabase() async {
    final client = await _getClient();
    try {
      final api = drive.DriveApi(client);
      final folderId = await _getOrCreateFolder(api);

      final dbPath = await _dbPath;
      final file = File(dbPath);
      
      if (!await file.exists()) {
        throw Exception('Database file not found at $dbPath');
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final driveFile = drive.File()
        ..name = 'pharmacy_backup_$timestamp.db'
        ..parents = [folderId];

      final media = drive.Media(file.openRead(), file.lengthSync());
      await api.files.create(driveFile, uploadMedia: media);
    } finally {
      client.close();
    }
  }

  static Future<void> restoreLatestBackup() async {
    final client = await _getClient();
    try {
      final api = drive.DriveApi(client);
      final folderId = await _getOrCreateFolder(api);

      final query = "'$folderId' in parents and trashed=false";
      final fileList = await api.files.list(
        q: query,
        orderBy: 'createdTime desc',
        spaces: 'drive',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        throw Exception('No backups found in Google Drive folder: $_folderName');
      }

      final latestFile = fileList.files!.first;
      final fileId = latestFile.id!;

      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final dbPath = await _dbPath;
      final file = File(dbPath);

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      await file.writeAsBytes(bytes);
    } finally {
      client.close();
    }
  }
}
