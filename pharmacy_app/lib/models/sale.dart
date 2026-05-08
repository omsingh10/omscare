class Sale {
  final int? id;
  final int? customerId;
  final String invoiceNo;
  final double totalAmount;
  final double discount;
  final double netAmount;
  final String? paymentMode;
  final String? saleDate;

  const Sale({
    this.id,
    this.customerId,
    required this.invoiceNo,
    required this.totalAmount,
    this.discount = 0,
    required this.netAmount,
    this.paymentMode,
    this.saleDate,
  });

  factory Sale.fromMap(Map<String, Object?> map) {
    return Sale(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int?,
      invoiceNo: map['invoice_no'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      netAmount: (map['net_amount'] as num).toDouble(),
      paymentMode: map['payment_mode'] as String?,
      saleDate: map['sale_date'] as String?,
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    final map = <String, Object?>{
      'customer_id': customerId,
      'invoice_no': invoiceNo,
      'total_amount': totalAmount,
      'discount': discount,
      'net_amount': netAmount,
      'payment_mode': paymentMode,
      'sale_date': saleDate,
    };

    if (includeId && id != null) {
      map['id'] = id;
    }

    return map;
  }
}
