enum PriceSuggestionSource {
  existingAverage,
  costMarkup,
}

enum AddToCartResult {
  added,
  outOfStock,
  limitReached,
}

enum AppThemePreference {
  light,
  dark,
}

enum ReceiptPaperSize {
  mm58,
  mm80,
}

enum DashboardDateRangePreset {
  custom,
  last7Days,
  last14Days,
  last30Days,
  last90Days,
}

class ItemModel {
  const ItemModel({
    this.itemId = 0,
    this.barcode = '',
    this.name = '',
    this.price = 0,
    this.cost = 0,
    this.stock = 0,
    this.category = InventoryCategories.food,
    this.status = 'ACTIVE',
    this.createdAt = 0,
    this.lastModifiedAt = 0,
  });

  factory ItemModel.fromMap(Map<String, Object?> map) {
    return ItemModel(
      itemId: _asInt(map['itemId']),
      barcode: map['barcode'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: _asDouble(map['price']),
      cost: _asDouble(map['cost']),
      stock: _asInt(map['stock']),
      category: map['category'] as String? ?? InventoryCategories.food,
      status: map['status'] as String? ?? 'ACTIVE',
      createdAt: _asInt(map['createdAt']),
      lastModifiedAt: _asInt(map['lastModifiedAt']),
    );
  }

  final int itemId;
  final String barcode;
  final String name;
  final double price;
  final double cost;
  final int stock;
  final String category;
  final String status;
  final int createdAt;
  final int lastModifiedAt;

  bool get isActive => status == 'ACTIVE';

  ItemModel copyWith({
    int? itemId,
    String? barcode,
    String? name,
    double? price,
    double? cost,
    int? stock,
    String? category,
    String? status,
    int? createdAt,
    int? lastModifiedAt,
  }) {
    return ItemModel(
      itemId: itemId ?? this.itemId,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'itemId': itemId,
        'barcode': barcode,
        'name': name,
        'price': price,
        'cost': cost,
        'stock': stock,
        'category': category,
        'status': status,
        'createdAt': createdAt,
        'lastModifiedAt': lastModifiedAt,
      };
}

class TransactionModel {
  const TransactionModel({
    this.transactionId = 0,
    this.customerName,
    this.status = 'PAID',
    this.createdAt = 0,
    this.paidAt,
    this.totalAmount = 0,
    this.totalCost = 0,
    this.totalProfit = 0,
    this.paymentType = 'Cash',
    this.cashReceived,
    this.changeAmount = 0,
  });

  factory TransactionModel.fromMap(Map<String, Object?> map) {
    return TransactionModel(
      transactionId: _asInt(map['transactionId']),
      customerName: (map['customerName'] as String?)?.trim().isEmpty == true
          ? null
          : map['customerName'] as String?,
      status: map['status'] as String? ?? 'PAID',
      createdAt: _asInt(map['createdAt']),
      paidAt: map['paidAt'] == null ? null : _asInt(map['paidAt']),
      totalAmount: _asDouble(map['totalAmount']),
      totalCost: _asDouble(map['totalCost']),
      totalProfit: _asDouble(map['totalProfit']),
      paymentType: map['paymentType'] as String? ?? 'Cash',
      cashReceived: map['cashReceived'] == null ? null : _asDouble(map['cashReceived']),
      changeAmount: _asDouble(map['changeAmount']),
    );
  }

  final int transactionId;
  final String? customerName;
  final String status;
  final int createdAt;
  final int? paidAt;
  final double totalAmount;
  final double totalCost;
  final double totalProfit;
  final String paymentType;
  final double? cashReceived;
  final double changeAmount;

  Map<String, Object?> toMap() => {
        'transactionId': transactionId,
        'customerName': customerName,
        'status': status,
        'createdAt': createdAt,
        'paidAt': paidAt,
        'totalAmount': totalAmount,
        'totalCost': totalCost,
        'totalProfit': totalProfit,
        'paymentType': paymentType,
        'cashReceived': cashReceived,
        'changeAmount': changeAmount,
      };
}

class TransactionItemModel {
  const TransactionItemModel({
    this.id = 0,
    this.transactionId = 0,
    this.itemId = 0,
    this.itemName = '',
    this.quantity = 0,
    this.price = 0,
    this.cost = 0,
    this.subtotal = 0,
    this.costSubtotal = 0,
  });

  factory TransactionItemModel.fromMap(Map<String, Object?> map) {
    return TransactionItemModel(
      id: _asInt(map['id']),
      transactionId: _asInt(map['transactionId']),
      itemId: _asInt(map['itemId']),
      itemName: map['itemName'] as String? ?? '',
      quantity: _asInt(map['quantity']),
      price: _asDouble(map['price']),
      cost: _asDouble(map['cost']),
      subtotal: _asDouble(map['subtotal']),
      costSubtotal: _asDouble(map['costSubtotal']),
    );
  }

  final int id;
  final int transactionId;
  final int itemId;
  final String itemName;
  final int quantity;
  final double price;
  final double cost;
  final double subtotal;
  final double costSubtotal;

  Map<String, Object?> toMap() => {
        'id': id,
        'transactionId': transactionId,
        'itemId': itemId,
        'itemName': itemName,
        'quantity': quantity,
        'price': price,
        'cost': cost,
        'subtotal': subtotal,
        'costSubtotal': costSubtotal,
      };
}

class InventoryLogModel {
  const InventoryLogModel({
    this.id = 0,
    this.itemId = 0,
    this.changeType = 'SALE',
    this.quantity = 0,
    this.date = 0,
  });

  factory InventoryLogModel.fromMap(Map<String, Object?> map) {
    return InventoryLogModel(
      id: _asInt(map['id']),
      itemId: _asInt(map['itemId']),
      changeType: map['changeType'] as String? ?? 'SALE',
      quantity: _asInt(map['quantity']),
      date: _asInt(map['date']),
    );
  }

  final int id;
  final int itemId;
  final String changeType;
  final int quantity;
  final int date;

  Map<String, Object?> toMap() => {
        'id': id,
        'itemId': itemId,
        'changeType': changeType,
        'quantity': quantity,
        'date': date,
      };
}

class AppSettingsModel {
  const AppSettingsModel({
    this.storeName = 'TipidPOS',
    this.ownerName = '',
    this.contactNumber = '',
    this.storeAddress = '',
    this.receiptHeader = '',
    this.receiptFooter = 'Thank you! Come again!',
    this.lowStockThreshold = 5,
    this.autoPrintReceipt = false,
    this.preferredPrinterName = '',
    this.preferredPrinterAddress = '',
    this.soundEnabled = true,
    this.notificationsEnabled = true,
    this.themePreference = AppThemePreference.light,
    this.receiptPaperSize = ReceiptPaperSize.mm58,
    this.introSeen = false,
  });

  factory AppSettingsModel.fromMap(Map<Object?, Object?> map) {
    return AppSettingsModel(
      storeName: map['storeName'] as String? ?? 'TipidPOS',
      ownerName: map['ownerName'] as String? ?? '',
      contactNumber: map['contactNumber'] as String? ?? '',
      storeAddress: map['storeAddress'] as String? ?? '',
      receiptHeader: map['receiptHeader'] as String? ?? '',
      receiptFooter: map['receiptFooter'] as String? ?? 'Thank you! Come again!',
      lowStockThreshold: _asInt(map['lowStockThreshold'], fallback: 5),
      autoPrintReceipt: map['autoPrintReceipt'] as bool? ?? false,
      preferredPrinterName: map['preferredPrinterName'] as String? ?? '',
      preferredPrinterAddress: map['preferredPrinterAddress'] as String? ?? '',
      soundEnabled: map['soundEnabled'] as bool? ?? true,
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      themePreference: _themePreferenceFromValue(map['themePreference']),
      receiptPaperSize: _receiptPaperSizeFromValue(map['receiptPaperSize']),
      introSeen: map['introSeen'] as bool? ?? false,
    );
  }

  final String storeName;
  final String ownerName;
  final String contactNumber;
  final String storeAddress;
  final String receiptHeader;
  final String receiptFooter;
  final int lowStockThreshold;
  final bool autoPrintReceipt;
  final String preferredPrinterName;
  final String preferredPrinterAddress;
  final bool soundEnabled;
  final bool notificationsEnabled;
  final AppThemePreference themePreference;
  final ReceiptPaperSize receiptPaperSize;
  final bool introSeen;

  AppSettingsModel copyWith({
    String? storeName,
    String? ownerName,
    String? contactNumber,
    String? storeAddress,
    String? receiptHeader,
    String? receiptFooter,
    int? lowStockThreshold,
    bool? autoPrintReceipt,
    String? preferredPrinterName,
    String? preferredPrinterAddress,
    bool? soundEnabled,
    bool? notificationsEnabled,
    AppThemePreference? themePreference,
    ReceiptPaperSize? receiptPaperSize,
    bool? introSeen,
  }) {
    return AppSettingsModel(
      storeName: storeName ?? this.storeName,
      ownerName: ownerName ?? this.ownerName,
      contactNumber: contactNumber ?? this.contactNumber,
      storeAddress: storeAddress ?? this.storeAddress,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
      preferredPrinterName: preferredPrinterName ?? this.preferredPrinterName,
      preferredPrinterAddress: preferredPrinterAddress ?? this.preferredPrinterAddress,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themePreference: themePreference ?? this.themePreference,
      receiptPaperSize: receiptPaperSize ?? this.receiptPaperSize,
      introSeen: introSeen ?? this.introSeen,
    );
  }

  Map<String, Object?> toMap() => {
        'storeName': storeName,
        'ownerName': ownerName,
        'contactNumber': contactNumber,
        'storeAddress': storeAddress,
        'receiptHeader': receiptHeader,
        'receiptFooter': receiptFooter,
        'lowStockThreshold': lowStockThreshold,
        'autoPrintReceipt': autoPrintReceipt,
        'preferredPrinterName': preferredPrinterName,
        'preferredPrinterAddress': preferredPrinterAddress,
        'soundEnabled': soundEnabled,
        'notificationsEnabled': notificationsEnabled,
        'themePreference': themePreference.name,
        'receiptPaperSize': receiptPaperSize.name,
        'introSeen': introSeen,
      };
}

class CartItemData {
  const CartItemData({
    required this.itemId,
    required this.name,
    required this.price,
    required this.cost,
    required this.stock,
    this.quantity = 1,
  });

  final int itemId;
  final String name;
  final double price;
  final double cost;
  final int stock;
  final int quantity;

  CartItemData copyWith({
    int? itemId,
    String? name,
    double? price,
    double? cost,
    int? stock,
    int? quantity,
  }) {
    return CartItemData(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      quantity: quantity ?? this.quantity,
    );
  }
}

class TodayIncome {
  const TodayIncome({
    this.amount = 0,
    this.profit = 0,
    this.count = 0,
    this.topItem = 'N/A',
    this.topQty = 0,
  });

  final double amount;
  final double profit;
  final int count;
  final String topItem;
  final int topQty;
}

class DashboardDateRange {
  const DashboardDateRange({
    required this.start,
    required this.end,
    this.preset = DashboardDateRangePreset.custom,
  });

  final int start;
  final int end;
  final DashboardDateRangePreset preset;

  DashboardDateRange copyWith({
    int? start,
    int? end,
    DashboardDateRangePreset? preset,
  }) {
    return DashboardDateRange(
      start: start ?? this.start,
      end: end ?? this.end,
      preset: preset ?? this.preset,
    );
  }
}

class DashboardAnalyticsSummary {
  const DashboardAnalyticsSummary({
    this.sales = 0,
    this.profit = 0,
    this.transactionCount = 0,
    this.topItem = 'N/A',
    this.topQuantity = 0,
  });

  final double sales;
  final double profit;
  final int transactionCount;
  final String topItem;
  final int topQuantity;
}

class TopSeller {
  const TopSeller({
    required this.item,
    required this.totalSold,
  });

  final ItemModel item;
  final int totalSold;
}

class DailyIncome {
  const DailyIncome({
    required this.day,
    required this.amount,
  });

  final String day;
  final double amount;
}

class PriceSuggestion {
  const PriceSuggestion({
    required this.suggestedPrice,
    required this.source,
  });

  final double suggestedPrice;
  final PriceSuggestionSource source;
}

class PriceSuggestionUiState {
  const PriceSuggestionUiState({
    this.suggestedPrice = 0,
    this.appliedPrice = 0,
    this.cost = 0,
    this.profit = 0,
    this.hasSuggestion = false,
    this.source = PriceSuggestionSource.costMarkup,
  });

  final double suggestedPrice;
  final double appliedPrice;
  final double cost;
  final double profit;
  final bool hasSuggestion;
  final PriceSuggestionSource source;
}

class BackupSummary {
  const BackupSummary({
    required this.itemCount,
    required this.transactionCount,
    required this.transactionItemCount,
    required this.inventoryLogCount,
    required this.imageCount,
  });

  final int itemCount;
  final int transactionCount;
  final int transactionItemCount;
  final int inventoryLogCount;
  final int imageCount;
}

class PairedBluetoothPrinter {
  const PairedBluetoothPrinter({
    required this.name,
    required this.address,
  });

  factory PairedBluetoothPrinter.fromMap(Map<Object?, Object?> map) {
    return PairedBluetoothPrinter(
      name: map['name'] as String? ?? 'Bluetooth Printer',
      address: map['address'] as String? ?? '',
    );
  }

  final String name;
  final String address;
}

class AppSnackBarEvent {
  const AppSnackBarEvent({
    required this.id,
    required this.message,
  });

  final int id;
  final String message;
}

abstract final class InventoryCategories {
  static const String food = 'Food';
  static const String nonFood = 'Non-food';

  static List<String> get all => const [food, nonFood];

  static String normalize(String? rawCategory, {String fallback = food}) {
    final normalized = (rawCategory ?? '').trim().toLowerCase().replaceAll('_', ' ');
    switch (normalized) {
      case 'food':
      case 'foods':
      case 'staples':
      case 'canned goods':
      case 'snacks':
      case 'beverages':
      case 'condiments':
      case 'grocery':
      case 'groceries':
        return food;
      case 'non-food':
      case 'non food':
      case 'personal care':
      case 'household':
      case 'cleaning':
      case 'toiletries':
        return nonFood;
      default:
        return fallback == nonFood ? nonFood : food;
    }
  }
}

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

AppThemePreference _themePreferenceFromValue(Object? value) {
  final raw = (value as String?)?.trim().toLowerCase();
  switch (raw) {
    case 'dark':
      return AppThemePreference.dark;
    case 'light':
    default:
      return AppThemePreference.light;
  }
}

ReceiptPaperSize _receiptPaperSizeFromValue(Object? value) {
  final raw = (value as String?)?.trim().toLowerCase();
  switch (raw) {
    case 'mm80':
    case '80mm':
    case '80':
      return ReceiptPaperSize.mm80;
    case 'mm58':
    case '58mm':
    case '58':
    default:
      return ReceiptPaperSize.mm58;
  }
}
