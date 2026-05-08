import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pharmacy_app/models/batch.dart' as app_models;
import 'package:pharmacy_app/models/customer.dart';
import 'package:pharmacy_app/models/medicine.dart';
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
}
