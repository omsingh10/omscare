class Tables {
  static const String medicines = '''
    CREATE TABLE IF NOT EXISTS medicines (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      generic_name TEXT,
      category TEXT,
      manufacturer TEXT,
      hsn_code TEXT,
      gst_rate REAL DEFAULT 12.0,
      pack_size TEXT,
      default_mrp REAL,
      barcode TEXT UNIQUE,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    )
  ''';

  static const String batches = '''
    CREATE TABLE IF NOT EXISTS batches (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      medicine_id INTEGER NOT NULL,
      batch_number TEXT NOT NULL,
      expiry_date TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      mrp REAL NOT NULL,
      purchase_rate REAL NOT NULL,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (medicine_id) REFERENCES medicines (id)
    )
  ''';

  static const String customers = '''
    CREATE TABLE IF NOT EXISTS customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT,
      email TEXT,
      address TEXT,
      created_at TEXT DEFAULT (datetime('now'))
    )
  ''';

  static const String sales = '''
    CREATE TABLE IF NOT EXISTS sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_id INTEGER,
      invoice_no TEXT NOT NULL UNIQUE,
      total_amount REAL NOT NULL,
      discount REAL DEFAULT 0,
      net_amount REAL NOT NULL,
      payment_mode TEXT,
      sale_date TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (customer_id) REFERENCES customers (id)
    )
  ''';

  static const String saleItems = '''
    CREATE TABLE IF NOT EXISTS sale_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id INTEGER NOT NULL,
      medicine_id INTEGER NOT NULL,
      batch_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL,
      rate REAL NOT NULL,
      gst_percentage REAL,
      total REAL NOT NULL,
      FOREIGN KEY (sale_id) REFERENCES sales (id),
      FOREIGN KEY (medicine_id) REFERENCES medicines (id),
      FOREIGN KEY (batch_id) REFERENCES batches (id)
    )
  ''';

  static const String purchases = '''
    CREATE TABLE IF NOT EXISTS purchases (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      supplier_name TEXT,
      invoice_no TEXT,
      total_amount REAL NOT NULL,
      purchase_date TEXT DEFAULT (datetime('now'))
    )
  ''';

  static const String purchaseItems = '''
    CREATE TABLE IF NOT EXISTS purchase_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      purchase_id INTEGER NOT NULL,
      medicine_id INTEGER NOT NULL,
      batch_number TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      purchase_rate REAL NOT NULL,
      mrp REAL NOT NULL,
      FOREIGN KEY (purchase_id) REFERENCES purchases (id),
      FOREIGN KEY (medicine_id) REFERENCES medicines (id)
    )
  ''';

  static const String shopInfo = '''
    CREATE TABLE IF NOT EXISTS shop_info (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      address TEXT,
      phone TEXT,
      gst_no TEXT,
      invoice_prefix TEXT DEFAULT 'INV',
      next_invoice_no INTEGER DEFAULT 1
    )
  ''';
}
