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
      version: 14,
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
          saled_return_ctn INTEGER NOT NULL DEFAULT 0,
          saled_return_units INTEGER NOT NULL DEFAULT 0,
          saled_return_total REAL NOT NULL DEFAULT 0,
          saled_return_value REAL NOT NULL DEFAULT 0,
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
          area TEXT,
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
          address TEXT,
          subtotal REAL NOT NULL,
          discount REAL NOT NULL,
          total REAL NOT NULL,
          items TEXT NOT NULL,
          generated INTEGER NOT NULL DEFAULT 0
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
          recovery REAL DEFAULT 0,
          discount REAL DEFAULT 0,
          return REAL DEFAULT 0,
          cash REAL DEFAULT 0,
          credit REAL DEFAULT 0,
          invoiceNumber TEXT
        )
      ''');

      await txn.execute('''
        CREATE TABLE IF NOT EXISTS suppliers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          fatherName TEXT NOT NULL,
          address TEXT NOT NULL,
          cnic TEXT NOT NULL,
          phone TEXT NOT NULL,
          type TEXT NOT NULL DEFAULT 'Supplier'
        )
      ''');

      await txn.execute('''
        CREATE TABLE ledger (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          shopName TEXT,
          shopCode TEXT,
          date TEXT,
          details TEXT,
          debit REAL,
          credit REAL,
          balance REAL
        )
      ''');

      await txn.execute('''
        CREATE TABLE IF NOT EXISTS app_metadata (
          key TEXT PRIMARY KEY,
          value TEXT
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
            recovery REAL DEFAULT 0,
            discount REAL DEFAULT 0,
            return REAL DEFAULT 0,
            cash REAL DEFAULT 0,
            credit REAL DEFAULT 0
          )
        ''');
        await txn.execute('''
          ALTER TABLE pick_list ADD COLUMN cash REAL DEFAULT 0
        ''');
        await txn.execute('''
          ALTER TABLE pick_list ADD COLUMN credit REAL DEFAULT 0
        ''');
      }
      if (oldVersion < 7) {
        await txn.execute("ALTER TABLE shops ADD COLUMN address TEXT");
        await txn.execute("ALTER TABLE shops ADD COLUMN area TEXT");
        await txn.execute("ALTER TABLE shops ADD COLUMN phone TEXT");
      }
      if (oldVersion < 8) {
        await txn.execute("ALTER TABLE invoices ADD COLUMN address TEXT");
      }
      if (oldVersion < 9) {
        await txn.execute("ALTER TABLE suppliers ADD COLUMN type TEXT NOT NULL DEFAULT 'Supplier'");
      }
      if (oldVersion < 10) {
        await txn.execute("ALTER TABLE invoices ADD COLUMN address TEXT");
      }
      if (oldVersion < 11) {
        await txn.execute("ALTER TABLE pick_list ADD COLUMN invoiceNumber TEXT");
      }
      if (oldVersion < 12) {
        await txn.execute("ALTER TABLE invoices ADD COLUMN generated INTEGER NOT NULL DEFAULT 0");
      }
      if (oldVersion < 13) {
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS ledger (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            shopName TEXT,
            shopCode TEXT,
            date TEXT,
            details TEXT,
            debit REAL,
            credit REAL,
            balance REAL
          )
        ''');
      }
      if (oldVersion < 14) {
        await txn.execute("ALTER TABLE stock_records ADD COLUMN saled_return_ctn INTEGER NOT NULL DEFAULT 0");
        await txn.execute("ALTER TABLE stock_records ADD COLUMN saled_return_units INTEGER NOT NULL DEFAULT 0");
        await txn.execute("ALTER TABLE stock_records ADD COLUMN saled_return_total REAL NOT NULL DEFAULT 0");
        await txn.execute("ALTER TABLE stock_records ADD COLUMN saled_return_value REAL NOT NULL DEFAULT 0");
      }
    });
  }

  Future<void> ensureAppMetadataTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT
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

  Future<int> updateProduct(Map<String, dynamic> product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [product['id']],
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

  Future<int> updateShop(Map<String, dynamic> shop) async {
    final db = await instance.database;
    return await db.update(
      'shops',
      shop,
      where: 'code = ?',
      whereArgs: [shop['code']],
    );
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

  Future<void> updateInvoiceGenerated(String id, int generated) async {
    final db = await database;
    await db.update(
      'invoices',
      {'generated': generated},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> getInvoiceByNumber(String invoiceNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'invoices',
      where: 'invoiceNumber = ?',
      whereArgs: [invoiceNumber],
    );
    return result.isNotEmpty ? result.first : null;
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

  Future<void> updateLoadFormItemReturn(String brandName, int returnUnits) async {
    final db = await database;
    
    // Get current return quantity
    final List<Map<String, dynamic>> result = await db.query(
      'load_form',
      columns: ['id', 'returnQty', 'units'],
      where: 'brandName = ?',
      whereArgs: [brandName],
    );

    if (result.isNotEmpty) {
      final currentReturnQty = result.first['returnQty'] as int? ?? 0;
      final totalUnits = result.first['units'] as int? ?? 0;
      final newReturnQty = currentReturnQty + returnUnits;
      
      // Validate that return quantity doesn't exceed total units
      if (newReturnQty > totalUnits) {
        throw Exception('Return quantity ($newReturnQty) cannot exceed total units ($totalUnits) for brand: $brandName');
      }

      // Calculate new sale value
      final newSale = totalUnits - newReturnQty;

      await db.update(
        'load_form',
        {
          'returnQty': newReturnQty,
          'sale': newSale, // Update sale field with calculated value
        },
        where: 'brandName = ?',
        whereArgs: [brandName],
      );
    } else {
      // If brand doesn't exist in load_form, create a new entry with return quantity
      await db.insert('load_form', {
        'brandName': brandName,
        'units': 0, // No original units since this is a return-only entry
        'issue': 0,
        'returnQty': returnUnits,
        'sale': 0 - returnUnits, // Sale will be negative for return-only entries
        'saledReturn': 0,
      });
    }
  }

  Future<void> recalculateAllLoadFormSales() async {
    final db = await database;
    
    // Get all items from load_form
    final List<Map<String, dynamic>> items = await db.query('load_form');
    
    for (final item in items) {
      final units = item['units'] as int? ?? 0;
      final returnQty = item['returnQty'] as int? ?? 0;
      final calculatedSale = units - returnQty;
      
      // Update the sale field if it's different from calculated value
      if (item['sale'] != calculatedSale) {
        await db.update(
          'load_form',
          {'sale': calculatedSale},
          where: 'id = ?',
          whereArgs: [item['id']],
        );
      }
    }
  }

  Future<void> updateStockRecordsFromLoadForm() async {
    final db = await database;
    
    // Get all items from load_form with sale > 0 or saledReturn > 0
    final List<Map<String, dynamic>> loadFormItems = await db.query(
      'load_form',
      where: 'sale > 0 OR saledReturn > 0',
    );
    
    for (final loadFormItem in loadFormItems) {
      final brandName = loadFormItem['brandName'] as String;
      final saleQuantity = loadFormItem['sale'] as int;
      final saledReturnQuantity = loadFormItem['saledReturn'] as int;
      
      // Find the product by brand name
      final List<Map<String, dynamic>> products = await db.query(
        'products',
        where: 'brand = ?',
        whereArgs: [brandName],
      );
      
      if (products.isNotEmpty) {
        final product = products.first;
        final productId = product['id'] as String;
        final tradeRate = product['salePrice'] as double;
        final boxPacking = product['boxPacking'] as int;
        
        // Calculate sale values
        final saleValue = saleQuantity * tradeRate;
        final saledReturnValue = saledReturnQuantity * tradeRate;
        
        // Get the latest stock record for this product
        final List<Map<String, dynamic>> stockRecords = await db.query(
          'stock_records',
          where: 'product_id = ?',
          whereArgs: [productId],
          orderBy: 'date DESC',
          limit: 1,
        );
        
        if (stockRecords.isNotEmpty) {
          // Update the latest stock record with sale and saled return data
          final latestRecord = stockRecords.first;
          final currentSaleUnits = latestRecord['sale_units'] as int? ?? 0;
          final currentSaleValue = latestRecord['sale_value'] as double? ?? 0.0;
          final currentSaledReturnUnits = latestRecord['saled_return_units'] as int? ?? 0;
          final currentSaledReturnValue = latestRecord['saled_return_value'] as double? ?? 0.0;
          
          // Add the new sale and saled return to existing data
          final newSaleUnits = currentSaleUnits + saleQuantity;
          final newSaleValue = currentSaleValue + saleValue;
          final newSaledReturnUnits = currentSaledReturnUnits + saledReturnQuantity;
          final newSaledReturnValue = currentSaledReturnValue + saledReturnValue;
          
          // Calculate sale CTN and Box based on packing strategy
          int saleCtn;
          int saleBox;
          
          if (newSaleUnits <= boxPacking) {
            // If total is less than or equal to box packing, no CTN needed
            saleCtn = 0;
            saleBox = newSaleUnits;
          } else {
            // If total exceeds box packing, calculate CTN and Box
            saleCtn = newSaleUnits ~/ boxPacking; // Integer division for CTN
            saleBox = newSaleUnits % boxPacking; // Remainder for Box
          }
          
          final saleTotal = newSaleUnits.toDouble(); // Total boxes sold
          
          // Calculate saled return CTN and Box based on packing strategy
          int saledReturnCtn;
          int saledReturnBox;
          
          if (newSaledReturnUnits <= boxPacking) {
            // If total is less than or equal to box packing, no CTN needed
            saledReturnCtn = 0;
            saledReturnBox = newSaledReturnUnits;
          } else {
            // If total exceeds box packing, calculate CTN and Box
            saledReturnCtn = newSaledReturnUnits ~/ boxPacking; // Integer division for CTN
            saledReturnBox = newSaledReturnUnits % boxPacking; // Remainder for Box
          }
          
          final saledReturnTotal = newSaledReturnUnits.toDouble(); // Total boxes returned
          
          // Calculate closing stock values
          final totalStockTotal = latestRecord['total_stock_total'] as double;
          final totalStockValue = latestRecord['total_stock_value'] as double;
          
          // Updated formula: Closing Stock = Total Stock - Sale + Saled Return
          final closingStockTotal = totalStockTotal - saleTotal + saledReturnTotal;
          final closingStockValue = totalStockValue - newSaleValue + newSaledReturnValue;
          
          // Calculate proper CTN and Box for Closing Stock based on packing strategy
          int closingStockCtn;
          int closingStockBox;
          
          if (closingStockTotal <= boxPacking) {
            // If total is less than or equal to box packing, no CTN needed
            closingStockCtn = 0;
            closingStockBox = closingStockTotal.toInt();
          } else {
            // If total exceeds box packing, calculate CTN and Box
            closingStockCtn = closingStockTotal ~/ boxPacking; // Integer division for CTN
            closingStockBox = closingStockTotal.toInt() % boxPacking; // Remainder for Box
          }
          
          await db.update(
            'stock_records',
            {
              'sale_ctn': saleCtn,
              'sale_units': saleBox,
              'sale_total': saleTotal,
              'sale_value': newSaleValue,
              'saled_return_ctn': saledReturnCtn,
              'saled_return_units': saledReturnBox,
              'saled_return_total': saledReturnTotal,
              'saled_return_value': newSaledReturnValue,
              // Update closing stock with new formula
              'closing_stock_ctn': closingStockCtn,
              'closing_stock_units': closingStockBox,
              'closing_stock_total': closingStockTotal,
              'closing_stock_value': closingStockValue,
            },
            where: 'id = ?',
            whereArgs: [latestRecord['id']],
          );
        } else {
          // Create a new stock record if none exists
          
          // Calculate sale CTN and Box based on packing strategy
          int saleCtn;
          int saleBox;
          
          if (saleQuantity <= boxPacking) {
            // If total is less than or equal to box packing, no CTN needed
            saleCtn = 0;
            saleBox = saleQuantity;
          } else {
            // If total exceeds box packing, calculate CTN and Box
            saleCtn = saleQuantity ~/ boxPacking; // Integer division for CTN
            saleBox = saleQuantity % boxPacking; // Remainder for Box
          }
          
          // Calculate saled return CTN and Box based on packing strategy
          int saledReturnCtn;
          int saledReturnBox;
          
          if (saledReturnQuantity <= boxPacking) {
            // If total is less than or equal to box packing, no CTN needed
            saledReturnCtn = 0;
            saledReturnBox = saledReturnQuantity;
          } else {
            // If total exceeds box packing, calculate CTN and Box
            saledReturnCtn = saledReturnQuantity ~/ boxPacking; // Integer division for CTN
            saledReturnBox = saledReturnQuantity % boxPacking; // Remainder for Box
          }
          
          // For new records, closing stock will be: 0 - Sale + Saled Return
          final closingStockTotal = 0.0 - saleQuantity + saledReturnQuantity;
          final closingStockValue = 0.0 - saleValue + saledReturnValue;
          
          // Calculate proper CTN and Box for Closing Stock (will be based on saled return for new records)
          int closingStockCtn = 0;
          int closingStockBox = 0;
          
          if (closingStockTotal > 0) {
            if (closingStockTotal <= boxPacking) {
              closingStockCtn = 0;
              closingStockBox = closingStockTotal.toInt();
            } else {
              closingStockCtn = closingStockTotal ~/ boxPacking;
              closingStockBox = closingStockTotal.toInt() % boxPacking;
            }
          }
          
          await db.insert('stock_records', {
            'product_id': productId,
            'date': DateTime.now().toIso8601String().split('T')[0],
            'opening_stock_ctn': 0,
            'opening_stock_units': 0,
            'opening_stock_total': 0.0,
            'opening_stock_value': 0.0,
            'received_ctn': 0,
            'received_units': 0,
            'received_total': 0.0,
            'received_value': 0.0,
            'total_stock_ctn': 0,
            'total_stock_units': 0,
            'total_stock_total': 0.0,
            'total_stock_value': 0.0,
            'closing_stock_ctn': closingStockCtn,
            'closing_stock_units': closingStockBox,
            'closing_stock_total': closingStockTotal,
            'closing_stock_value': closingStockValue,
            'sale_ctn': saleCtn,
            'sale_units': saleBox,
            'sale_total': saleQuantity.toDouble(),
            'sale_value': saleValue,
            'saled_return_ctn': saledReturnCtn,
            'saled_return_units': saledReturnBox,
            'saled_return_total': saledReturnQuantity.toDouble(),
            'saled_return_value': saledReturnValue,
          });
        }
      }
    }
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

  // Supplier operations
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    final db = await instance.database;
    return await db.query('suppliers', orderBy: 'name ASC');
  }

  Future<int> insertSupplier(Map<String, dynamic> supplier) async {
    final db = await instance.database;
    return await db.insert('suppliers', supplier);
  }

  Future<int> updateSupplier(Map<String, dynamic> supplier) async {
    final db = await instance.database;
    return await db.update('suppliers', supplier, where: 'id = ?', whereArgs: [supplier['id']]);
  }

  Future<int> deleteSupplier(int id) async {
    final db = await instance.database;
    return await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // Ledger operations
  Future<int> insertLedger(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('ledger', row);
  }

  // Close database
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<String?> getAppMetadata(String key) async {
    final db = await database;
    final result = await db.query('app_metadata', where: 'key = ?', whereArgs: [key]);
    if (result.isNotEmpty) {
      return result.first['value'] as String?;
    }
    return null;
  }

  Future<void> setAppMetadata(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_metadata',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
} 