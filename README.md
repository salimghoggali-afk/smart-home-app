# My Home (smart home app)

Flutter 3 Android app that links at run time to a Firebase project (by QR code),
signs people in with email and password, and lets an installer configure the home
in the Realtime Database.

## Menu (v1.3)

- **Home**
- **Operator** (needs today's operator code): Configuration, Unlink the home
- **Settings** (needs the user's own password): Profile, Display
- **Sign out**

## Daily operator code

- Each home has a random secret at `/operatorSecret` in the Realtime Database
  (base64, 32 bytes). The installer adds it with the Firebase console. The rules
  let only the owner account read it, and nobody write it from the app.
- Today's code = `HMAC-SHA256(secret, "myhome-op-v1|<projectId>|<YYYY-MM-DD>")`,
  cut to 8 digits (RFC 4226 dynamic truncation).
- The day is the date in Algeria (UTC+1), from Firebase server time, so a wrong
  phone clock does not matter.
- The installer gets today's code from the generator on the QR maker page.
- Code: `lib/core/admin_lock.dart`, tests: `test/admin_lock_test.dart`.

## Database rules

Paste `database.rules.json` into Firebase console > Realtime Database > Rules.

## Build

```
flutter pub get
flutter test
flutter build apk --release
```

Release signing needs `android/key.properties` and the keystore, which are kept
outside the repository.
