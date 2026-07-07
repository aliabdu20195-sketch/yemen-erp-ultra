import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('yemen_erp_ultra.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> initializeDatabase() async {
    await database;
  }

  Future _createDB(Database db, int version) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS branches (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, location TEXT, is_main INTEGER DEFAULT 0, is_active INTEGER DEFAULT 1)',
    );

    await db.execute(
      'CREATE TABLE IF NOT EXISTS warehouses (id INTEGER PRIMARY KEY AUTOINCREMENT, branch_id INTEGER, name TEXT NOT NULL, location TEXT, is_active INTEGER DEFAULT 1)',
    );

    await db.execute(
      'CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL UNIQUE, password_hash TEXT NOT NULL, full_name TEXT NOT NULL, role TEXT DEFAULT \'sales\', branch_id INTEGER, is_active INTEGER DEFAULT 1, last_login TIMESTAMP)',
    );

    await db.execute(
      'CREATE TABLE IF NOT EXISTS permissions (id INTEGER PRIMARY KEY AUTOINCREMENT, role TEXT NOT NULL, module TEXT NOT NULL, can_view INTEGER DEFAULT 0, can_create INTEGER DEFAULT 0, can_edit INTEGER DEFAULT 0, can_delete INTEGER DEFAULT 0, can_export INTEGER DEFAULT 0, UNIQUE(role, module))',
    );

    await db.execute(
      'CREATE TABLE IF NOT EXISTS categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT, is_active INTEGER DEFAULT 1)',
    );

    await db.execute(
      'CREATE TABLE IF NOT EXISTS units (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, symbol TEXT)',
    );

    await db.execute(
      'CREATE TABLE IF NOT EXISTS products (id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL UNIQUE, barcode TEXT, name TEXT NOT NULL, category_id INTEGER, unit_id INTEGER, buy_price REAL DEFAULT 0.00, sell_price REAL DEFAULT 0.00, wholesale_price REAL DEFAULT 0.00, tax_rate REAL DEFAULT 0.00, is_active INTEGER DEFAULT 1)',
    );

    await db.execute(
      'CREATE TABLE IF NOT EXISTS stock (id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL, warehouse_id INTEGER NOT NULL, quantity REAL DEFAULT 0.00, min_stock REAL DEFAULT 0.00, max_stock REAL DEFAULT 0.00, UNIQUE(product_id, warehouse_id))',
    );

    await db.execute(
      'CREATE TABLE IF NOT EXISTS stock_movements (id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER NOT NULL, warehouse_id INTEGER NOT NULL, movement_type TEXT NOT NULL, quantity REAL NOT NULL, notes TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)',
    );

    await db.execute(
      'CREATE TABLE IF NOT EXISTS customers (id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT UNIQUE, name TEXT NOT NULL, phone TEXT, address TEXT, city TEXT, opening_balance REAL DEFAULT 0.00, current_balance REAL DEFAULT 0.00, is_active INTEGER DEFAULT 1)',
    );

    await db.execute(
      'CREATE TABLE IF NOT EXISTS suppliers (id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT UNIQUE, name TEXT NOT NULL, phone TEXT, address TEXT, city TEXT, opening_balance REAL DEFAULT 0.00, current_balance REAL DEFAULT 0.00, is_active INTEGER DEFAULT 1)',
    );

    await db.execute(
      'CREATE TABLE IF NOT EXISTS sales_invoices (id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_number TEXT NOT NULL UNIQUE, customer_id INTEGER, user_id INTEGER, subtotal REAL DEFAULT 0.00, discount_amount REAL DEFAULT 0.00, tax_amount REAL DEFAULT 0.00, total REAL DEFAULT 0.00, paid REAL DEFAULT 0.00, due REAL DEFAULT 0.00, invoice_date TEXT NOT NULL, status TEXT DEFAULT \'draft\', notes TEXT)',
    );

    await db.execute(
      'CREATE TABLE IF NOT EXISTS sales_invoice_items (id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_id INTEGER NOT NULL, product_id INTEGER, quantity REAL NOT NULL, unit_price REAL NOT NULL, total REAL NOT NULL)',
    );

    await db.execute(
      'CREATE TABLE IF NOT EXISTS ai_alerts (id INTEGER PRIMARY KEY AUTOINCREMENT, alert_type TEXT NOT NULL, severity TEXT DEFAULT \'info\', title TEXT NOT NULL, description TEXT, is_read INTEGER DEFAULT 0)',
    );

    await db.execute(
      'CREATE TABLE IF NOT EXISTS settings (id INTEGER PRIMARY KEY AUTOINCREMENT, key TEXT NOT NULL UNIQUE, value TEXT)',
    );

    await _insertDefaultData(db);
  }

  Future _insertDefaultData(Database db) async {
    await db.insert('branches', {'name': 'Main Branch', 'is_main': 1});
    await db.insert('warehouses', {'branch_id': 1, 'name': 'Main Warehouse'});
    await db.insert('users', {
      'username': 'admin',
      'password_hash': r'$2b$10$tUhnkOzNg.1u6c5xgUZuUuw4jI6LnhXAR5WWcy4cpcjK43lnv0J.a',
      'full_name': 'Admin',
      'role': 'super_admin',
      'branch_id': 1,
    });
    await db.insert('units', {'name': 'Piece', 'symbol': 'pcs'});
    await db.insert('categories', {'name': 'General'});
await db.insert('categories', {'name': 'Electronics'});
    await db.insert('products', {
      'code': 'P001',
      'name': 'Dell Laptop',
      'category_id': 1,
      'unit_id': 1,
      'buy_price': 250000,
      'sell_price': 320000,
      'wholesale_price': 300000,
    });
    await db.insert('products', {
      'code': 'P002',
      'name': 'HP Printer',
      'category_id': 2,
      'unit_id': 1,
      'buy_price': 85000,
      'sell_price': 110000,
      'wholesale_price': 100000,
    });
    await db.insert('stock', {
      'product_id': 1,
      'warehouse_id': 1,
      'quantity': 15,
      'min_stock': 5,
    });
    await db.insert('stock', {
      'product_id': 2,
      'warehouse_id': 1,
      'quantity': 3,
      'min_stock': 5,
    });
    await db.insert('settings', {'key': 'company_name', 'value': 'Yemen Trading Co'});
  }

  Future<List<Map<String, dynamic>>> getAll(String table, {String? orderBy, int? limit}) async {
    final db = await database;
    return await db.query(table, orderBy: orderBy, limit: limit);
  }

  Future<Map<String, dynamic>?> getById(String table, int id) async {
    final db = await database;
    final results = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<int> update(String table, Map<String, dynamic> data, int id) async {
    final db = await database;
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<void> rawExecute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
