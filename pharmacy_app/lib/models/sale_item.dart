class SaleItem {
  final int? id;
  final int saleId;
  final int medicineId;
  final int batchId;
  final int quantity;
  final double rate;
  final double? gstPercentage;
  final double total;

  const SaleItem({
    this.id,
    required this.saleId,
    required this.medicineId,
    required this.batchId,
    required this.quantity,
    required this.rate,
    this.gstPercentage,
    required this.total,
  });

  factory SaleItem.fromMap(Map<String, Object?> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int,
      medicineId: map['medicine_id'] as int,
      batchId: map['batch_id'] as int,
      quantity: (map['quantity'] as num).toInt(),
      rate: (map['rate'] as num).toDouble(),
      gstPercentage: (map['gst_percentage'] as num?)?.toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    final map = <String, Object?>{
      'sale_id': saleId,
      'medicine_id': medicineId,
      'batch_id': batchId,
      'quantity': quantity,
      'rate': rate,
      'gst_percentage': gstPercentage,
      'total': total,
    };

    if (includeId && id != null) {
      map['id'] = id;
    }

    return map;
  }
}
