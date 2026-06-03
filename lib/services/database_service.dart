import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._();
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'spicedesk.db');
    return openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE businesses (id TEXT PRIMARY KEY, owner_id TEXT NOT NULL, name TEXT NOT NULL, logo TEXT, address TEXT, phone TEXT, email TEXT, website TEXT, vat_number TEXT, currency TEXT DEFAULT \'ZAR\', currency_symbol TEXT DEFAULT \'R\', vat_rate REAL DEFAULT 0.15, country TEXT DEFAULT \'South Africa\', invoice_prefix TEXT, receipt_footer TEXT, cloud_sync_enabled INTEGER DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE categories (id TEXT PRIMARY KEY, business_id TEXT NOT NULL, name TEXT NOT NULL, type TEXT NOT NULL, created_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE products (id TEXT PRIMARY KEY, business_id TEXT NOT NULL, category_id TEXT, name TEXT NOT NULL, description TEXT, price REAL NOT NULL, cost_price REAL NOT NULL, stock_qty REAL DEFAULT 0, unit TEXT, low_stock_threshold REAL, barcode TEXT, image_path TEXT, active INTEGER DEFAULT 1, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE customers (id TEXT PRIMARY KEY, business_id TEXT NOT NULL, name TEXT NOT NULL, phone TEXT, email TEXT, address TEXT, notes TEXT, created_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE orders (id TEXT PRIMARY KEY, business_id TEXT NOT NULL, customer_id TEXT, order_type TEXT NOT NULL, status TEXT NOT NULL, subtotal REAL NOT NULL, tax_amount REAL NOT NULL DEFAULT 0, discount REAL NOT NULL DEFAULT 0, total REAL NOT NULL, payment_method TEXT NOT NULL, notes TEXT, created_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE order_items (id TEXT PRIMARY KEY, order_id TEXT NOT NULL, product_id TEXT NOT NULL, product_name TEXT NOT NULL, qty REAL NOT NULL, unit_price REAL NOT NULL, total REAL NOT NULL)');
    await db.execute('CREATE TABLE expenses (id TEXT PRIMARY KEY, business_id TEXT NOT NULL, category_id TEXT, amount REAL NOT NULL, description TEXT, reference TEXT, expense_date TEXT NOT NULL, created_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE invoices (id TEXT PRIMARY KEY, business_id TEXT NOT NULL, order_id TEXT, customer_id TEXT, invoice_number TEXT NOT NULL, pdf_path TEXT, status TEXT NOT NULL, created_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE bank_accounts (id TEXT PRIMARY KEY, business_id TEXT NOT NULL, account_name TEXT NOT NULL, bank_name TEXT NOT NULL, account_number TEXT NOT NULL, account_type TEXT, balance REAL DEFAULT 0, created_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE bank_transactions (id TEXT PRIMARY KEY, account_id TEXT NOT NULL, business_id TEXT NOT NULL, amount REAL NOT NULL, transaction_type TEXT NOT NULL, description TEXT, reference TEXT, transaction_date TEXT NOT NULL, created_at TEXT NOT NULL)');
    await db.execute('CREATE TABLE sync_log (id TEXT PRIMARY KEY, business_id TEXT NOT NULL, table_name TEXT NOT NULL, record_id TEXT NOT NULL, action TEXT NOT NULL, synced INTEGER DEFAULT 0, created_at TEXT NOT NULL)');
  }

  static Future<List<Map<String, dynamic>>> query(String sql, [List<Object?>? args]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }

  static Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return db.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  static Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }
}
