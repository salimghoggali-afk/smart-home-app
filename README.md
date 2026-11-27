# My Home (smart home app)

Flutter 3 Android app that links at run time to a Firebase project (by QR code),
signs people in with email and password, and lets an installer configure the home
in the Realtime Database.

## Menu (v1.3)

- **Home**
- **Operator** (needs today's operator code): Configuration, Unlink the home
- **Settings** (needs the user's own password): Profile, Display
- **Sign out**

## Daily operator code (v2)

- One 8-digit code per day, the same in every home, valid only that day.
- Code = `HMAC-SHA256(master, "myhome-op-v2|<YYYY-MM-DD>")`, cut to 8 digits
  (RFC 4226 dynamic truncation). The day is the date in Algeria (UTC+1), from
  Firebase server time.
- The master key is **not** in this repository. The release build gets it as two
  random halves: `--dart-define-from-file=operator-key.json` (keys `OP_A`,
  `OP_B`, XOR gives the master). The file is kept with the signing key.
- A build without the file still runs, but the Operator menu says the app has
  no operator key.
- Salim and Karim read the code on the private "Operator Daily Code" page.
- Changing the key: make a new `operator-key.json`, release an update, and
  give the new master key to the code page. Old app versions keep the old key.
- Code: `lib/core/admin_lock.dart`, tests: `test/admin_lock_test.dart`.

## Home data (v1.6, lights)

Everything is a list, so the board finds things by number. Items are never
deleted: "Remove" in the app sets `archived: true`, so numbers never move.

```
homes/{h}: name, createdAt, createdBy, archived?
  floors/{f}: name, archived?
    lamps/{l}: name, order, state, locked, lockstate, mode, archived?
    rooms/{r}: name, type, archived?
      lamps/{i}: position        (1-based number of a lamp in floors/{f}/lamps)
      rooms/{s}: name, type, lamps/{i}/position   (one level of sub-rooms)
```

Lamp fields:
- `order` (app): `"none"`, then a number 0 to 100.
- `state` (board): 0 to 100, shown in the app as the light level.
- `locked` (app): `"none"`, then `true` (board ignores the wall switch) or `false`.
- `lockstate` (board): `true` or `false`, the lock the board applied.
- `mode` (app): `"switch"` (On / Off) or `"dimmer"`.

Shutters (`volets`) are not in the app yet.

## Database rules

Paste `database.rules.json` into Firebase console > Realtime Database > Rules.

## Build

```
flutter pub get
flutter test
flutter build apk --release --obfuscate --split-debug-info=build/debug-info \
  --dart-define-from-file=/path/to/operator-key.json
```

Release signing needs `android/key.properties` and the keystore, which are kept
outside the repository.
