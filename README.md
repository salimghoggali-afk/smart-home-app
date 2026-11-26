# My Home

Smart home control app (Flutter, Android first).

The original 2022 code is kept untouched on the `reference` branch.

## What this version does

- Animated splash screen.
- Start screen that links the app to **any Firebase project at runtime**. Nothing is baked into the build: there is no `google-services.json`.
  - Scan a link QR code, or enter the details by hand, or paste a whole `google-services.json`.
  - The details are checked (format, then an online check of the API key) before they are saved.
  - Saved with `flutter_secure_storage`. Later launches skip setup.
  - "Unlink project" goes back to the start screen.

## Link QR code format

The QR code holds JSON:

```json
{
  "v": 1,
  "apiKey": "AIza...",
  "appId": "1:1234567890:android:abc123",
  "projectId": "my-home-1234",
  "messagingSenderId": "1234567890",
  "databaseURL": "https://my-home-1234-default-rtdb.firebaseio.com",
  "storageBucket": "my-home-1234.appspot.com",
  "webClientId": "1234-xxxx.apps.googleusercontent.com"
}
```

`databaseURL`, `storageBucket` and `webClientId` are optional. A full `google-services.json` also works as QR content or pasted text.

### Firebase project setup (by hand, once per home)

1. Create the project in the Firebase console.
2. Add an Android app with package name `com.ghoggalisalim.smarthome`.
3. Turn on Authentication and Realtime Database.
4. For Google Sign-In later: add the SHA-1 of the signing key to that Android app.

## Build

Flutter 3.50 (stable), Android SDK 36, JDK 21.

```sh
flutter pub get
flutter test
flutter build apk --release
```

Release signing reads `android/key.properties` and the keystore it points to. Both are kept out of git. Without them, the release build is signed with the debug key.
