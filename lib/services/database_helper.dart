import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subscription.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('subscriptions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incremented version for schema update
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const textTypeNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE subscriptions(
        id $idType,
        name $textType,
        amount $realType,
        currency $textType,
        renewal_date $textType,
        category $textType,
        notes $textTypeNullable,
        billing_period $textType DEFAULT 'monthly'
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add billing_period column for existing databases
      await db.execute('ALTER TABLE subscriptions ADD COLUMN billing_period TEXT DEFAULT "monthly"');
    }
  }

  Future<int> createSubscription(Subscription subscription) async {
    final db = await instance.database;
    return await db.insert('subscriptions', subscription.toMap());
  }

  Future<List<Subscription>> readAllSubscriptions() async {
    final db = await instance.database;
    const orderBy = 'renewal_date ASC';
    final result = await db.query('subscriptions', orderBy: orderBy);
    return result.map((json) => Subscription.fromMap(json)).toList();
  }

  Future<int> updateSubscription(Subscription subscription) async {
    final db = await instance.database;
    return db.update(
      'subscriptions',
      subscription.toMap(),
      where: 'id = ?',
      whereArgs: [subscription.id],
    );
  }

  Future<int> deleteSubscription(int id) async {
    final db = await instance.database;
    return await db.delete(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}