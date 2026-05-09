import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pharmacy_app/models/batch.dart' as app_models;
import 'package:pharmacy_app/models/customer.dart';
import 'package:pharmacy_app/models/medicine.dart';
import 'package:pharmacy_app/models/sales_summary.dart';
import 'package:pharmacy_app/models/sale.dart';
import 'package:pharmacy_app/models/sale_item.dart';
import 'package:pharmacy_app/models/shop_info.dart';
import 'tables.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pharmacy.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(Tables.medicines);
        await db.execute(Tables.batches);
        await db.execute(Tables.customers);
        await db.execute(Tables.sales);
        await db.execute(Tables.saleItems);
        await db.execute(Tables.purchases);
        await db.execute(Tables.purchaseItems);
        await db.execute(Tables.shopInfo);
        // Insert default shop info row
        await db.insert('shop_info', {
          'id': 1,
          'invoice_prefix': 'INV',
          'next_invoice_no': 1,
        });
      },
    );
  }

  static Future<int> insertMedicine(
    Medicine medicine, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.abort,
  }) async {
    final db = await database;
    return db.insert(
      'medicines',
      medicine.toMap(),
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  static Future<int> insertMedicines(
    List<Medicine> medicines, {
    bool ignoreConflicts = false,
  }) async {
    if (medicines.isEmpty) return 0;

    final db = await database;
    var inserted = 0;
    final conflictAlgorithm =
        ignoreConflicts ? ConflictAlgorithm.ignore : ConflictAlgorithm.abort;

    await db.transaction((txn) async {
      for (final medicine in medicines) {
        final id = await txn.insert(
          'medicines',
          medicine.toMap(),
          conflictAlgorithm: conflictAlgorithm,
        );
        if (id > 0) {
          inserted += 1;
        }
      }
    });

    return inserted;
  }

  static Future<int> seedSampleMedicines({bool force = false}) async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS count FROM medicines');
    var count = 0;

    if (rows.isNotEmpty && rows.first.isNotEmpty) {
      final rawCount = rows.first.values.first;
      if (rawCount is int) {
        count = rawCount;
      } else if (rawCount is num) {
        count = rawCount.toInt();
      } else if (rawCount != null) {
        count = int.tryParse(rawCount.toString()) ?? 0;
      }
    }

    if (count > 0 && !force) return 0;

    return insertMedicines(
      _sampleMedicines(),
      ignoreConflicts: true,
    );
  }

  static Future<int> seedSampleBatches({bool force = false}) async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS count FROM batches');
    var count = 0;

    if (rows.isNotEmpty && rows.first.isNotEmpty) {
      final rawCount = rows.first.values.first;
      if (rawCount is int) {
        count = rawCount;
      } else if (rawCount is num) {
        count = rawCount.toInt();
      } else if (rawCount != null) {
        count = int.tryParse(rawCount.toString()) ?? 0;
      }
    }

    if (count > 0 && !force) return 0;

    var inserted = 0;
    final samples = _sampleBatches();

    await db.transaction((txn) async {
      for (final sample in samples) {
        final barcode = sample['barcode'] as String;
        final medicineRows = await txn.query(
          'medicines',
          columns: ['id'],
          where: 'barcode = ?',
          whereArgs: [barcode],
          limit: 1,
        );

        if (medicineRows.isEmpty) continue;

        final medicineId = (medicineRows.first['id'] as num).toInt();
        final batchMap = {
          'medicine_id': medicineId,
          'batch_number': sample['batch_number'],
          'expiry_date': sample['expiry_date'],
          'quantity': sample['quantity'],
          'mrp': sample['mrp'],
          'purchase_rate': sample['purchase_rate'],
        };

        final id = await txn.insert('batches', batchMap);
        if (id > 0) {
          inserted += 1;
        }
      }
    });

    return inserted;
  }

  static Future<List<Medicine>> getMedicines() async {
    final db = await database;
    final rows = await db.query('medicines', orderBy: 'name COLLATE NOCASE');
    return rows.map(Medicine.fromMap).toList();
  }

  static Future<Medicine?> getMedicineById(int id) async {
    final db = await database;
    final rows = await db.query(
      'medicines',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Medicine.fromMap(rows.first);
  }

  static Future<Medicine?> getMedicineByBarcode(String barcode) async {
    final db = await database;
    final rows = await db.query(
      'medicines',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Medicine.fromMap(rows.first);
  }

  static Future<int> updateMedicine(Medicine medicine) async {
    if (medicine.id == null) {
      throw ArgumentError('Medicine id is required for update.');
    }

    final db = await database;
    final data = medicine.toMap();
    data['updated_at'] = DateTime.now().toIso8601String();
    return db.update(
      'medicines',
      data,
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
  }

  static Future<int> deleteMedicine(int id) async {
    final db = await database;
    return db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> insertBatch(app_models.Batch batch) async {
    final db = await database;
    return db.insert('batches', batch.toMap());
  }

  static Future<app_models.Batch?> getBatchById(int id) async {
    final db = await database;
    final rows = await db.query(
      'batches',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return app_models.Batch.fromMap(rows.first);
  }

  static Future<List<app_models.Batch>> getBatchesForMedicine(
    int medicineId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'batches',
      where: 'medicine_id = ?',
      whereArgs: [medicineId],
      orderBy: 'expiry_date ASC',
    );
    return rows.map(app_models.Batch.fromMap).toList();
  }

  static Future<int> updateBatch(app_models.Batch batch) async {
    if (batch.id == null) {
      throw ArgumentError('Batch id is required for update.');
    }

    final db = await database;
    return db.update(
      'batches',
      batch.toMap(),
      where: 'id = ?',
      whereArgs: [batch.id],
    );
  }

  static Future<int> updateBatchQuantity(int batchId, int quantity) async {
    final db = await database;
    return db.update(
      'batches',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [batchId],
    );
  }

  static Future<int> deleteBatch(int id) async {
    final db = await database;
    return db.delete('batches', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> addStock({
    required int medicineId,
    required String batchNumber,
    required String expiryDate,
    required int quantity,
    required double mrp,
    required double purchaseRate,
  }) async {
    final db = await database;

    return db.transaction((txn) async {
      final rows = await txn.query(
        'batches',
        columns: ['id', 'quantity'],
        where: 'medicine_id = ? AND batch_number = ?',
        whereArgs: [medicineId, batchNumber],
        limit: 1,
      );

      if (rows.isEmpty) {
        return txn.insert('batches', {
          'medicine_id': medicineId,
          'batch_number': batchNumber,
          'expiry_date': expiryDate,
          'quantity': quantity,
          'mrp': mrp,
          'purchase_rate': purchaseRate,
        });
      }

      final batchId = (rows.first['id'] as num).toInt();
      await txn.rawUpdate(
        'UPDATE batches SET quantity = quantity + ?, mrp = ?, purchase_rate = ?, expiry_date = ? WHERE id = ?',
        [quantity, mrp, purchaseRate, expiryDate, batchId],
      );
      return batchId;
    });
  }

  static Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return db.insert('customers', customer.toMap());
  }

  static Future<List<Customer>> getCustomers() async {
    final db = await database;
    final rows = await db.query('customers', orderBy: 'name COLLATE NOCASE');
    return rows.map(Customer.fromMap).toList();
  }

  static Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final rows = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  static Future<int> updateCustomer(Customer customer) async {
    if (customer.id == null) {
      throw ArgumentError('Customer id is required for update.');
    }

    final db = await database;
    final data = customer.toMap();
    data.remove('created_at');
    return db.update(
      'customers',
      data,
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  static Future<int> deleteCustomer(int id) async {
    final db = await database;
    return db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  static Future<ShopInfo> getShopInfo() async {
    final db = await database;
    final rows = await db.query('shop_info', limit: 1);
    if (rows.isEmpty) {
      return const ShopInfo(name: 'Pharmacy Manager');
    }
    return ShopInfo.fromMap(rows.first);
  }

  static Future<void> saveShopInfo(ShopInfo info) async {
    final db = await database;
    await db.insert(
      'shop_info',
      info.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String> getNextInvoiceNo() async {
    final db = await database;
    return db.transaction((txn) async {
      final shopRows = await txn.query('shop_info', limit: 1);
      var prefix = 'INV';
      var nextNo = 1;
      var shopId = 1;

      if (shopRows.isEmpty) {
        await txn.insert('shop_info', {
          'id': 1,
          'invoice_prefix': prefix,
          'next_invoice_no': nextNo,
        });
      } else {
        final row = shopRows.first;
        prefix = row['invoice_prefix'] as String? ?? prefix;
        final rawNext = row['next_invoice_no'];
        if (rawNext is int) {
          nextNo = rawNext;
        } else if (rawNext is num) {
          nextNo = rawNext.toInt();
        } else if (rawNext != null) {
          nextNo = int.tryParse(rawNext.toString()) ?? nextNo;
        }
        final rawId = row['id'];
        if (rawId is int) {
          shopId = rawId;
        } else if (rawId is num) {
          shopId = rawId.toInt();
        }
      }

      await txn.update(
        'shop_info',
        {'next_invoice_no': nextNo + 1},
        where: 'id = ?',
        whereArgs: [shopId],
      );

      return '$prefix$nextNo';
    });
  }

  static Future<int> createSaleWithItems({
    required Sale sale,
    required List<SaleItem> items,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Sale must contain at least one item.');
    }

    final db = await database;
    return db.transaction((txn) async {
      final saleId = await txn.insert('sales', sale.toMap());

      for (final item in items) {
        final batchRows = await txn.query(
          'batches',
          columns: ['quantity'],
          where: 'id = ?',
          whereArgs: [item.batchId],
          limit: 1,
        );

        if (batchRows.isEmpty) {
          throw StateError('Batch ${item.batchId} not found.');
        }

        final available = (batchRows.first['quantity'] as num).toInt();
        if (available < item.quantity) {
          throw StateError('Not enough stock for batch ${item.batchId}.');
        }

        final itemMap = item.toMap();
        itemMap['sale_id'] = saleId;
        await txn.insert('sale_items', itemMap);

        await txn.rawUpdate(
          'UPDATE batches SET quantity = quantity - ? WHERE id = ?',
          [item.quantity, item.batchId],
        );
      }

      return saleId;
    });
  }

  static Future<List<SalesSummary>> getDailySalesSummary({
    int limit = 30,
  }) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT date(sale_date) AS period, SUM(net_amount) AS total, COUNT(*) AS count '
      'FROM sales GROUP BY period ORDER BY period DESC LIMIT ?',
      [limit],
    );
    return rows.map(SalesSummary.fromMap).toList();
  }

  static Future<List<SalesSummary>> getMonthlySalesSummary({
    int limit = 12,
  }) async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT strftime('%Y-%m', sale_date) AS period, SUM(net_amount) AS total, COUNT(*) AS count "
      'FROM sales GROUP BY period ORDER BY period DESC LIMIT ?',
      [limit],
    );
    return rows.map(SalesSummary.fromMap).toList();
  }

  static Future<List<Map<String, dynamic>>> getLowStockMedicines({int threshold = 10}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT m.id, m.name, m.barcode, COALESCE(SUM(b.quantity), 0) AS total_quantity 
      FROM medicines m 
      LEFT JOIN batches b ON m.id = b.medicine_id 
      GROUP BY m.id 
      HAVING total_quantity < ?
      ORDER BY total_quantity ASC
    ''', [threshold]);
  }

  static Future<List<Map<String, dynamic>>> getExpiringBatches({int days = 60}) async {
    final db = await database;
    final targetDate = DateTime.now().add(Duration(days: days));
    final targetDateStr = targetDate.toIso8601String().split('T').first;
    
    return db.rawQuery('''
      SELECT b.id, b.batch_number, b.expiry_date, b.quantity, m.name as medicine_name 
      FROM batches b 
      JOIN medicines m ON b.medicine_id = m.id 
      WHERE date(b.expiry_date) <= date(?) AND b.quantity > 0 
      ORDER BY date(b.expiry_date) ASC
    ''', [targetDateStr]);
  }

  static List<Medicine> _sampleMedicines() {
    return const [
      Medicine(
        name: 'Paracetamol 500',
        genericName: 'Paracetamol',
        category: 'Analgesic',
        manufacturer: 'Cipla',
        hsnCode: '3004',
        gstRate: 12.0,
        packSize: '10 tablets',
        defaultMrp: 25.0,
        barcode: '8901234500012',
      ),
      Medicine(
        name: 'Azithromycin 250',
        genericName: 'Azithromycin',
        category: 'Antibiotic',
        manufacturer: 'Sun Pharma',
        hsnCode: '3004',
        gstRate: 12.0,
        packSize: '6 tablets',
        defaultMrp: 78.0,
        barcode: '8901234500029',
      ),
      Medicine(
        name: 'Cetirizine 10',
        genericName: 'Cetirizine',
        category: 'Antihistamine',
        manufacturer: 'Dr. Reddy',
        hsnCode: '3004',
        gstRate: 12.0,
        packSize: '10 tablets',
        defaultMrp: 18.0,
        barcode: '8901234500036',
      ),
      Medicine(
        name: 'Pantoprazole 40',
        genericName: 'Pantoprazole',
        category: 'Gastro',
        manufacturer: 'Abbott',
        hsnCode: '3004',
        gstRate: 12.0,
        packSize: '10 tablets',
        defaultMrp: 65.0,
        barcode: '8901234500043',
      ),
      Medicine(
        name: 'Amoxicillin 500',
        genericName: 'Amoxicillin',
        category: 'Antibiotic',
        manufacturer: 'GSK',
        hsnCode: '3004',
        gstRate: 12.0,
        packSize: '10 capsules',
        defaultMrp: 95.0,
        barcode: '8901234500050',
      ),
    ];
  }

  static List<Map<String, Object>> _sampleBatches() {
    return [
      {
        'barcode': '8901234500012',
        'batch_number': 'PCM24A',
        'expiry_date': '2027-12-31',
        'quantity': 50,
        'mrp': 25.0,
        'purchase_rate': 18.0,
      },
      {
        'barcode': '8901234500029',
        'batch_number': 'AZM24B',
        'expiry_date': '2027-08-30',
        'quantity': 24,
        'mrp': 78.0,
        'purchase_rate': 55.0,
      },
      {
        'barcode': '8901234500036',
        'batch_number': 'CTZ24C',
        'expiry_date': '2027-03-31',
        'quantity': 60,
        'mrp': 18.0,
        'purchase_rate': 12.5,
      },
      {
        'barcode': '8901234500043',
        'batch_number': 'PTZ24D',
        'expiry_date': '2027-06-30',
        'quantity': 4, // Low stock
        'mrp': 65.0,
        'purchase_rate': 45.0,
      },
      {
        'barcode': '8901234500050',
        'batch_number': 'AMX24E',
        'expiry_date': '2023-11-30', // Expired
        'quantity': 30,
        'mrp': 95.0,
        'purchase_rate': 70.0,
      },
      {
        'barcode': '8901234500050',
        'batch_number': 'AMX25F',
        'expiry_date': DateTime.now().add(const Duration(days: 15)).toIso8601String().split('T').first, // Expiring soon
        'quantity': 15,
        'mrp': 98.0,
        'purchase_rate': 72.0,
      },
    ];
  }
}
