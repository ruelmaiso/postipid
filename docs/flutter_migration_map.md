# Flutter Migration Map

This project now targets a Flutter-first runtime. Android stays as a thin host for startup, DataStore-backed settings, and Bluetooth printer access.

## Shell And Navigation

| Legacy Android file/flow | Flutter replacement |
| --- | --- |
| `app/src/main/java/com/smartsarisari/pos/MainActivity.kt` | `lib/main.dart` + `lib/features/app/app_root.dart` + `lib/features/app/app_shell.dart` |
| `ui/navigation/MainDestination.kt` | `lib/features/app/app_controller.dart` (`AppSection`, `ActivitySection`) |
| `ui/navigation/MainNavigator.kt` | `Navigator` pushes from Flutter screens and controller-driven shell switching |
| `ui/base/BaseBindingFragment.kt` | Flutter widget tree |
| `ui/base/BasePosFragment.kt` | `TipidPosController` provided app-wide through `provider` |
| Drawer shell (`activity_main.xml`, `main_drawer_menu.xml`, `nav_header_main.xml`) | Modern bottom-navigation shell with an activity hub tab and full-screen feature routes |

## State And Domain

| Legacy Android file/flow | Flutter replacement |
| --- | --- |
| `ui/viewmodel/PosViewModel.kt` | `lib/features/app/app_controller.dart` |
| `data/repository/PosRepository.kt` | `lib/core/repository/pos_repository.dart` |
| `data/database/AppDatabase.kt` | `lib/core/services/local_database_service.dart` |
| `data/entity/*` | `lib/core/models/app_models.dart` |
| `ui/util/UiFormatters.kt` | `lib/core/utils/formatters.dart` |
| `ui/util/ReceiptFormatter.kt` | `lib/core/utils/receipt_formatter.dart` |

## Feature Screens

| Legacy Android file/flow | Flutter replacement |
| --- | --- |
| `ui/screens/dashboard/DashboardScreen.kt` + `fragment_dashboard.xml` | `lib/features/dashboard/dashboard_screen.dart` |
| `ui/screens/pos/PosScreen.kt` + `fragment_pos.xml` + `item_cart.xml` + `item_pos_search_result.xml` + `dialog_receipt_preview.xml` | `lib/features/pos/pos_screen.dart` |
| `ui/screens/inventory/InventoryScreen.kt` + `fragment_inventory.xml` + `item_inventory.xml` + `dialog_stock_in.xml` | `lib/features/inventory/inventory_screen.dart` |
| `ui/screens/inventory/AddItemScreen.kt` + `activity_add_item.xml` | `lib/features/inventory/item_editor_screen.dart` (create mode) |
| `ui/screens/inventory/EditItemScreen.kt` + `activity_edit_item.xml` + `edit_item_menu.xml` | `lib/features/inventory/item_editor_screen.dart` (edit mode) |
| `ui/screens/credits/CreditsScreen.kt` + `fragment_credits.xml` + `item_credit.xml` | `lib/features/credits/credits_screen.dart` |
| `ui/screens/transactions/TransactionsScreen.kt` + `fragment_transactions.xml` + `item_transaction.xml` | `lib/features/transactions/transactions_screen.dart` |
| `ui/screens/reports/ReportsScreen.kt` + `fragment_reports.xml` + `item_daily_income.xml` + `item_simple_line.xml` | `lib/features/reports/reports_screen.dart` |
| `ui/screens/settings/SettingsScreen.kt` + `fragment_settings.xml` | `lib/features/settings/settings_screen.dart` |
| `ui/manual/ManualActivity.kt` + `activity_manual.xml` | `lib/features/manual/manual_screen.dart` |
| `ui/onboarding/OnboardingActivity.kt` + `ui/onboarding/OnboardingAdapter.kt` + `activity_onboarding.xml` + `item_onboarding_page.xml` | `lib/features/onboarding/onboarding_screen.dart` |
| `ui/scanner/BarcodeScannerActivity.kt` + `activity_barcode_scanner.xml` | `lib/features/scanner/barcode_scanner_screen.dart` |

## Adapters To Flutter Lists

| Legacy Android file | Flutter replacement |
| --- | --- |
| `ui/adapter/CartAdapter.kt` | POS cart list in `lib/features/pos/pos_screen.dart` |
| `ui/adapter/PosSearchAdapter.kt` | POS search results list in `lib/features/pos/pos_screen.dart` |
| `ui/adapter/InventoryAdapter.kt` | inventory list in `lib/features/inventory/inventory_screen.dart` |
| `ui/adapter/CreditsAdapter.kt` | credits list in `lib/features/credits/credits_screen.dart` |
| `ui/adapter/TransactionsAdapter.kt` | transactions list in `lib/features/transactions/transactions_screen.dart` |
| `ui/adapter/DailyIncomeAdapter.kt` | reports trend list in `lib/features/reports/reports_screen.dart` |

## Native Pieces Intentionally Left On Android

| Native file | Reason |
| --- | --- |
| `app/src/main/java/com/smartsarisari/pos/MainActivity.kt` | Flutter host activity and method-channel bridge |
| `app/src/main/java/com/smartsarisari/pos/util/BluetoothPrinterManager.kt` | Classic Bluetooth printer discovery, permission handling, and ESC/POS text printing |
| `app/src/main/java/com/smartsarisari/pos/util/PreferencesManager.kt` | Existing DataStore preferences kept as the source of truth so installed-device settings survive the migration |
| `app/src/main/AndroidManifest.xml` | Android permissions, launcher entry, and Flutter host declaration |

## Legacy UI Resources Now Considered Obsolete

These files remain only as legacy resources for reference and compile safety. They are no longer the active runtime UI:

- All XML layouts under `app/src/main/res/layout/`
- `app/src/main/res/menu/main_drawer_menu.xml`
- `app/src/main/res/menu/edit_item_menu.xml`
- ViewBinding-based fragments, activities, adapters, and navigation classes listed above
