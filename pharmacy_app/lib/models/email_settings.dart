class EmailSettings {
  const EmailSettings({
    required this.smtpEmail,
    required this.appPassword,
    required this.fromName,
  });

  final String smtpEmail;
  final String appPassword;
  final String fromName;

  factory EmailSettings.fromMap(Map<String, Object?> map) {
    return EmailSettings(
      smtpEmail: (map['smtp_email'] as String?) ?? '',
      appPassword: (map['app_password'] as String?) ?? '',
      fromName: (map['from_name'] as String?) ?? 'Pharmacy Manager',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'smtp_email': smtpEmail,
      'app_password': appPassword,
      'from_name': fromName,
    };
  }
}
