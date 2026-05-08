class SalesSummary {
  const SalesSummary({
    required this.period,
    required this.total,
    required this.count,
  });

  final String period;
  final double total;
  final int count;

  factory SalesSummary.fromMap(Map<String, Object?> map) {
    final rawTotal = map['total'];
    var total = 0.0;
    if (rawTotal is num) {
      total = rawTotal.toDouble();
    } else if (rawTotal != null) {
      total = double.tryParse(rawTotal.toString()) ?? 0.0;
    }

    final rawCount = map['count'];
    var count = 0;
    if (rawCount is int) {
      count = rawCount;
    } else if (rawCount is num) {
      count = rawCount.toInt();
    } else if (rawCount != null) {
      count = int.tryParse(rawCount.toString()) ?? 0;
    }

    return SalesSummary(
      period: (map['period'] as String?) ?? '',
      total: total,
      count: count,
    );
  }
}
