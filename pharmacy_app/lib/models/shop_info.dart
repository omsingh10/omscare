class ShopInfo {
  const ShopInfo({
    this.id = 1,
    required this.name,
    this.address,
    this.phone,
    this.gstNo,
    this.invoicePrefix = 'INV',
    this.nextInvoiceNo = 1,
  });

  final int id;
  final String name;
  final String? address;
  final String? phone;
  final String? gstNo;
  final String invoicePrefix;
  final int nextInvoiceNo;

  factory ShopInfo.fromMap(Map<String, Object?> map) {
    final rawNext = map['next_invoice_no'];
    var nextNo = 1;
    if (rawNext is int) {
      nextNo = rawNext;
    } else if (rawNext is num) {
      nextNo = rawNext.toInt();
    } else if (rawNext != null) {
      nextNo = int.tryParse(rawNext.toString()) ?? nextNo;
    }

    final rawId = map['id'];
    var id = 1;
    if (rawId is int) {
      id = rawId;
    } else if (rawId is num) {
      id = rawId.toInt();
    }

    return ShopInfo(
      id: id,
      name: (map['name'] as String?) ?? 'Pharmacy Manager',
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      gstNo: map['gst_no'] as String?,
      invoicePrefix: (map['invoice_prefix'] as String?) ?? 'INV',
      nextInvoiceNo: nextNo,
    );
  }

  Map<String, Object?> toMap({bool includeId = true}) {
    final map = <String, Object?>{
      'name': name,
      'address': address,
      'phone': phone,
      'gst_no': gstNo,
      'invoice_prefix': invoicePrefix,
      'next_invoice_no': nextInvoiceNo,
    };

    if (includeId) {
      map['id'] = id;
    }

    return map;
  }
}
