class Batch {
  final int? id;
  final int medicineId;
  final String batchNumber;
  final String expiryDate;
  final int quantity;
  final double mrp;
  final double purchaseRate;
  final String? createdAt;

  const Batch({
    this.id,
    required this.medicineId,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
    required this.mrp,
    required this.purchaseRate,
    this.createdAt,
  });

  factory Batch.fromMap(Map<String, Object?> map) {
    return Batch(
      id: map['id'] as int?,
      medicineId: map['medicine_id'] as int,
      batchNumber: map['batch_number'] as String,
      expiryDate: map['expiry_date'] as String,
      quantity: (map['quantity'] as num).toInt(),
      mrp: (map['mrp'] as num).toDouble(),
      purchaseRate: (map['purchase_rate'] as num).toDouble(),
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    final map = <String, Object?>{
      'medicine_id': medicineId,
      'batch_number': batchNumber,
      'expiry_date': expiryDate,
      'quantity': quantity,
      'mrp': mrp,
      'purchase_rate': purchaseRate,
      'created_at': createdAt,
    };

    if (includeId && id != null) {
      map['id'] = id;
    }

    return map;
  }
}
