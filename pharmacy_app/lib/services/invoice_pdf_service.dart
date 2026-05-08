import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoiceData {
  const InvoiceData({
    required this.invoiceNo,
    required this.invoiceDate,
    required this.shopName,
    this.shopAddress,
    this.shopPhone,
    this.shopGst,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.taxableAmount,
    required this.taxLines,
    required this.taxTotal,
    required this.netAmount,
  });

  final String invoiceNo;
  final DateTime invoiceDate;
  final String shopName;
  final String? shopAddress;
  final String? shopPhone;
  final String? shopGst;
  final String? customerName;
  final String? customerPhone;
  final List<InvoiceLine> items;
  final double subtotal;
  final double discount;
  final double taxableAmount;
  final List<TaxLine> taxLines;
  final double taxTotal;
  final double netAmount;
}

class InvoiceLine {
  const InvoiceLine({
    required this.name,
    required this.batchNumber,
    required this.quantity,
    required this.rate,
    required this.gstRate,
    required this.total,
  });

  final String name;
  final String batchNumber;
  final int quantity;
  final double rate;
  final double gstRate;
  final double total;
}

class TaxLine {
  const TaxLine({required this.rate, required this.amount});

  final double rate;
  final double amount;
}

class InvoicePdfService {
  static Future<Uint8List> buildPdf(InvoiceData data) async {
    final doc = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            _buildHeader(data, dateFormat),
            pw.SizedBox(height: 16),
            _buildItemsTable(data),
            pw.SizedBox(height: 12),
            _buildTotals(data),
            pw.SizedBox(height: 24),
            pw.Text('Thank you for your purchase.'),
          ];
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildHeader(InvoiceData data, DateFormat dateFormat) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              data.shopName,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (data.shopAddress != null && data.shopAddress!.isNotEmpty)
              pw.Text(data.shopAddress!),
            if (data.shopPhone != null && data.shopPhone!.isNotEmpty)
              pw.Text('Phone: ${data.shopPhone}'),
            if (data.shopGst != null && data.shopGst!.isNotEmpty)
              pw.Text('GSTIN: ${data.shopGst}'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Invoice',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text('No: ${data.invoiceNo}'),
            pw.Text('Date: ${dateFormat.format(data.invoiceDate)}'),
            pw.SizedBox(height: 8),
            pw.Text(
              'Customer: ${data.customerName ?? 'Walk-in'}',
              textAlign: pw.TextAlign.right,
            ),
            if (data.customerPhone != null && data.customerPhone!.isNotEmpty)
              pw.Text('Phone: ${data.customerPhone}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(InvoiceData data) {
    final headers = <String>[
      '#',
      'Item',
      'Batch',
      'Qty',
      'Rate',
      'GST%',
      'Total',
    ];

    final rows = <List<String>>[];
    for (var i = 0; i < data.items.length; i++) {
      final item = data.items[i];
      rows.add([
        '${i + 1}',
        item.name,
        item.batchNumber,
        item.quantity.toString(),
        _money(item.rate),
        item.gstRate.toStringAsFixed(1),
        _money(item.total),
      ]);
    }

    return pw.Table.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {
        0: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
      },
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        3: const pw.FixedColumnWidth(32),
        4: const pw.FixedColumnWidth(56),
        5: const pw.FixedColumnWidth(40),
        6: const pw.FixedColumnWidth(64),
      },
      cellHeight: 24,
    );
  }

  static pw.Widget _buildTotals(InvoiceData data) {
    final rows = <pw.Widget>[];

    rows.add(_totalRow('Subtotal', data.subtotal));
    rows.add(_totalRow('Discount', data.discount));
    rows.add(_totalRow('Taxable amount', data.taxableAmount));

    for (final tax in data.taxLines) {
      rows.add(
        _totalRow(
          'GST ${tax.rate.toStringAsFixed(1)}%',
          tax.amount,
        ),
      );
    }

    rows.add(_totalRow('GST total', data.taxTotal));
    rows.add(pw.Divider());
    rows.add(
      _totalRow(
        'Net amount',
        data.netAmount,
        isBold: true,
      ),
    );

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 220,
        child: pw.Column(children: rows),
      ),
    );
  }

  static pw.Widget _totalRow(
    String label,
    double value, {
    bool isBold = false,
  }) {
    final style = pw.TextStyle(
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(_money(value), style: style),
        ],
      ),
    );
  }

  static String _money(double value) => value.toStringAsFixed(2);
}
