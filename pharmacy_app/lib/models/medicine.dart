class Medicine {
  final int? id;
  final String name;
  final String? genericName;
  final String? category;
  final String? manufacturer;
  final String? hsnCode;
  final double gstRate;
  final String? packSize;
  final double? defaultMrp;
  final String? barcode;
  final String? createdAt;
  final String? updatedAt;

  const Medicine({
    this.id,
    required this.name,
    this.genericName,
    this.category,
    this.manufacturer,
    this.hsnCode,
    this.gstRate = 12.0,
    this.packSize,
    this.defaultMrp,
    this.barcode,
    this.createdAt,
    this.updatedAt,
  });

  factory Medicine.fromMap(Map<String, Object?> map) {
    return Medicine(
      id: map['id'] as int?,
      name: map['name'] as String,
      genericName: map['generic_name'] as String?,
      category: map['category'] as String?,
      manufacturer: map['manufacturer'] as String?,
      hsnCode: map['hsn_code'] as String?,
      gstRate: (map['gst_rate'] as num?)?.toDouble() ?? 12.0,
      packSize: map['pack_size'] as String?,
      defaultMrp: (map['default_mrp'] as num?)?.toDouble(),
      barcode: map['barcode'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    final map = <String, Object?>{
      'name': name,
      'generic_name': genericName,
      'category': category,
      'manufacturer': manufacturer,
      'hsn_code': hsnCode,
      'gst_rate': gstRate,
      'pack_size': packSize,
      'default_mrp': defaultMrp,
      'barcode': barcode,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };

    if (includeId && id != null) {
      map['id'] = id;
    }

    return map;
  }
}
