// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_app/models/medicine.dart';

void main() {
  test('Medicine model creates successfully', () {
    const medicine = Medicine(
      name: 'Test Med',
      barcode: '12345',
      defaultMrp: 10.0,
      gstRate: 5.0,
    );

    expect(medicine.name, 'Test Med');
    expect(medicine.barcode, '12345');
    expect(medicine.defaultMrp, 10.0);
  });
}
