import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _isDeleting = false;
  static bool _isInitialized = false;

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
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'records_keeper.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE income (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          category TEXT NOT NULL,
          details TEXT NOT NULL,
          amount REAL NOT NULL
        )
      ''');

      await txn.execute('''
        CREATE TABLE expenditure (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          category TEXT NOT NULL,
          details TEXT NOT NULL,
          amount REAL NOT NULL
        )
      ''');

      await txn.execute('''
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

      await txn.execute('''
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

      await txn.execute('''
        CREATE TABLE shops (
          code TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          owner_name TEXT NOT NULL,
          category TEXT NOT NULL,
          address TEXT,
          phone TEXT
        )
      ''');

      await txn.execute('''
        CREATE TABLE invoices (
          id TEXT PRIMARY KEY,
          invoiceNumber TEXT NOT NULL,
          date TEXT NOT NULL,
          shopName TEXT NOT NULL,
          shopCode TEXT NOT NULL,
          ownerName TEXT NOT NULL,
          category TEXT NOT NULL,
          subtotal REAL NOT NULL,
          discount REAL NOT NULL,
          total REAL NOT NULL,
          items TEXT NOT NULL
        )
      ''');

      await txn.execute('''
        CREATE TABLE load_form (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          brandName TEXT NOT NULL,
          units INTEGER NOT NULL,
          issue INTEGER DEFAULT 0,
          returnQty INTEGER DEFAULT 0,
          sale INTEGER DEFAULT 0,
          saledReturn INTEGER DEFAULT 0
        )
      ''');

      await txn.execute('''
        CREATE TABLE pick_list (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT,
          shopName TEXT,
          ownerName TEXT,
          billAmount REAL DEFAULT 0,
          paymentType TEXT DEFAULT '',
          recovery REAL DEFAULT 0
        )
      ''');
    });
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    await db.transaction((txn) async {
      if (oldVersion < 2) {
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS shops (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            ownerName TEXT NOT NULL,
            category TEXT NOT NULL
          )
        ''');
      }
      if (oldVersion < 3) {
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS invoices (
            id TEXT PRIMARY KEY,
            invoiceNumber TEXT NOT NULL,
            date TEXT NOT NULL,
            shopName TEXT NOT NULL,
            shopCode TEXT NOT NULL,
            ownerName TEXT NOT NULL,
            category TEXT NOT NULL,
            items TEXT NOT NULL,
            subtotal REAL NOT NULL,
            discount REAL NOT NULL,
            total REAL NOT NULL
          )
        ''');
      }
      if (oldVersion < 4) {
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS products (
            id TEXT PRIMARY KEY,
            company TEXT NOT NULL,
            brand TEXT NOT NULL,
            ctnRate REAL NOT NULL,
            boxRate REAL NOT NULL,
            ctnPacking INTEGER NOT NULL,
            boxPacking INTEGER NOT NULL,
            unitsPacking INTEGER NOT NULL,
            salePrice REAL NOT NULL
          )
        ''');
      }
      if (oldVersion < 5) {
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS load_form (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            brandName TEXT NOT NULL,
            units INTEGER NOT NULL,
            issue INTEGER DEFAULT 0,
            returnQty INTEGER DEFAULT 0,
            sale INTEGER DEFAULT 0,
            saledReturn INTEGER DEFAULT 0
          )
        ''');
      }
      if (oldVersion < 6) {
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS pick_list (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT,
            shopName TEXT,
            ownerName TEXT,
            billAmount REAL DEFAULT 0,
            paymentType TEXT DEFAULT '',
            recovery REAL DEFAULT 0
          )
        ''');
      }
    });
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

  // Invoice methods
  Future<void> insertInvoice(Map<String, dynamic> invoice) async {
    final Database db = await database;
    await db.insert(
      'invoices',
      {
        ...invoice,
        'items': jsonEncode(invoice['items']),
        'date': invoice['date'].toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getInvoices() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('invoices');
    return maps.map((map) {
      return {
        ...map,
        'items': jsonDecode(map['items']),
      };
    }).toList();
  }

  Future<void> deleteInvoice(String id) async {
    final db = await database;
    await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> getInvoice(String id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return {
      ...maps.first,
      'items': jsonDecode(maps.first['items']),
    };
  }

  // Load Form Methods
  Future<int> insertLoadFormItem(Map<String, dynamic> row) async {
    final db = await instance.database;
    
    // Check if brand already exists
    final List<Map<String, dynamic>> existing = await db.query(
      'load_form',
      where: 'brandName = ?',
      whereArgs: [row['brandName']],
    );

    if (existing.isNotEmpty) {
      // Update existing record by adding units
      final existingUnits = existing.first['units'] as int;
      final newUnits = existingUnits + (row['units'] as int);
      
      await db.update(
        'load_form',
        {'units': newUnits},
        where: 'brandName = ?',
        whereArgs: [row['brandName']],
      );
      return existing.first['id'] as int;
    } else {
      // Insert new record
      return await db.insert('load_form', row);
    }
  }

  Future<List<Map<String, dynamic>>> getLoadFormItems() async {
    final db = await instance.database;
    return await db.query('load_form', orderBy: 'id ASC');
  }

  Future<int> updateLoadFormItem(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'load_form',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  // Pick List operations
  Future<void> insertOrUpdatePickListItem(Map<String, dynamic> item) async {
    final db = await database;
    
    // Check if shop already exists in pick list
    final List<Map<String, dynamic>> existingItems = await db.query(
      'pick_list',
      where: 'shopName = ?',
      whereArgs: [item['shopName']],
    );

    if (existingItems.isNotEmpty) {
      // Update existing record by adding to billAmount
      final existingItem = existingItems.first;
      final newBillAmount = (existingItem['billAmount'] as double) + (item['billAmount'] as double);
      
      await db.update(
        'pick_list',
        {'billAmount': newBillAmount},
        where: 'id = ?',
        whereArgs: [existingItem['id']],
      );
    } else {
      // Insert new record
      await db.insert('pick_list', item);
    }
  }

  Future<List<Map<String, dynamic>>> getPickListItems() async {
    final db = await database;
    return db.query('pick_list');
  }

  Future<void> updatePickListItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.update(
      'pick_list',
      item,
      where: 'id = ?',
      whereArgs: [item['id']],
    );
  }

  // Close database
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
} 