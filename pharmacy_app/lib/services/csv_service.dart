import 'package:csv/csv.dart';
import 'package:pharmacy_app/models/medicine.dart';

class CsvService {
  static const List<String> medicineHeaders = [
    'name',
    'generic_name',
    'category',
    'manufacturer',
    'hsn_code',
    'gst_rate',
    'pack_size',
    'default_mrp',
    'barcode',
  ];

  static List<Medicine> parseMedicinesCsv(String csvContent) {
    if (csvContent.trim().isEmpty) return [];

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(csvContent);

    if (rows.isEmpty) return [];

    var startIndex = 0;
    final headerIndex = <String, int>{};

    if (_looksLikeHeader(rows.first)) {
      headerIndex.addAll(_buildHeaderIndex(rows.first));
      startIndex = 1;
    }

    final medicines = <Medicine>[];

    for (var i = startIndex; i < rows.length; i++) {
      final row = rows[i];
      if (_rowIsEmpty(row)) continue;

      final name = _readField(
        row,
        headerIndex,
        keys: ['name', 'medicine_name'],
        fallbackIndex: 0,
      );

      if (name == null || name.trim().isEmpty) continue;

      final genericName = _readField(
        row,
        headerIndex,
        keys: ['generic_name', 'generic'],
        fallbackIndex: 1,
      );
      final category = _readField(
        row,
        headerIndex,
        keys: ['category'],
        fallbackIndex: 2,
      );
      final manufacturer = _readField(
        row,
        headerIndex,
        keys: ['manufacturer', 'company'],
        fallbackIndex: 3,
      );
      final hsnCode = _readField(
        row,
        headerIndex,
        keys: ['hsn_code', 'hsn'],
        fallbackIndex: 4,
      );
      final gstRate = _parseDouble(
            _readField(
              row,
              headerIndex,
              keys: ['gst_rate', 'gst', 'gst_percent'],
              fallbackIndex: 5,
            ),
          ) ??
          12.0;
      final packSize = _readField(
        row,
        headerIndex,
        keys: ['pack_size', 'pack'],
        fallbackIndex: 6,
      );
      final defaultMrp = _parseDouble(
        _readField(
          row,
          headerIndex,
          keys: ['default_mrp', 'mrp'],
          fallbackIndex: 7,
        ),
      );
      final barcode = _readField(
        row,
        headerIndex,
        keys: ['barcode'],
        fallbackIndex: 8,
      );

      medicines.add(
        Medicine(
          name: name.trim(),
          genericName: genericName?.trim(),
          category: category?.trim(),
          manufacturer: manufacturer?.trim(),
          hsnCode: hsnCode?.trim(),
          gstRate: gstRate,
          packSize: packSize?.trim(),
          defaultMrp: defaultMrp,
          barcode: barcode?.trim(),
        ),
      );
    }

    return medicines;
  }

  static String buildMedicinesCsv(List<Medicine> medicines) {
    final rows = <List<String>>[medicineHeaders];

    for (final medicine in medicines) {
      rows.add([
        medicine.name,
        medicine.genericName ?? '',
        medicine.category ?? '',
        medicine.manufacturer ?? '',
        medicine.hsnCode ?? '',
        medicine.gstRate.toString(),
        medicine.packSize ?? '',
        medicine.defaultMrp?.toString() ?? '',
        medicine.barcode ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  static bool _looksLikeHeader(List<dynamic> row) {
    final normalized = row.map(_normalizeHeader).toSet();
    return normalized.contains('name') || normalized.contains('medicine_name');
  }

  static Map<String, int> _buildHeaderIndex(List<dynamic> headerRow) {
    final index = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final key = _normalizeHeader(headerRow[i]);
      if (key.isEmpty) continue;
      index[key] = i;
    }
    return index;
  }

  static String _normalizeHeader(dynamic value) {
    final raw = value?.toString() ?? '';
    var normalized = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    normalized = normalized.replaceAll('-', '_');
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
    normalized = normalized.replaceAll(RegExp(r'_+'), '_');
    normalized = normalized.replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized;
  }

  static String? _readField(
    List<dynamic> row,
    Map<String, int> headerIndex, {
    required List<String> keys,
    required int fallbackIndex,
  }) {
    int? index;
    for (final key in keys) {
      if (headerIndex.containsKey(key)) {
        index = headerIndex[key];
        break;
      }
    }

    if (index != null && index < row.length) {
      return row[index]?.toString();
    }

    if (fallbackIndex < row.length) {
      return row[fallbackIndex]?.toString();
    }

    return null;
  }

  static bool _rowIsEmpty(List<dynamic> row) {
    return row.every((cell) => cell == null || cell.toString().trim().isEmpty);
  }

  static double? _parseDouble(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }
}
