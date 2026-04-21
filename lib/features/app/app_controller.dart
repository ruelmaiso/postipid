import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/models/app_models.dart';
import '../../core/repository/pos_repository.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/bluetooth_printer_service.dart';
import '../../core/services/image_storage_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/receipt_formatter.dart';

enum AppSection {
  dashboard,
  pos,
  inventory,
  activity,
  settings,
}

enum ActivitySection {
  credits,
  transactions,
  reports,
}

class TipidPosController extends ChangeNotifier {
  TipidPosController({
    required PosRepository repository,
    required SettingsService settingsService,
    required ImageStorageService imageStorageService,
    required BluetoothPrinterService bluetoothPrinterService,
    required BackupService backupService,
  })  : _repository = repository,
        _settingsService = settingsService,
        _imageStorageService = imageStorageService,
        _bluetoothPrinterService = bluetoothPrinterService,
        _backupService = backupService;

  final PosRepository _repository;
  final SettingsService _settingsService;
  final ImageStorageService _imageStorageService;
  final BluetoothPrinterService _bluetoothPrinterService;
  final BackupService _backupService;

  bool _initialized = false;
  String? _bootstrapError;
  AppSettingsModel _settings = const AppSettingsModel();
  AppSection _section = AppSection.dashboard;
  ActivitySection _activitySection = ActivitySection.credits;
  List<ItemModel> _allItems = const [];
  List<TransactionModel> _allTransactions = const [];
  List<TransactionModel> _pendingCredits = const [];
  List<CartItemData> _cart = const [];
  List<ItemModel> _searchResults = const [];
  TodayIncome _todayIncome = const TodayIncome();
  List<ItemModel> _lowStockItems = const [];
  List<ItemModel> _outOfStockItems = const [];
  double _weeklyIncome = 0;
  double _monthlyIncome = 0;
  double _weeklyProfit = 0;
  double _monthlyProfit = 0;
  double _yearlyIncome = 0;
  List<TopSeller> _topSellers = const [];
  List<DailyIncome> _dailyChart = const [];
  DashboardDateRange _dashboardDateRange = _initialDashboardDateRange();
  DashboardAnalyticsSummary _dashboardAnalytics =
      const DashboardAnalyticsSummary();
  List<DailyIncome> _dashboardChart = const [];
  List<TopSeller> _dashboardTopSellers = const [];
  List<PairedBluetoothPrinter> _pairedPrinters = const [];
  AppSnackBarEvent? _snackBarEvent;
  int _snackBarSequence = 0;

  bool get initialized => _initialized;
  String? get bootstrapError => _bootstrapError;
  AppSettingsModel get settings => _settings;
  AppSection get section => _section;
  ActivitySection get activitySection => _activitySection;
  List<ItemModel> get allItems => _allItems;
  List<TransactionModel> get allTransactions => _allTransactions;
  List<TransactionModel> get pendingCredits => _pendingCredits;
  List<CartItemData> get cart => _cart;
  List<ItemModel> get searchResults => _searchResults;
  TodayIncome get todayIncome => _todayIncome;
  List<ItemModel> get lowStockItems => _lowStockItems;
  List<ItemModel> get outOfStockItems => _outOfStockItems;
  double get weeklyIncome => _weeklyIncome;
  double get monthlyIncome => _monthlyIncome;
  double get weeklyProfit => _weeklyProfit;
  double get monthlyProfit => _monthlyProfit;
  double get yearlyIncome => _yearlyIncome;
  List<TopSeller> get topSellers => _topSellers;
  List<DailyIncome> get dailyChart => _dailyChart;
  DashboardDateRange get dashboardDateRange => _dashboardDateRange;
  DashboardAnalyticsSummary get dashboardAnalytics => _dashboardAnalytics;
  List<DailyIncome> get dashboardChart => _dashboardChart;
  List<TopSeller> get dashboardTopSellers => _dashboardTopSellers;
  List<PairedBluetoothPrinter> get pairedPrinters => _pairedPrinters;
  AppSnackBarEvent? get snackBarEvent => _snackBarEvent;
  ThemeMode get themeMode => _settings.themePreference == AppThemePreference.dark
      ? ThemeMode.dark
      : ThemeMode.light;

  double get cartTotal => _cart.fold<double>(0, (sum, item) => sum + item.price * item.quantity);
  int get cartItemCount => _cart.fold<int>(0, (sum, item) => sum + item.quantity);

  Future<void> bootstrap() async {
    _initialized = false;
    _bootstrapError = null;
    notifyListeners();
    try {
      _settings = await _settingsService.load();
      await _repository.removeLegacySeedDataIfNeeded();
      await refreshAll();
    } catch (error, stackTrace) {
      debugPrint('TipidPOS bootstrap failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _bootstrapError = error.toString();
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    _allItems = await _repository.getAllItems();
    _allTransactions = await _repository.getAllTransactions();
    _pendingCredits = await _repository.getPendingCredits();
    _todayIncome = await _repository.getTodayIncome();
    _weeklyIncome = await _repository.getWeeklyIncome();
    _monthlyIncome = await _repository.getMonthlyIncome();
    _weeklyProfit = await _repository.getWeeklyProfit();
    _monthlyProfit = await _repository.getMonthlyProfit();
    _yearlyIncome = await _repository.getYearlyIncome();
    _topSellers = await _repository.getTopSellers();
    _dailyChart = await _repository.getDailyIncomeForChart();
    _lowStockItems = await _repository.getLowStockItems(_settings.lowStockThreshold);
    _outOfStockItems = await _repository.getOutOfStockItems();
    await _refreshDashboardAnalytics(notify: false);
    notifyListeners();
  }

  void setSection(AppSection section) {
    _section = section;
    notifyListeners();
  }

  void openNewTransaction() {
    _section = AppSection.pos;
    notifyListeners();
  }

  void openActivity(ActivitySection section) {
    _section = AppSection.activity;
    _activitySection = section;
    notifyListeners();
  }

  void consumeSnackBar() {
    _snackBarEvent = null;
  }

  void showMessage(String message) {
    if (message.trim().isEmpty) {
      return;
    }
    _snackBarSequence += 1;
    _snackBarEvent = AppSnackBarEvent(id: _snackBarSequence, message: message);
    notifyListeners();
  }

  Future<void> searchItems(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = const [];
      notifyListeners();
      return;
    }
    _searchResults = await _repository.searchItems(query);
    notifyListeners();
  }

  void clearSearchResults() {
    _searchResults = const [];
    notifyListeners();
  }

  Future<void> updateDashboardDateRange(DashboardDateRange range) async {
    _dashboardDateRange = _normalizeDashboardDateRange(range);
    await _refreshDashboardAnalytics(notify: false);
    notifyListeners();
  }

  AddToCartResult addToCart(ItemModel item) {
    final current = _cart.toList(growable: true);
    final index = current.indexWhere((entry) => entry.itemId == item.itemId);
    if (index >= 0) {
      final existing = current[index];
      if (existing.quantity >= item.stock) {
        return AddToCartResult.limitReached;
      }
      current[index] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      if (item.stock <= 0) {
        return AddToCartResult.outOfStock;
      }
      current.add(
        CartItemData(
          itemId: item.itemId,
          name: item.name,
          price: item.price,
          cost: item.cost,
          stock: item.stock,
        ),
      );
    }
    _cart = current;
    notifyListeners();
    return AddToCartResult.added;
  }

  void updateCartQuantity(int itemId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(itemId);
      return;
    }
    _cart = _cart
        .map(
          (item) => item.itemId == itemId
              ? item.copyWith(quantity: quantity.clamp(1, item.stock).toInt())
              : item,
        )
        .toList(growable: false);
    notifyListeners();
  }

  void removeFromCart(int itemId) {
    _cart = _cart.where((item) => item.itemId != itemId).toList(growable: false);
    notifyListeners();
  }

  void clearCart() {
    _cart = const [];
    notifyListeners();
  }

  Future<String?> checkoutCash({
    String? customerName,
    required double cashReceived,
  }) async {
    if (_cart.isEmpty) {
      showMessage('Cart is empty');
      return null;
    }
    if (cashReceived < cartTotal) {
      showMessage('Cash amount is less than the total');
      return null;
    }

    final transaction = await _repository.createTransaction(
      customerName: customerName?.trim().isEmpty == true ? null : customerName?.trim(),
      paymentType: 'Cash',
      cartItems: _cart,
      cashReceived: cashReceived,
    );
    final receipt = await buildReceiptForTransaction(transaction);
    _cart = const [];
    await refreshAll();
    showMessage('Payment successful');
    return receipt;
  }

  Future<String?> checkoutCredit({required String customerName}) async {
    if (_cart.isEmpty) {
      showMessage('Cart is empty');
      return null;
    }
    if (customerName.trim().isEmpty) {
      showMessage('Customer name is required for credit');
      return null;
    }

    final transaction = await _repository.createTransaction(
      customerName: customerName.trim(),
      paymentType: 'Credit',
      cartItems: _cart,
    );
    final receipt = await buildReceiptForTransaction(transaction);
    _cart = const [];
    await refreshAll();
    showMessage('Credit transaction recorded');
    return receipt;
  }

  Future<void> settleCredit(int transactionId) async {
    await _repository.settleCredit(transactionId);
    await refreshAll();
    showMessage('Credit settled successfully');
  }

  Future<void> findAndAddToCartByBarcode(String barcode) async {
    final item = await _repository.getItemByBarcode(barcode);
    if (item == null) {
      showMessage('No item found for barcode: $barcode');
      return;
    }
    if (!item.isActive) {
      showMessage('${item.name} is no longer active');
      return;
    }
    final result = addToCart(item);
    switch (result) {
      case AddToCartResult.added:
        showMessage('${item.name} added to cart');
      case AddToCartResult.outOfStock:
        showMessage('${item.name} is out of stock');
      case AddToCartResult.limitReached:
        showMessage('No more stock available for ${item.name}');
    }
  }

  Future<PriceSuggestionUiState> computePriceSuggestion({
    required String itemName,
    required String costText,
    String? currentPriceText,
    required bool allowAutoFillPrice,
  }) async {
    final parsedCost = double.tryParse(costText);
    final currentPrice = double.tryParse(currentPriceText ?? '') ?? 0;
    if (parsedCost == null || parsedCost < 0) {
      return PriceSuggestionUiState(
        appliedPrice: currentPrice,
        cost: parsedCost ?? 0,
        profit: currentPrice - (parsedCost ?? 0),
        hasSuggestion: false,
      );
    }

    final suggestion = await _repository.suggestPrice(itemName, parsedCost);
    final appliedPrice =
        (allowAutoFillPrice || currentPrice <= 0) ? suggestion.suggestedPrice : currentPrice;
    return PriceSuggestionUiState(
      suggestedPrice: suggestion.suggestedPrice,
      appliedPrice: appliedPrice,
      cost: parsedCost,
      profit: appliedPrice - parsedCost,
      hasSuggestion: true,
      source: suggestion.source,
    );
  }

  Future<ItemModel?> getItemById(int itemId) => _repository.getItemById(itemId);

  Future<ItemModel?> getItemByBarcode(String barcode) => _repository.getItemByBarcode(barcode);

  Future<String> buildReceiptForTransaction(TransactionModel transaction) async {
    final items = await _repository.getTransactionItems(transaction.transactionId);
    return ReceiptFormatter.format(_settings, transaction, items);
  }

  Future<void> printReceipt(String receiptText) async {
    if (_settings.preferredPrinterAddress.trim().isEmpty) {
      showMessage('Select a Bluetooth printer in Settings first');
      return;
    }

    try {
      final hasPermission = await _bluetoothPrinterService.ensurePermission();
      if (!hasPermission) {
        showMessage('Bluetooth permission is required to print');
        return;
      }

      await _bluetoothPrinterService.printText(
        printerAddress: _settings.preferredPrinterAddress,
        text: receiptText,
      );
      showMessage('Receipt sent to printer');
    } catch (error) {
      showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> refreshPairedPrinters() async {
    try {
      final hasPermission = await _bluetoothPrinterService.ensurePermission();
      if (!hasPermission) {
        showMessage('Bluetooth permission is required to access printers');
        return;
      }
      _pairedPrinters = await _bluetoothPrinterService.getPairedPrinters();
      notifyListeners();
    } catch (error) {
      showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> saveSettings(AppSettingsModel settings) async {
    _settings = settings;
    await _settingsService.save(settings);
    _lowStockItems = await _repository.getLowStockItems(settings.lowStockThreshold);
    notifyListeners();
  }

  Future<void> updateThemePreference(AppThemePreference preference) async {
    await saveSettings(_settings.copyWith(themePreference: preference));
  }

  Future<void> updateReceiptPaperSize(ReceiptPaperSize size) async {
    await saveSettings(_settings.copyWith(receiptPaperSize: size));
  }

  Future<void> selectPrinter(PairedBluetoothPrinter printer) async {
    await saveSettings(
      _settings.copyWith(
        preferredPrinterName: printer.name,
        preferredPrinterAddress: printer.address,
      ),
    );
  }

  Future<void> clearPrinterSelection() async {
    await saveSettings(
      _settings.copyWith(
        preferredPrinterName: '',
        preferredPrinterAddress: '',
      ),
    );
  }

  Future<void> completeOnboarding() async {
    final updated = _settings.copyWith(introSeen: true);
    _settings = updated;
    await _settingsService.save(updated);
    await _settingsService.markIntroSeen();
    notifyListeners();
  }

  Future<ItemModel?> saveNewItem({
    required String name,
    required double price,
    required double cost,
    required int stock,
    required String category,
    required String barcode,
    String? imagePath,
  }) async {
    final item = await _repository.addItem(
      name: name,
      price: price,
      cost: cost,
      stock: stock,
      category: category,
      barcode: barcode,
    );
    if (imagePath != null && imagePath.isNotEmpty) {
      await _imageStorageService.saveImageForItem(item.itemId, imagePath);
    }
    await refreshAll();
    showMessage('Item saved successfully');
    return item;
  }

  Future<void> updateItem({
    required int itemId,
    required String name,
    required double price,
    required double cost,
    required String category,
    required String barcode,
    String? imagePath,
    bool removePhoto = false,
  }) async {
    await _repository.updateItem(
      itemId: itemId,
      name: name,
      price: price,
      cost: cost,
      category: category,
      barcode: barcode,
    );
    if (removePhoto) {
      await _imageStorageService.deleteImageForItem(itemId);
    } else if (imagePath != null && imagePath.isNotEmpty) {
      await _imageStorageService.saveImageForItem(itemId, imagePath);
    }
    await refreshAll();
    showMessage('Item updated successfully');
  }

  Future<void> deactivateItem(int itemId) async {
    await _repository.deactivateItem(itemId);
    await refreshAll();
    showMessage('Item deactivated');
  }

  Future<void> activateItem(int itemId) async {
    await _repository.activateItem(itemId);
    await refreshAll();
    showMessage('Item activated');
  }

  Future<void> deleteInactiveItem(int itemId) async {
    await _repository.deleteInactiveItem(itemId);
    await _imageStorageService.deleteImageForItem(itemId);
    _cart = _cart.where((item) => item.itemId != itemId).toList(growable: false);
    _searchResults = _searchResults
        .where((item) => item.itemId != itemId)
        .toList(growable: false);
    await refreshAll();
    showMessage('Item deleted permanently');
  }

  Future<void> stockIn(int itemId, int quantity) async {
    await _repository.stockIn(itemId, quantity);
    await refreshAll();
    showMessage('Stock updated');
  }

  Future<String?> imagePathForItem(int itemId) => _imageStorageService.existingImagePath(itemId);

  Future<BackupSummary?> exportBackup(String directoryPath) async {
    final summary = await _backupService.exportToDirectory(directoryPath);
    showMessage('Backup exported: ${summary.itemCount} items');
    return summary;
  }

  Future<BackupSummary?> importBackup(String filePath) async {
    final summary = await _backupService.importFromFile(filePath);
    _settings = await _settingsService.load();
    await refreshAll();
    showMessage('Backup imported: ${summary.itemCount} items');
    return summary;
  }

  Future<void> clearAllData() async {
    await _repository.clearAllData();
    await _imageStorageService.clearAllImages();
    clearCart();
    await refreshAll();
    showMessage('Data cleared');
  }

  Future<File?> imageFileForItem(int itemId) async {
    final imagePath = await imagePathForItem(itemId);
    if (imagePath == null) {
      return null;
    }
    return File(imagePath);
  }

  Future<void> _refreshDashboardAnalytics({bool notify = true}) async {
    final range = _normalizeDashboardDateRange(_dashboardDateRange);
    _dashboardDateRange = range;
    _dashboardAnalytics = await _repository.getDashboardAnalyticsSummary(
      start: range.start,
      end: range.end,
    );
    _dashboardChart = await _repository.getDailyIncomeForDateRange(
      start: range.start,
      end: range.end,
    );
    _dashboardTopSellers = await _repository.getTopSellersForRange(
      start: range.start,
      end: range.end,
      limit: 4,
    );
    if (notify) {
      notifyListeners();
    }
  }

  DashboardDateRange _normalizeDashboardDateRange(DashboardDateRange range) {
    final today = startOfDay(DateTime.now().millisecondsSinceEpoch);
    var start = startOfDay(range.start);
    var end = startOfDay(range.end);

    if (start > today) {
      start = today;
    }
    if (end > today) {
      end = today;
    }
    if (start > end) {
      final previousStart = start;
      start = end;
      end = previousStart;
    }

    return DashboardDateRange(
      start: start,
      end: end,
      preset: range.preset,
    );
  }

  static DashboardDateRange _initialDashboardDateRange() {
    final today = startOfDay(DateTime.now().millisecondsSinceEpoch);
    return DashboardDateRange(
      start: plusDays(today, -6),
      end: today,
      preset: DashboardDateRangePreset.last7Days,
    );
  }
}
