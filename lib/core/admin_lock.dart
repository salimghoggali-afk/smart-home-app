import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// The configuration code that protects the Configuration menu, and the
/// re-check of the user's own password that protects Settings.
///
/// The configuration code belongs to the installer, not to the users. It is
/// never stored in the app. The installer puts one string at `/admin` with the
/// Firebase console, in the form `pbkdf2-sha256$<rounds>$<salt b64>$<hash b64>`
/// (the QR maker page makes it). The rules let nobody write it from the app.
/// `/adminContact` holds the text shown on the lock screen.
/// An unlock lasts a few minutes, then the menu locks again.
class AdminLock {
  AdminLock({FirebaseDatabase? db, FirebaseAuth? auth})
      : _dbOverride = db,
        _authOverride = auth;

  final FirebaseDatabase? _dbOverride;
  final FirebaseAuth? _authOverride;
  FirebaseDatabase get _db => _dbOverride ?? FirebaseDatabase.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  static const unlockFor = Duration(minutes: 5);
  static const defaultRounds = 210000;
  static const defaultContact =
      'To get the configuration code, contact Mr. Salim GHOGGALI '
      '(+213 665 98 09 64) or Mr. Karim HADDAD (+213 674 43 45 78).';

  DateTime? _adminUntil;
  DateTime? _settingsUntil;

  bool get adminUnlocked =>
      _adminUntil != null && DateTime.now().isBefore(_adminUntil!);
  bool get settingsUnlocked =>
      _settingsUntil != null && DateTime.now().isBefore(_settingsUntil!);

  void lockAll() {
    _adminUntil = null;
    _settingsUntil = null;
  }

  /// Whether a code is set for this home, and the contact text to show.
  Future<({bool hasCode, String contact})> lockInfo() async {
    var contact = defaultContact;
    var hasCode = false;
    try {
      final c = await _db.ref('adminContact').get();
      final cv = c.value;
      if (cv is String && cv.trim().isNotEmpty) contact = cv.trim();
      final a = await _db.ref('admin').get();
      hasCode = parseRecord(a.value) != null;
    } catch (_) {}
    return (hasCode: hasCode, contact: contact);
  }

  /// Checks the configuration code. On success the Configuration menu unlocks.
  Future<bool> unlockAdmin(String code) async {
    final snap = await _db.ref('admin').get();
    final v = snap.value;
    if (v is! String) return false;
    final ok = await verify(code, v);
    if (ok) _adminUntil = DateTime.now().add(unlockFor);
    return ok;
  }

  /// Re-checks the signed-in user's own password with Firebase.
  Future<bool> unlockSettings(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return false;
    try {
      await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: password));
      _settingsUntil = DateTime.now().add(unlockFor);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'user-mismatch') {
        return false;
      }
      rethrow;
    }
  }

  /// Changes the user's own password. Needs a recent unlock of Settings.
  Future<void> changeOwnPassword(String newPassword) =>
      _auth.currentUser!.updatePassword(newPassword);

  // ---- Record format ----

  static const _sep = r'$';

  static ({int rounds, List<int> salt, List<int> hash})? parseRecord(Object? v) {
    if (v is! String) return null;
    final parts = v.trim().split(_sep);
    if (parts.length != 4 || parts[0] != 'pbkdf2-sha256') return null;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds < 10000) return null;
    try {
      return (
        rounds: rounds,
        salt: base64Decode(parts[2]),
        hash: base64Decode(parts[3]),
      );
    } catch (_) {
      return null;
    }
  }

  /// Makes the string stored at `/admin` for a code. The installer normally
  /// makes it with the QR maker page; this is used by the tests.
  static Future<String> makeRecord(String code,
      {List<int>? salt, int rounds = defaultRounds}) async {
    final s = salt ?? _randomBytes(16);
    final h = await _derive(code, s, rounds);
    return ['pbkdf2-sha256', '$rounds', base64Encode(s), base64Encode(h)]
        .join(_sep);
  }

  /// Checks a code against a stored record string.
  static Future<bool> verify(String code, String record) async {
    final rec = parseRecord(record);
    if (rec == null) return false;
    final actual = await _derive(code, rec.salt, rec.rounds);
    return _sameBytes(actual, rec.hash);
  }

  static Future<List<int>> _derive(
      String code, List<int> salt, int rounds) async {
    final algo = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: rounds,
      bits: 256,
    );
    final key = await algo.deriveKeyFromPassword(password: code, nonce: salt);
    return key.extractBytes();
  }

  static List<int> _randomBytes(int n) {
    final r = Random.secure();
    return List<int>.generate(n, (_) => r.nextInt(256));
  }

  // Compares in constant time, so timing does not leak how close a guess was.
  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
