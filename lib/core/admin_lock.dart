import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Locks for the Operator menu (daily operator code) and the Settings menu
/// (the user's own password).
///
/// Daily operator code:
/// - Each home has a random secret at `/operatorSecret` (base64, 32 bytes),
///   added by the installer with the Firebase console. The rules let only the
///   owner's account read it and nobody write it from the app.
/// - Today's code = `HMAC-SHA256(secret, "myhome-op-v1|projectId|YYYY-MM-DD")`,
///   cut to 8 digits the same way authenticator apps do (RFC 4226).
/// - The day is the date in Algeria (UTC+1, no daylight saving), taken from
///   Firebase server time, so a wrong phone clock does not matter.
/// - The installer gets the code from the generator on the QR maker page.
class AdminLock {
  AdminLock({FirebaseDatabase? db, FirebaseAuth? auth})
      : _dbOverride = db,
        _authOverride = auth;

  final FirebaseDatabase? _dbOverride;
  final FirebaseAuth? _authOverride;
  FirebaseDatabase get _db => _dbOverride ?? FirebaseDatabase.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  static const unlockFor = Duration(minutes: 5);
  static const digits = 8;
  static const defaultContact =
      'To get today\'s operator code, contact Mr. Salim GHOGGALI '
      '(+213 665 98 09 64) or Mr. Karim HADDAD (+213 674 43 45 78).';

  DateTime? _operatorUntil;
  DateTime? _settingsUntil;

  bool get operatorUnlocked =>
      _operatorUntil != null && DateTime.now().isBefore(_operatorUntil!);
  bool get settingsUnlocked =>
      _settingsUntil != null && DateTime.now().isBefore(_settingsUntil!);

  void lockAll() {
    _operatorUntil = null;
    _settingsUntil = null;
  }

  /// The contact text, and whether this account can check operator codes.
  Future<({bool ready, String contact, String? problem})> operatorInfo() async {
    var contact = defaultContact;
    try {
      final c = await _db.ref('adminContact').get();
      final cv = c.value;
      if (cv is String && cv.trim().isNotEmpty) contact = cv.trim();
    } catch (_) {}
    try {
      final s = await _db.ref('operatorSecret').get();
      if (_decodeSecret(s.value) == null) {
        return (
          ready: false,
          contact: contact,
          problem: 'No operator secret is set for this home yet.'
        );
      }
      return (ready: true, contact: contact, problem: null);
    } catch (_) {
      return (
        ready: false,
        contact: contact,
        problem: 'Operator tools open only on the owner\'s account. '
            'Sign in with the owner account on this phone.'
      );
    }
  }

  /// Checks today's operator code. On success the Operator menu unlocks.
  Future<bool> unlockOperator(String code, String projectId) async {
    final snap = await _db.ref('operatorSecret').get();
    final secret = _decodeSecret(snap.value);
    if (secret == null) return false;
    final day = algeriaDay(await serverNow());
    final expected = await codeFor(secret, projectId, day);
    final ok = _sameText(expected, code.replaceAll(RegExp(r'\s'), ''));
    if (ok) _operatorUntil = DateTime.now().add(unlockFor);
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

  Future<void> changeOwnPassword(String newPassword) =>
      _auth.currentUser!.updatePassword(newPassword);

  /// Current time corrected with the Firebase server clock.
  Future<DateTime> serverNow() async {
    try {
      final snap = await _db.ref('.info/serverTimeOffset').get();
      final offset = (snap.value as num?)?.toInt() ?? 0;
      return DateTime.now().toUtc().add(Duration(milliseconds: offset));
    } catch (_) {
      return DateTime.now().toUtc();
    }
  }

  // ---- Pure functions, shared with the generator page and the tests ----

  /// The date in Algeria (UTC+1 all year) as YYYY-MM-DD.
  static String algeriaDay(DateTime nowUtc) {
    final d = nowUtc.toUtc().add(const Duration(hours: 1));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  /// The 8-digit code for one home on one day.
  static Future<String> codeFor(
      List<int> secret, String projectId, String day) async {
    final mac = await Hmac.sha256().calculateMac(
      utf8.encode('myhome-op-v1|$projectId|$day'),
      secretKey: SecretKey(secret),
    );
    final h = mac.bytes;
    final o = h[h.length - 1] & 0x0f;
    final bin = ((h[o] & 0x7f) << 24) |
        (h[o + 1] << 16) |
        (h[o + 2] << 8) |
        h[o + 3];
    var mod = 1;
    for (var i = 0; i < digits; i++) {
      mod *= 10;
    }
    return (bin % mod).toString().padLeft(digits, '0');
  }

  static List<int>? _decodeSecret(Object? v) {
    if (v is! String) return null;
    try {
      final b = base64Decode(v.trim());
      return b.length >= 16 ? b : null;
    } catch (_) {
      return null;
    }
  }

  // Compares in constant time.
  static bool _sameText(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
