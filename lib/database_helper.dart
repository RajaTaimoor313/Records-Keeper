import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('accounts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Income table
    await db.execute('''
      CREATE TABLE income (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        details TEXT NOT NULL,
        amount REAL NOT NULL
      )
    ''');

    // Expenditure table
    await db.execute('''
      CREATE TABLE expenditure (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        details TEXT NOT NULL,
        amount REAL NOT NULL
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company TEXT NOT NULL,
        brand TEXT NOT NULL,
        ctnRate REAL NOT NULL,
        boxRate REAL NOT NULL,
        ctnPacking INTEGER NOT NULL,
        boxPacking INTEGER NOT NULL,
        unitsPacking INTEGER NOT NULL
      )
    ''');
  }

  // Income operations
  Future<int> insertIncome(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('income', row);
  }

  Future<List<Map<String, dynamic>>> getIncomes() async {
    final db = await instance.database;
    return await db.query('income', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getIncomesByCategory(String category) async {
    final db = await instance.database;
    return await db.query(
      'income',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
  }

  Future<double> getSalesRecoveryTotal() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM income WHERE category = ?',
      ['Sales & Recovery'],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  Future<double> getOtherIncomeTotal() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM income WHERE category = ?',
      ['Other Income'],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  Future<double> getTotalIncome() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM income',
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // Expenditure operations
  Future<int> insertExpenditure(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('expenditure', row);
  }

  Future<List<Map<String, dynamic>>> getExpenditures() async {
    final db = await instance.database;
    return await db.query('expenditure', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getExpendituresByCategory(
    String category,
  ) async {
    final db = await instance.database;
    return await db.query(
      'expenditure',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
  }

  Future<double> getTotalExpenditure() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenditure',
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // Product operations
  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('products', row);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products', orderBy: 'company ASC, brand ASC');
  }

  // Close database
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
} 