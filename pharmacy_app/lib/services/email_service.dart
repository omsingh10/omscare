import 'dart:io';
import 'dart:typed_data';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pharmacy_app/models/email_settings.dart';

class EmailService {
  static Future<void> sendInvoice({
    required EmailSettings settings,
    required String recipientEmail,
    required String subject,
    required String body,
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    final smtpServer = gmail(settings.smtpEmail, settings.appPassword);

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    final message = Message()
      ..from = Address(settings.smtpEmail, settings.fromName)
      ..recipients.add(recipientEmail)
      ..subject = subject
      ..text = body
      ..attachments.add(FileAttachment(file));

    try {
      await send(message, smtpServer);
    } finally {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
