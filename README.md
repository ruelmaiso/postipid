# TipidPOS Clean

Standalone Flutter app for Android.

## Open In VS Code

```powershell
cd C:\Users\Matilde\AndroidStudioProjects\tipidpos\pos_clean
code .
```

## Day-To-Day Commands

```powershell
flutter pub get
flutter run
```

## Build Commands

Debug/testing APK:

```powershell
flutter build apk
```

Release APK for direct install/testing:

```powershell
flutter build apk --release
```

Release Android App Bundle for Google Play upload:

```powershell
flutter build appbundle --release
```

## Output Files

- APK: `build\app\outputs\flutter-apk\app-release.apk`
- AAB: `build\app\outputs\bundle\release\app-release.aab`

## Publish Notes

- Active app path is only this `pos_clean` folder.
- Settings persistence is handled in Flutter with `shared_preferences`.
- Bluetooth receipt printing is handled in Flutter with `print_bluetooth_thermal`.
- Barcode scanning uses `mobile_scanner`.
- Minimum Android SDK is `24`.
- Pair your Bluetooth printer first in Android Bluetooth settings before selecting it in the app.

For Play publishing, prepare your own signing key:

1. Copy `android/key.properties.example` to `android/key.properties`
2. Replace the placeholder values with your real keystore path and passwords
3. Build the release AAB

If `android/key.properties` is missing, release builds fall back to debug signing for local testing only.
