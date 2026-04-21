import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

class SettingsService {
  static const _storeNameKey = 'storeName';
  static const _ownerNameKey = 'ownerName';
  static const _contactNumberKey = 'contactNumber';
  static const _storeAddressKey = 'storeAddress';
  static const _receiptHeaderKey = 'receiptHeader';
  static const _receiptFooterKey = 'receiptFooter';
  static const _lowStockThresholdKey = 'lowStockThreshold';
  static const _autoPrintReceiptKey = 'autoPrintReceipt';
  static const _preferredPrinterNameKey = 'preferredPrinterName';
  static const _preferredPrinterAddressKey = 'preferredPrinterAddress';
  static const _soundEnabledKey = 'soundEnabled';
  static const _notificationsEnabledKey = 'notificationsEnabled';
  static const _themePreferenceKey = 'themePreference';
  static const _receiptPaperSizeKey = 'receiptPaperSize';
  static const _introSeenKey = 'introSeen';

  Future<AppSettingsModel> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettingsModel(
      storeName: prefs.getString(_storeNameKey) ?? 'TipidPOS',
      ownerName: prefs.getString(_ownerNameKey) ?? '',
      contactNumber: prefs.getString(_contactNumberKey) ?? '',
      storeAddress: prefs.getString(_storeAddressKey) ?? '',
      receiptHeader: prefs.getString(_receiptHeaderKey) ?? '',
      receiptFooter: prefs.getString(_receiptFooterKey) ?? 'Thank you! Come again!',
      lowStockThreshold: prefs.getInt(_lowStockThresholdKey) ?? 5,
      autoPrintReceipt: prefs.getBool(_autoPrintReceiptKey) ?? false,
      preferredPrinterName: prefs.getString(_preferredPrinterNameKey) ?? '',
      preferredPrinterAddress: prefs.getString(_preferredPrinterAddressKey) ?? '',
      soundEnabled: prefs.getBool(_soundEnabledKey) ?? true,
      notificationsEnabled: prefs.getBool(_notificationsEnabledKey) ?? true,
      themePreference: _themePreference(
        prefs.getString(_themePreferenceKey),
      ),
      receiptPaperSize: _receiptPaperSize(
        prefs.getString(_receiptPaperSizeKey),
      ),
      introSeen: prefs.getBool(_introSeenKey) ?? false,
    );
  }

  Future<void> save(AppSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeNameKey, settings.storeName);
    await prefs.setString(_ownerNameKey, settings.ownerName);
    await prefs.setString(_contactNumberKey, settings.contactNumber);
    await prefs.setString(_storeAddressKey, settings.storeAddress);
    await prefs.setString(_receiptHeaderKey, settings.receiptHeader);
    await prefs.setString(_receiptFooterKey, settings.receiptFooter);
    await prefs.setInt(_lowStockThresholdKey, settings.lowStockThreshold);
    await prefs.setBool(_autoPrintReceiptKey, settings.autoPrintReceipt);
    await prefs.setString(_preferredPrinterNameKey, settings.preferredPrinterName);
    await prefs.setString(_preferredPrinterAddressKey, settings.preferredPrinterAddress);
    await prefs.setBool(_soundEnabledKey, settings.soundEnabled);
    await prefs.setBool(_notificationsEnabledKey, settings.notificationsEnabled);
    await prefs.setString(_themePreferenceKey, settings.themePreference.name);
    await prefs.setString(_receiptPaperSizeKey, settings.receiptPaperSize.name);
    await prefs.setBool(_introSeenKey, settings.introSeen);
  }

  Future<void> markIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introSeenKey, true);
  }

  AppThemePreference _themePreference(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'dark':
        return AppThemePreference.dark;
      case 'light':
      default:
        return AppThemePreference.light;
    }
  }

  ReceiptPaperSize _receiptPaperSize(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
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
}
