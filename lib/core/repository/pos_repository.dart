import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../models/app_models.dart';
import '../services/local_database_service.dart';
import '../utils/formatters.dart';

class PosRepository {
  PosRepository._(this._db);

  final Database _db;

  static const double _defaultMarkup = 0.20;

  static final List<_SampleItemSignature> _sampleItemSignatures = [
    const _SampleItemSignature('SSS000001', 'Rice (5kg)', 250.0, 'Staples'),
    const _SampleItemSignature('SSS000002', 'Cooking Oil (1L)', 85.0, 'Staples'),
    const _SampleItemSignature('SSS000003', 'Sugar (1kg)', 65.0, 'Staples'),
    const _SampleItemSignature('SSS000004', 'Canned Sardines', 28.0, 'Canned Goods'),
    const _SampleItemSignature('SSS000005', 'Instant Noodles', 14.0, 'Snacks'),
    const _SampleItemSignature('SSS000006', 'Coffee (3in1)', 12.0, 'Beverages'),
    const _SampleItemSignature('SSS000007', 'Soap Bar', 35.0, 'Personal Care'),
    const _SampleItemSignature('SSS000008', 'Shampoo Sachet', 7.0, 'Personal Care'),
    const _SampleItemSignature('SSS000009', 'Bottled Water (500ml)', 15.0, 'Beverages'),
    const _SampleItemSignature('SSS000010', 'Biscuits', 10.0, 'Snacks'),
    const _SampleItemSignature('SSS000011', 'Condensed Milk', 42.0, 'Staples'),
    const _SampleItemSignature('SSS000012', 'Soy Sauce (350ml)', 25.0, 'Condiments'),
    const _SampleItemSignature('SSS000013', 'Vinegar (350ml)', 22.0, 'Condiments'),
    const _SampleItemSignature('SSS000014', 'Laundry Detergent', 8.0, 'Household'),
    const _SampleItemSignature('SSS000015', 'Toothpaste Sachet', 5.0, 'Personal Care'),
  ];

  static const Set<int> _sampleTransactionIds = {1000, 1001, 1002, 1003, 1004};

  static Future<PosRepository> create(LocalDatabaseService service) async {
    final db = await service.open();
    return PosRepository._(db);
  }

  Future<List<ItemModel>> getAllItems() async {
    final rows = await _db.query('items', orderBy: 'name ASC');
    return rows.map(ItemModel.fromMap).toList(growable: false);
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final rows = await _db.query('transactions', orderBy: 'createdAt DESC');
    return rows.map(TransactionModel.fromMap).toList(growable: false);
  }

  Future<List<TransactionModel>> getPendingCredits() async {
    final rows = await _db.query(
      'transactions',
      where: 'status = ?',
      whereArgs: const ['PENDING_CREDIT'],
      orderBy: 'createdAt DESC',
    );
    return rows.map(TransactionModel.fromMap).toList(growable: false);
  }

  Future<List<InventoryLogModel>> getAllInventoryLogs() async {
    final rows = await _db.query('inventory_logs', orderBy: 'date DESC');
    return rows.map(InventoryLogModel.fromMap).toList(growable: false);
  }

  Future<List<TransactionItemModel>> getAllTransactionItems() async {
    final rows = await _db.query('transaction_items');
    return rows.map(TransactionItemModel.fromMap).toList(growable: false);
  }

  Future<ItemModel?> getItemById(int itemId) async {
    final rows = await _db.query(
      'items',
      where: 'itemId = ?',
      whereArgs: [itemId],
      limit: 1,
    );
    return rows.isEmpty ? null : ItemModel.fromMap(rows.first);
  }

  Future<TransactionModel?> getTransactionById(int transactionId) async {
    final rows = await _db.query(
      'transactions',
      where: 'transactionId = ?',
      whereArgs: [transactionId],
      limit: 1,
    );
    return rows.isEmpty ? null : TransactionModel.fromMap(rows.first);
  }

  Future<List<ItemModel>> searchItems(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return const [];
    }
    final pattern = '%$normalized%';
    final rows = await _db.query(
      'items',
      where: "status = 'ACTIVE' AND (name LIKE ? OR barcode LIKE ?)",
      whereArgs: [pattern, pattern],
      orderBy: 'name ASC',
    );
    return rows.map(ItemModel.fromMap).toList(growable: false);
  }

  Future<List<TransactionModel>> searchTransactions(String query) async {
    final normalized = query.trim();
    final pattern = '%$normalized%';
    final rows = await _db.rawQuery(
      '''
      SELECT * FROM transactions
      WHERE customerName LIKE ? OR CAST(transactionId AS TEXT) LIKE ?
      ORDER BY createdAt DESC
      ''',
      [pattern, pattern],
    );
    return rows.map(TransactionModel.fromMap).toList(growable: false);
  }

  Future<ItemModel?> getItemByBarcode(String barcode) async {
    final normalized = _normalizeBarcode(barcode);
    if (normalized.isEmpty) {
      return null;
    }
    final items = await getAllItems();
    for (final item in items) {
      if (_normalizeBarcode(item.barcode) == normalized) {
        return item;
      }
    }
    return null;
  }

  Future<PriceSuggestion> suggestPrice(String name, double cost) async {
    final normalizedName = name.trim();
    double? existingAverage;
    if (normalizedName.isNotEmpty) {
      final rows = await _db.rawQuery(
        'SELECT AVG(price) AS averagePrice FROM items WHERE LOWER(TRIM(name)) = LOWER(TRIM(?))',
        [normalizedName],
      );
      final average = rows.first['averagePrice'];
      final parsed = average == null ? null : (average as num).toDouble();
      if (parsed != null && !parsed.isNaN && parsed > 0) {
        existingAverage = parsed;
      }
    }

    final rawPrice = existingAverage ?? (cost + (cost * _defaultMarkup));
    return PriceSuggestion(
      suggestedPrice: rawPrice.roundToDouble() < 0 ? 0 : rawPrice.roundToDouble(),
      source: existingAverage != null
          ? PriceSuggestionSource.existingAverage
          : PriceSuggestionSource.costMarkup,
    );
  }

  Future<ItemModel> addItem({
    required String name,
    required double price,
    required double cost,
    required int stock,
    required String category,
    required String barcode,
  }) async {
    final allItems = await getAllItems();
    final maxNum = allItems.fold<int>(0, (current, item) {
      final value = int.tryParse(item.barcode.replaceFirst('SSS', '')) ?? 0;
      return math.max(current, value);
    });

    final normalizedBarcode = _normalizeBarcode(barcode);
    final finalBarcode = normalizedBarcode.isEmpty
        ? 'SSS${(maxNum + 1).toString().padLeft(6, '0')}'
        : normalizedBarcode;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (normalizedBarcode.isNotEmpty) {
      final existingItem = allItems.cast<ItemModel?>().firstWhere(
            (item) => item != null && _normalizeBarcode(item.barcode) == normalizedBarcode,
            orElse: () => null,
          );

      if (existingItem != null) {
        final mergedItem = existingItem.copyWith(
          name: name.trim().isEmpty ? existingItem.name : name.trim(),
          price: price,
          cost: cost,
          stock: existingItem.stock + stock,
          category: InventoryCategories.normalize(
            category,
            fallback: InventoryCategories.normalize(existingItem.category),
          ),
          barcode: existingItem.barcode.isEmpty ? finalBarcode : existingItem.barcode,
          lastModifiedAt: now,
        );
        await _db.update(
          'items',
          mergedItem.toMap()..remove('itemId'),
          where: 'itemId = ?',
          whereArgs: [existingItem.itemId],
        );
        if (stock > 0) {
          await _db.insert(
            'inventory_logs',
            InventoryLogModel(
              itemId: existingItem.itemId,
              changeType: 'STOCK_IN',
              quantity: stock,
              date: now,
            ).toMap()..remove('id'),
          );
        }
        return mergedItem;
      }
    }

    final item = ItemModel(
      name: name.trim(),
      price: price,
      cost: cost,
      stock: stock,
      category: InventoryCategories.normalize(category),
      barcode: finalBarcode,
      status: 'ACTIVE',
      createdAt: now,
      lastModifiedAt: now,
    );
    final insertedId = await _db.insert('items', item.toMap()..remove('itemId'));
    if (stock > 0) {
      await _db.insert(
        'inventory_logs',
        InventoryLogModel(
          itemId: insertedId,
          changeType: 'STOCK_IN',
          quantity: stock,
          date: now,
        ).toMap()..remove('id'),
      );
    }
    return item.copyWith(itemId: insertedId);
  }

  Future<void> updateItem({
    required int itemId,
    required String name,
    required double price,
    required double cost,
    required String category,
    required String barcode,
  }) async {
    final item = await getItemById(itemId);
    if (item == null) {
      return;
    }

    final normalizedBarcode = _normalizeBarcode(barcode);
    final otherItem = normalizedBarcode.isEmpty
        ? null
        : await _findItemByBarcode(
            normalizedBarcode,
            excludingItemId: itemId,
          );
    if (otherItem != null) {
      throw Exception('Barcode already exists on ${otherItem.name}');
    }

    final updated = item.copyWith(
      name: name.trim(),
      price: price,
      cost: cost,
      barcode: normalizedBarcode.isEmpty ? item.barcode : normalizedBarcode,
      category: InventoryCategories.normalize(
        category,
        fallback: InventoryCategories.normalize(item.category),
      ),
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _db.update(
      'items',
      updated.toMap()..remove('itemId'),
      where: 'itemId = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> deleteInactiveItem(int itemId) async {
    final item = await getItemById(itemId);
    if (item == null) {
      return;
    }
    if (item.isActive) {
      throw Exception('Deactivate the item before deleting it');
    }

    await _db.transaction((txn) async {
      await txn.delete(
        'inventory_logs',
        where: 'itemId = ?',
        whereArgs: [itemId],
      );
      await txn.delete(
        'items',
        where: 'itemId = ?',
        whereArgs: [itemId],
      );
    });
  }

  Future<void> deactivateItem(int itemId) {
    return _db.update(
      'items',
      {
        'status': 'INACTIVE',
        'lastModifiedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'itemId = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> activateItem(int itemId) {
    return _db.update(
      'items',
      {
        'status': 'ACTIVE',
        'lastModifiedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'itemId = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> stockIn(int itemId, int quantity) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.rawUpdate(
      'UPDATE items SET stock = stock + ?, lastModifiedAt = ? WHERE itemId = ?',
      [quantity, now, itemId],
    );
    await _db.insert(
      'inventory_logs',
      InventoryLogModel(
        itemId: itemId,
        changeType: 'STOCK_IN',
        quantity: quantity,
        date: now,
      ).toMap()..remove('id'),
    );
  }

  Future<List<ItemModel>> getLowStockItems(int threshold) async {
    final rows = await _db.query(
      'items',
      where: "status = 'ACTIVE' AND stock <= ? AND stock > 0",
      whereArgs: [threshold],
      orderBy: 'stock ASC, name ASC',
    );
    return rows.map(ItemModel.fromMap).toList(growable: false);
  }

  Future<List<ItemModel>> getOutOfStockItems() async {
    final rows = await _db.query(
      'items',
      where: "status = 'ACTIVE' AND stock = 0",
      orderBy: 'name ASC',
    );
    return rows.map(ItemModel.fromMap).toList(growable: false);
  }

  Future<TransactionModel> createTransaction({
    String? customerName,
    required String paymentType,
    required List<CartItemData> cartItems,
    double? cashReceived,
  }) async {
    final transactionId = DateTime.now().millisecondsSinceEpoch;
    final totalAmount = cartItems.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
    final totalCost = cartItems.fold<double>(0, (sum, item) => sum + (item.cost * item.quantity));
    final totalProfit = totalAmount - totalCost;
    final now = DateTime.now().millisecondsSinceEpoch;
    final isPaid = paymentType == 'Cash';
    final finalCashReceived = isPaid
        ? math.max(cashReceived ?? totalAmount, totalAmount).toDouble()
        : null;

    final transaction = TransactionModel(
      transactionId: transactionId,
      customerName: customerName?.trim().isEmpty == true ? null : customerName?.trim(),
      status: isPaid ? 'PAID' : 'PENDING_CREDIT',
      createdAt: now,
      paidAt: isPaid ? now : null,
      totalAmount: totalAmount,
      totalCost: totalCost,
      totalProfit: totalProfit,
      paymentType: paymentType,
      cashReceived: finalCashReceived,
      changeAmount: isPaid && finalCashReceived != null
          ? math.max(finalCashReceived - totalAmount, 0).toDouble()
          : 0,
    );

    await _db.transaction((txn) async {
      await txn.insert('transactions', transaction.toMap());

      for (final cartItem in cartItems) {
        await txn.insert(
          'transaction_items',
          TransactionItemModel(
            transactionId: transactionId,
            itemId: cartItem.itemId,
            itemName: cartItem.name,
            quantity: cartItem.quantity,
            price: cartItem.price,
            cost: cartItem.cost,
            subtotal: cartItem.price * cartItem.quantity,
            costSubtotal: cartItem.cost * cartItem.quantity,
          ).toMap()..remove('id'),
        );
        await txn.rawUpdate(
          'UPDATE items SET stock = MAX(0, stock - ?), lastModifiedAt = ? WHERE itemId = ?',
          [cartItem.quantity, now, cartItem.itemId],
        );
        await txn.insert(
          'inventory_logs',
          InventoryLogModel(
            itemId: cartItem.itemId,
            changeType: 'SALE',
            quantity: -cartItem.quantity,
            date: now,
          ).toMap()..remove('id'),
        );
      }
    });

    return transaction;
  }

  Future<void> settleCredit(int transactionId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.update(
      'transactions',
      {
        'status': 'PAID',
        'paidAt': now,
      },
      where: 'transactionId = ?',
      whereArgs: [transactionId],
    );
  }

  Future<List<TransactionItemModel>> getTransactionItems(int transactionId) async {
    final rows = await _db.query(
      'transaction_items',
      where: 'transactionId = ?',
      whereArgs: [transactionId],
    );
    return rows.map(TransactionItemModel.fromMap).toList(growable: false);
  }

  Future<TodayIncome> getTodayIncome() async {
    final start = startOfDay(DateTime.now().millisecondsSinceEpoch);
    final transactions = await _queryPaidTransactionsSince(start);
    final transactionItems = <TransactionItemModel>[];
    for (final transaction in transactions) {
      transactionItems.addAll(await getTransactionItems(transaction.transactionId));
    }

    final amount = transactions.fold<double>(0, (sum, item) => sum + item.totalAmount);
    final profit = transactions.fold<double>(0, (sum, item) => sum + item.totalProfit);
    final count = transactions.length;
    final salesMap = <String, int>{};
    for (final item in transactionItems) {
      final name = item.itemName.isEmpty ? 'Item #${item.itemId}' : item.itemName;
      salesMap[name] = (salesMap[name] ?? 0) + item.quantity;
    }

    var topItemName = 'N/A';
    var topQuantity = 0;
    for (final entry in salesMap.entries) {
      if (entry.value > topQuantity) {
        topItemName = entry.key;
        topQuantity = entry.value;
      }
    }

    return TodayIncome(
      amount: amount,
      profit: profit,
      count: count,
      topItem: topItemName,
      topQty: topQuantity,
    );
  }

  Future<double> getWeeklyIncome() async =>
      _sumTransactions(await _queryPaidTransactionsSince(_startOfWeek()));

  Future<double> getWeeklyProfit() async =>
      _sumTransactions(await _queryPaidTransactionsSince(_startOfWeek()), profit: true);

  Future<double> getMonthlyIncome() async =>
      _sumTransactions(await _queryPaidTransactionsSince(_startOfMonth()));

  Future<double> getMonthlyProfit() async =>
      _sumTransactions(await _queryPaidTransactionsSince(_startOfMonth()), profit: true);

  Future<double> getYearlyIncome() async =>
      _sumTransactions(await _queryPaidTransactionsSince(_startOfYear()));

  Future<DashboardAnalyticsSummary> getDashboardAnalyticsSummary({
    required int start,
    required int end,
  }) async {
    final normalizedStart = startOfDay(start);
    final normalizedEnd = startOfDay(end);
    final transactions = await _queryPaidTransactionsBetween(
      normalizedStart,
      plusDays(normalizedEnd, 1),
    );
    final transactionItems = <TransactionItemModel>[];
    for (final transaction in transactions) {
      transactionItems.addAll(await getTransactionItems(transaction.transactionId));
    }

    final sales = transactions.fold<double>(
      0,
      (sum, item) => sum + item.totalAmount,
    );
    final profit = transactions.fold<double>(
      0,
      (sum, item) => sum + item.totalProfit,
    );

    final salesMap = <String, int>{};
    for (final item in transactionItems) {
      final name = item.itemName.isEmpty ? 'Item #${item.itemId}' : item.itemName;
      salesMap[name] = (salesMap[name] ?? 0) + item.quantity;
    }

    var topItemName = 'N/A';
    var topQuantity = 0;
    for (final entry in salesMap.entries) {
      if (entry.value > topQuantity) {
        topItemName = entry.key;
        topQuantity = entry.value;
      }
    }

    return DashboardAnalyticsSummary(
      sales: sales,
      profit: profit,
      transactionCount: transactions.length,
      topItem: topItemName,
      topQuantity: topQuantity,
    );
  }

  Future<List<TopSeller>> getTopSellers({int limit = 5}) async {
    final allItems = await getAllTransactionItems();
    final salesMap = <String, int>{};
    for (final item in allItems.where((entry) => entry.quantity > 0)) {
      final name = item.itemName.isEmpty ? 'Item #${item.itemId}' : item.itemName;
      salesMap[name] = (salesMap[name] ?? 0) + item.quantity;
    }

    final entries = salesMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(limit).map((entry) {
      return TopSeller(
        item: ItemModel(name: entry.key),
        totalSold: entry.value,
      );
    }).toList(growable: false);
  }

  Future<List<TopSeller>> getTopSellersForRange({
    required int start,
    required int end,
    int limit = 5,
  }) async {
    final normalizedStart = startOfDay(start);
    final normalizedEnd = startOfDay(end);
    final rows = await _db.rawQuery(
      '''
      SELECT
        ti.itemId AS itemId,
        ti.itemName AS itemName,
        SUM(ti.quantity) AS totalSold
      FROM transaction_items ti
      INNER JOIN transactions t ON t.transactionId = ti.transactionId
      WHERE t.status = 'PAID'
        AND t.paidAt >= ?
        AND t.paidAt < ?
      GROUP BY ti.itemId, ti.itemName
      ORDER BY totalSold DESC
      LIMIT ${limit.clamp(1, 12)}
      ''',
      [normalizedStart, plusDays(normalizedEnd, 1)],
    );

    final sellers = <TopSeller>[];
    for (final row in rows) {
      final itemId = (row['itemId'] as num?)?.toInt() ?? 0;
      final totalSold = (row['totalSold'] as num?)?.toInt() ?? 0;
      final savedItem = itemId <= 0 ? null : await getItemById(itemId);
      final fallbackName = row['itemName'] as String? ?? 'Item #$itemId';
      sellers.add(
        TopSeller(
          item: savedItem ??
              ItemModel(
                itemId: itemId,
                name: fallbackName,
                status: 'INACTIVE',
              ),
          totalSold: totalSold,
        ),
      );
    }
    return sellers;
  }

  Future<List<DailyIncome>> getDailyIncomeForChart() async {
    final now = startOfDay(DateTime.now().millisecondsSinceEpoch);
    return getDailyIncomeForDateRange(
      start: plusDays(now, -6),
      end: now,
    );
  }

  Future<List<DailyIncome>> getDailyIncomeForDateRange({
    required int start,
    required int end,
  }) async {
    final normalizedStart = startOfDay(start);
    final normalizedEnd = startOfDay(end);
    final transactions = await _queryPaidTransactionsBetween(
      normalizedStart,
      plusDays(normalizedEnd, 1),
    );
    final totalsByDay = <int, double>{};
    for (final transaction in transactions) {
      final paidAt = transaction.paidAt;
      if (paidAt == null) {
        continue;
      }
      final dayKey = startOfDay(paidAt);
      totalsByDay[dayKey] = (totalsByDay[dayKey] ?? 0) + transaction.totalAmount;
    }

    final daySpan = ((normalizedEnd - normalizedStart) ~/ Duration.millisecondsPerDay) + 1;
    final chart = <DailyIncome>[];
    for (var offset = 0; offset < daySpan; offset++) {
      final dayValue = plusDays(normalizedStart, offset);
      chart.add(
        DailyIncome(
          day: daySpan <= 7 ? toShortDayLabel(dayValue) : toMonthDayLabel(dayValue),
          amount: totalsByDay[dayValue] ?? 0,
        ),
      );
    }
    return chart;
  }

  Future<void> removeLegacySeedDataIfNeeded() async {
    final items = await getAllItems();
    if (items.isEmpty) {
      return;
    }

    final transactions = await getAllTransactions();
    final matchesSampleItems = items.length == _sampleItemSignatures.length &&
        items.every((item) => _sampleItemSignatures.any((signature) => signature.matches(item)));
    final containsOnlySampleTransactions = transactions.every(
      (transaction) => _sampleTransactionIds.contains(transaction.transactionId),
    );

    if (matchesSampleItems && containsOnlySampleTransactions) {
      await clearAllData();
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final item in items) {
      final normalizedCategory = InventoryCategories.normalize(item.category);
      if (item.category != normalizedCategory) {
        await _db.update(
          'items',
          {
            'category': normalizedCategory,
            'lastModifiedAt': now,
          },
          where: 'itemId = ?',
          whereArgs: [item.itemId],
        );
      }
    }
  }

  Future<void> clearAllData() async {
    await _db.transaction((txn) async {
      await txn.delete('items');
      await txn.delete('transactions');
      await txn.delete('transaction_items');
      await txn.delete('inventory_logs');
    });
  }

  Future<void> replaceAllData({
    required List<ItemModel> items,
    required List<TransactionModel> transactions,
    required List<TransactionItemModel> transactionItems,
    required List<InventoryLogModel> inventoryLogs,
  }) async {
    await _db.transaction((txn) async {
      await txn.delete('inventory_logs');
      await txn.delete('transaction_items');
      await txn.delete('transactions');
      await txn.delete('items');

      for (final item in items) {
        await txn.insert('items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final transaction in transactions) {
        await txn.insert(
          'transactions',
          transaction.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final item in transactionItems) {
        await txn.insert(
          'transaction_items',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final log in inventoryLogs) {
        await txn.insert(
          'inventory_logs',
          log.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<TransactionModel>> _queryPaidTransactionsSince(int start) async {
    final rows = await _db.query(
      'transactions',
      where: "status = 'PAID' AND paidAt >= ?",
      whereArgs: [start],
    );
    return rows.map(TransactionModel.fromMap).toList(growable: false);
  }

  Future<List<TransactionModel>> _queryPaidTransactionsBetween(
    int start,
    int endExclusive,
  ) async {
    final rows = await _db.query(
      'transactions',
      where: "status = 'PAID' AND paidAt >= ? AND paidAt < ?",
      whereArgs: [start, endExclusive],
    );
    return rows.map(TransactionModel.fromMap).toList(growable: false);
  }

  Future<ItemModel?> _findItemByBarcode(
    String normalizedBarcode, {
    int? excludingItemId,
  }) async {
    final rows = await _db.query(
      'items',
      where: excludingItemId == null
          ? 'barcode = ?'
          : 'barcode = ? AND itemId != ?',
      whereArgs: excludingItemId == null
          ? [normalizedBarcode]
          : [normalizedBarcode, excludingItemId],
      limit: 1,
    );
    return rows.isEmpty ? null : ItemModel.fromMap(rows.first);
  }

  double _sumTransactions(List<TransactionModel> transactions, {bool profit = false}) {
    return transactions.fold<double>(
      0,
      (sum, item) => sum + (profit ? item.totalProfit : item.totalAmount),
    );
  }

  int _startOfWeek() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday % 7));
    return start.millisecondsSinceEpoch;
  }

  int _startOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
  }

  int _startOfYear() {
    final now = DateTime.now();
    return DateTime(now.year, 1, 1).millisecondsSinceEpoch;
  }

  String _normalizeBarcode(String barcode) {
    return barcode.trim().replaceAll(' ', '').replaceAll('\n', '').replaceAll('\r', '');
  }
}

class _SampleItemSignature {
  const _SampleItemSignature(this.barcode, this.name, this.price, this.category);

  final String barcode;
  final String name;
  final double price;
  final String category;

  bool matches(ItemModel item) {
    return item.barcode == barcode &&
        item.name == name &&
        item.price == price &&
        item.category == category;
  }
}
