import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _isDeleting = false;
  static bool _isInitialized = false;
  static const _databaseName = "accounts.db";
  static const _databaseVersion = 4;

  DatabaseHelper._init();

  Future<void> initialize() async {
    if (!_isInitialized) {
      if (Platform.isWindows || Platform.isLinux) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      _isInitialized = true;
    }
  }

  Future<void> deleteDatabase() async {
    if (_isDeleting) return;
    _isDeleting = true;
    
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'accounts.db');
      
      await databaseFactory.deleteDatabase(path);
    } finally {
      _isDeleting = false;
    }
  }

  Future<Database> get database async {
    await initialize();
    if (_database != null) return _database!;
    _database = await _initDB('accounts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
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
        id TEXT PRIMARY KEY,
        company TEXT NOT NULL,
        brand TEXT NOT NULL,
        ctnRate REAL NOT NULL,
        boxRate REAL NOT NULL,
        salePrice REAL NOT NULL,
        ctnPacking INTEGER NOT NULL,
        boxPacking INTEGER NOT NULL,
        unitsPacking INTEGER NOT NULL
      )
    ''');

    // Stock Records table
    await db.execute('''
      CREATE TABLE stock_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id TEXT NOT NULL,
        date TEXT NOT NULL,
        opening_stock_ctn INTEGER NOT NULL,
        opening_stock_units INTEGER NOT NULL,
        opening_stock_total REAL NOT NULL,
        opening_stock_value REAL NOT NULL,
        received_ctn INTEGER NOT NULL,
        received_units INTEGER NOT NULL,
        received_total REAL NOT NULL,
        received_value REAL NOT NULL,
        total_stock_ctn INTEGER NOT NULL,
        total_stock_units INTEGER NOT NULL,
        total_stock_total REAL NOT NULL,
        total_stock_value REAL NOT NULL,
        closing_stock_ctn INTEGER NOT NULL,
        closing_stock_units INTEGER NOT NULL,
        closing_stock_total REAL NOT NULL,
        closing_stock_value REAL NOT NULL,
        sale_ctn INTEGER NOT NULL,
        sale_units INTEGER NOT NULL,
        sale_total REAL NOT NULL,
        sale_value REAL NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // Shops table
    await db.execute('''
      CREATE TABLE shops (
        code TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        owner_name TEXT NOT NULL,
        category TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop the old products table if it exists
      await db.execute('DROP TABLE IF EXISTS products');
      
      // Create the new products table
      await db.execute('''
        CREATE TABLE products (
          id TEXT PRIMARY KEY,
          company TEXT NOT NULL,
          brand TEXT NOT NULL,
          ctnRate REAL NOT NULL,
          boxRate REAL NOT NULL,
          ctnPacking INTEGER NOT NULL,
          boxPacking INTEGER NOT NULL,
          unitsPacking INTEGER NOT NULL
        )
      ''');

      // Create the stock records table
      await db.execute('''
        CREATE TABLE stock_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id TEXT NOT NULL,
          date TEXT NOT NULL,
          opening_stock_ctn INTEGER NOT NULL,
          opening_stock_units INTEGER NOT NULL,
          opening_stock_total REAL NOT NULL,
          opening_stock_value REAL NOT NULL,
          received_ctn INTEGER NOT NULL,
          received_units INTEGER NOT NULL,
          received_total REAL NOT NULL,
          received_value REAL NOT NULL,
          total_stock_ctn INTEGER NOT NULL,
          total_stock_units INTEGER NOT NULL,
          total_stock_total REAL NOT NULL,
          total_stock_value REAL NOT NULL,
          closing_stock_ctn INTEGER NOT NULL,
          closing_stock_units INTEGER NOT NULL,
          closing_stock_total REAL NOT NULL,
          closing_stock_value REAL NOT NULL,
          sale_ctn INTEGER NOT NULL,
          sale_units INTEGER NOT NULL,
          sale_total REAL NOT NULL,
          sale_value REAL NOT NULL,
          FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 3) {
      // Add shops table in version 3
      await db.execute('''
        CREATE TABLE shops (
          code TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          owner_name TEXT NOT NULL,
          category TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      // Add sale price column
      await db.execute('ALTER TABLE products ADD COLUMN salePrice REAL DEFAULT 0');
    }
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
  Future<String> insertProduct(Map<String, dynamic> product) async {
    final db = await instance.database;
    await db.insert('products', product);
    return product['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query('products');
  }

  Future<void> deleteProduct(String id) async {
    final db = await instance.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Shop operations
  Future<String> generateShopCode() async {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';
    String code;
    bool isUnique = false;
    
    do {
      // Ensure at least 2 letters and 2 digits
      final List<String> codeChars = [];
      
      // Add 2 random letters
      for (var i = 0; i < 2; i++) {
        codeChars.add(letters[DateTime.now().microsecondsSinceEpoch % letters.length]);
      }
      
      // Add 2 random digits
      for (var i = 0; i < 2; i++) {
        codeChars.add(digits[DateTime.now().microsecondsSinceEpoch % digits.length]);
      }
      
      // Add 2 more random characters (can be either letter or digit)
      const allChars = letters + digits;
      for (var i = 0; i < 2; i++) {
        codeChars.add(allChars[DateTime.now().microsecondsSinceEpoch % allChars.length]);
      }
      
      // Shuffle the characters to make the pattern less predictable
      codeChars.shuffle();
      code = codeChars.join();
      
      // Check if code is unique
      final db = await instance.database;
      final result = await db.query(
        'shops',
        where: 'code = ?',
        whereArgs: [code],
      );
      
      isUnique = result.isEmpty;
    } while (!isUnique);
    
    return code;
  }

  Future<bool> insertShop(Map<String, dynamic> shop) async {
    try {
      final db = await instance.database;
      await db.insert('shops', shop);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getShops() async {
    final db = await instance.database;
    return await db.query('shops', orderBy: 'name ASC');
  }

  Future<bool> deleteShop(String code) async {
    try {
      final db = await instance.database;
      final rowsDeleted = await db.delete(
        'shops',
        where: 'code = ?',
        whereArgs: [code],
      );
      return rowsDeleted > 0;
    } catch (e) {
      return false;
    }
  }

  // Close database
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
} 