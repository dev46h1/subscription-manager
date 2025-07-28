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
      version: 3, // Incremented version for new schema
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const textTypeNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL DEFAULT 0';

    await db.execute('''
      CREATE TABLE subscriptions(
        id $idType,
        name $textType,
        amount $realType,
        currency $textType,
        renewal_date $textType,
        category $textType,
        notes $textTypeNullable,
        billing_period $textType DEFAULT 'monthly',
        status $textType DEFAULT 'active',
        created_date $textType,
        last_renew_date $textTypeNullable,
        renewal_count $intType
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add billing_period column for existing databases
      await db.execute('ALTER TABLE subscriptions ADD COLUMN billing_period TEXT DEFAULT "monthly"');
    }
    
    if (oldVersion < 3) {
      // Add new columns for enhanced functionality
      await db.execute('ALTER TABLE subscriptions ADD COLUMN status TEXT DEFAULT "active"');
      await db.execute('ALTER TABLE subscriptions ADD COLUMN created_date TEXT DEFAULT "${DateTime.now().toIso8601String()}"');
      await db.execute('ALTER TABLE subscriptions ADD COLUMN last_renew_date TEXT');
      await db.execute('ALTER TABLE subscriptions ADD COLUMN renewal_count INTEGER NOT NULL DEFAULT 0');
      
      // Update existing records to have proper created_date
      final now = DateTime.now().toIso8601String();
      await db.execute('UPDATE subscriptions SET created_date = ? WHERE created_date IS NULL OR created_date = ""', [now]);
    }
  }

  Future<int> createSubscription(Subscription subscription) async {
    final db = await instance.database;
    return await db.insert('subscriptions', subscription.toMap());
  }

  Future<List<Subscription>> readAllSubscriptions() async {
    final db = await instance.database;
    // Order by status (active first), then by renewal date
    const orderBy = '''
      CASE status 
        WHEN 'active' THEN 1 
        WHEN 'paused' THEN 2 
        WHEN 'cancelled' THEN 3 
        WHEN 'expired' THEN 4 
        ELSE 5 
      END, 
      renewal_date ASC
    ''';
    
    final result = await db.query('subscriptions', orderBy: orderBy);
    return result.map((json) => Subscription.fromMap(json)).toList();
  }

  Future<List<Subscription>> readSubscriptionsByStatus(SubscriptionStatus status) async {
    final db = await instance.database;
    const orderBy = 'renewal_date ASC';
    
    final result = await db.query(
      'subscriptions',
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: orderBy,
    );
    
    return result.map((json) => Subscription.fromMap(json)).toList();
  }

  Future<List<Subscription>> readActiveSubscriptions() async {
    return await readSubscriptionsByStatus(SubscriptionStatus.active);
  }

  Future<List<Subscription>> readCancelledSubscriptions() async {
    return await readSubscriptionsByStatus(SubscriptionStatus.cancelled);
  }

  Future<List<Subscription>> readPausedSubscriptions() async {
    return await readSubscriptionsByStatus(SubscriptionStatus.paused);
  }

  Future<Subscription?> readSubscription(int id) async {
    final db = await instance.database;
    
    final maps = await db.query(
      'subscriptions',
      columns: null,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Subscription.fromMap(maps.first);
    } else {
      return null;
    }
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

  Future<int> updateSubscriptionStatus(int id, SubscriptionStatus status) async {
    final db = await instance.database;
    return db.update(
      'subscriptions',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
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

  Future<int> deleteSubscriptionsByStatus(SubscriptionStatus status) async {
    final db = await instance.database;
    return await db.delete(
      'subscriptions',
      where: 'status = ?',
      whereArgs: [status.name],
    );
  }

  Future<int> deleteAllCancelledSubscriptions() async {
    return await deleteSubscriptionsByStatus(SubscriptionStatus.cancelled);
  }

  // Analytics queries
  Future<Map<String, dynamic>> getSubscriptionAnalytics() async {
    final db = await instance.database;
    
    // Get counts by status
    final statusCounts = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM subscriptions 
      GROUP BY status
    ''');
    
    // Get total spending by status (monthly equivalent calculation)
    final spendingByStatus = await db.rawQuery('''
      SELECT 
        status,
        SUM(
          CASE billing_period
            WHEN 'monthly' THEN amount
            WHEN 'quarterly' THEN amount / 3.0
            WHEN 'sixMonthly' THEN amount / 6.0
            WHEN 'yearly' THEN amount / 12.0
            ELSE amount
          END
        ) as monthly_equivalent
      FROM subscriptions 
      GROUP BY status
    ''');
    
    // Get category breakdown for active subscriptions
    final categoryBreakdown = await db.rawQuery('''
      SELECT 
        category,
        COUNT(*) as count,
        SUM(
          CASE billing_period
            WHEN 'monthly' THEN amount
            WHEN 'quarterly' THEN amount / 3.0
            WHEN 'sixMonthly' THEN amount / 6.0
            WHEN 'yearly' THEN amount / 12.0
            ELSE amount
          END
        ) as monthly_equivalent
      FROM subscriptions 
      WHERE status = 'active'
      GROUP BY category
      ORDER BY monthly_equivalent DESC
    ''');
    
    // Get billing period breakdown for active subscriptions
    final billingPeriodBreakdown = await db.rawQuery('''
      SELECT 
        billing_period,
        COUNT(*) as count,
        SUM(amount) as total_amount
      FROM subscriptions 
      WHERE status = 'active'
      GROUP BY billing_period
    ''');
    
    // Get upcoming renewals (next 30 days) for active subscriptions
    final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30)).toIso8601String();
    final upcomingRenewals = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM subscriptions 
      WHERE status = 'active' 
      AND renewal_date <= ?
      AND renewal_date >= ?
    ''', [thirtyDaysFromNow, DateTime.now().toIso8601String()]);
    
    return {
      'statusCounts': statusCounts,
      'spendingByStatus': spendingByStatus,
      'categoryBreakdown': categoryBreakdown,
      'billingPeriodBreakdown': billingPeriodBreakdown,
      'upcomingRenewalsCount': upcomingRenewals.first['count'] ?? 0,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  // Search functionality
  Future<List<Subscription>> searchSubscriptions(String query, {SubscriptionStatus? status}) async {
    final db = await instance.database;
    
    String whereClause = '''
      (name LIKE ? OR category LIKE ? OR notes LIKE ?)
    ''';
    List<dynamic> whereArgs = ['%$query%', '%$query%', '%$query%'];
    
    if (status != null) {
      whereClause += ' AND status = ?';
      whereArgs.add(status.name);
    }
    
    final result = await db.query(
      'subscriptions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '''
        CASE status 
          WHEN 'active' THEN 1 
          WHEN 'paused' THEN 2 
          WHEN 'cancelled' THEN 3 
          WHEN 'expired' THEN 4 
          ELSE 5 
        END, 
        renewal_date ASC
      ''',
    );
    
    return result.map((json) => Subscription.fromMap(json)).toList();
  }

  // Get subscriptions expiring in the next N days
  Future<List<Subscription>> getExpiringSubscriptions(int days) async {
    final db = await instance.database;
    final targetDate = DateTime.now().add(Duration(days: days)).toIso8601String();
    
    final result = await db.query(
      'subscriptions',
      where: 'status = ? AND renewal_date <= ?',
      whereArgs: ['active', targetDate],
      orderBy: 'renewal_date ASC',
    );
    
    return result.map((json) => Subscription.fromMap(json)).toList();
  }

  // Get overdue subscriptions
  Future<List<Subscription>> getOverdueSubscriptions() async {
    final db = await instance.database;
    final today = DateTime.now().toIso8601String();
    
    final result = await db.query(
      'subscriptions',
      where: 'status = ? AND renewal_date < ?',
      whereArgs: ['active', today],
      orderBy: 'renewal_date ASC',
    );
    
    return result.map((json) => Subscription.fromMap(json)).toList();
  }

  // Backup functionality
  Future<List<Map<String, dynamic>>> exportAllData() async {
    final db = await instance.database;
    return await db.query('subscriptions');
  }

  Future<void> importData(List<Map<String, dynamic>> data) async {
    final db = await instance.database;
    
    await db.transaction((txn) async {
      for (final item in data) {
        await txn.insert('subscriptions', item, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // Database maintenance
  Future<void> cleanupOldData() async {
    final db = await instance.database;
    
    // Remove cancelled subscriptions older than 1 year
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365)).toIso8601String();
    
    await db.delete(
      'subscriptions',
      where: 'status = ? AND created_date < ?',
      whereArgs: ['cancelled', oneYearAgo],
    );
  }

  Future<int> getSubscriptionCount({SubscriptionStatus? status}) async {
    final db = await instance.database;
    
    if (status != null) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM subscriptions WHERE status = ?',
        [status.name],
      );
      return result.first['count'] as int? ?? 0;
    } else {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM subscriptions');
      return result.first['count'] as int? ?? 0;
    }
  }

  Future<double> getTotalSpending({SubscriptionStatus? status}) async {
    final db = await instance.database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (status != null) {
      whereClause = 'WHERE status = ?';
      whereArgs = [status.name];
    }
    
    final result = await db.rawQuery('''
      SELECT 
        SUM(
          CASE billing_period
            WHEN 'monthly' THEN amount
            WHEN 'quarterly' THEN amount / 3.0
            WHEN 'sixMonthly' THEN amount / 6.0
            WHEN 'yearly' THEN amount / 12.0
            ELSE amount
          END
        ) as monthly_equivalent
      FROM subscriptions 
      $whereClause
    ''', whereArgs);
    
    return result.first['monthly_equivalent'] as double? ?? 0.0;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}