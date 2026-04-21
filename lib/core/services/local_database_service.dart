import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class LocalDatabaseService {
  Database? _database;

  Future<Database> open() async {
    if (_database != null) {
      return _database!;
    }

    final databasePath = await getDatabasesPath();
    final fullPath = path.join(databasePath, 'sari_sari_pos_db');

    _database = await openDatabase(
      fullPath,
      version: 5,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE items ADD COLUMN cost REAL NOT NULL DEFAULT 0.0');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE transactions ADD COLUMN totalCost REAL NOT NULL DEFAULT 0.0');
          await db.execute('ALTER TABLE transactions ADD COLUMN totalProfit REAL NOT NULL DEFAULT 0.0');
          await db.execute(
            "ALTER TABLE transaction_items ADD COLUMN itemName TEXT NOT NULL DEFAULT ''",
          );
          await db.execute('ALTER TABLE transaction_items ADD COLUMN cost REAL NOT NULL DEFAULT 0.0');
          await db.execute(
            'ALTER TABLE transaction_items ADD COLUMN costSubtotal REAL NOT NULL DEFAULT 0.0',
          );
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE transactions ADD COLUMN cashReceived REAL');
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN changeAmount REAL NOT NULL DEFAULT 0.0',
          );
        }
      },
    );

    return _database!;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS items (
        itemId INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL DEFAULT '',
        name TEXT NOT NULL DEFAULT '',
        price REAL NOT NULL DEFAULT 0.0,
        cost REAL NOT NULL DEFAULT 0.0,
        stock INTEGER NOT NULL DEFAULT 0,
        category TEXT NOT NULL DEFAULT 'Food',
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        createdAt INTEGER NOT NULL DEFAULT 0,
        lastModifiedAt INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        transactionId INTEGER PRIMARY KEY,
        customerName TEXT,
        status TEXT NOT NULL DEFAULT 'PAID',
        createdAt INTEGER NOT NULL DEFAULT 0,
        paidAt INTEGER,
        totalAmount REAL NOT NULL DEFAULT 0.0,
        totalCost REAL NOT NULL DEFAULT 0.0,
        totalProfit REAL NOT NULL DEFAULT 0.0,
        paymentType TEXT NOT NULL DEFAULT 'Cash',
        cashReceived REAL,
        changeAmount REAL NOT NULL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionId INTEGER NOT NULL,
        itemId INTEGER NOT NULL DEFAULT 0,
        itemName TEXT NOT NULL DEFAULT '',
        quantity INTEGER NOT NULL DEFAULT 0,
        price REAL NOT NULL DEFAULT 0.0,
        cost REAL NOT NULL DEFAULT 0.0,
        subtotal REAL NOT NULL DEFAULT 0.0,
        costSubtotal REAL NOT NULL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemId INTEGER NOT NULL DEFAULT 0,
        changeType TEXT NOT NULL DEFAULT 'SALE',
        quantity INTEGER NOT NULL DEFAULT 0,
        date INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
}

