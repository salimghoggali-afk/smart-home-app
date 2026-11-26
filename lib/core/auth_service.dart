import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// What the signed-in person may do in this home.
enum AccessLevel { owner, member, none }

/// Email and password sign-in, plus the "first account is the owner" rule.
///
/// The owner's uid is stored at `/owner` in the Realtime Database. The rules
/// let anyone read it, but only write it once, and only with their own uid.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseDatabase? db})
      : _authOverride = auth,
        _dbOverride = db;

  final FirebaseAuth? _authOverride;
  final FirebaseDatabase? _dbOverride;

  // Firebase is started at runtime, so look the instances up when used.
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseDatabase get _db => _dbOverride ?? FirebaseDatabase.instance;

  Stream<User?> get userChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// True when nobody has claimed the home yet.
  Future<bool> hasOwner() async {
    final snap = await _db.ref('owner').get();
    return snap.exists && snap.value != null;
  }

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  // Set while a new account is being set up, so the home screen waits for
  // the owner claim before it checks access.
  Future<AccessLevel>? _pendingRegistration;

  /// Creates an account. The first account ever becomes the owner.
  Future<AccessLevel> register(String email, String password) {
    final f = _register(email, password);
    _pendingRegistration = f;
    return f.whenComplete(() => _pendingRegistration = null);
  }

  Future<AccessLevel> _register(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final user = cred.user!;
    final ownerRef = _db.ref('owner');
    var isOwner = false;
    final existing = await ownerRef.get();
    if (!existing.exists || existing.value == null) {
      try {
        await ownerRef.set(user.uid);
        isOwner = true;
      } catch (_) {
        // Someone else claimed it at the same moment: the rules refuse us.
      }
    }
    await _db.ref('users/${user.uid}').set({
      'email': user.email,
      'role': isOwner ? 'owner' : 'member',
      'createdAt': ServerValue.timestamp,
    });
    return isOwner ? AccessLevel.owner : AccessLevel.none;
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

  /// Reads the access level of the signed-in person.
  Future<AccessLevel> accessLevel() async {
    final pending = _pendingRegistration;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {}
    }
    final user = _auth.currentUser;
    if (user == null) return AccessLevel.none;
    final owner = await _db.ref('owner').get();
    if (owner.value == user.uid) return AccessLevel.owner;
    try {
      final member = await _db.ref('members/${user.uid}').get();
      if (member.value == true) return AccessLevel.member;
    } catch (_) {}
    return AccessLevel.none;
  }

  /// Turns Firebase error codes into plain words.
  static String message(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'This email address is not valid.';
        case 'user-disabled':
          return 'This account is turned off.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'The email or password is wrong.';
        case 'email-already-in-use':
          return 'An account with this email already exists. Sign in instead.';
        case 'weak-password':
          return 'The password is too weak. Use at least 8 characters.';
        case 'operation-not-allowed':
          return 'Email sign-in is not turned on in this Firebase project. '
              'Turn it on in Authentication > Sign-in method.';
        case 'network-request-failed':
          return 'No internet connection.';
        case 'too-many-requests':
          return 'Too many tries. Please wait a moment.';
      }
      return e.message ?? 'Sign-in failed (${e.code}).';
    }
    if (e is FirebaseException && e.code == 'permission-denied') {
      return 'The database refused access. Check the database rules.';
    }
    if (e is FirebaseException) {
      return 'Firebase error (${e.code}): ${e.message ?? ''}';
    }
    final t = e.toString();
    return 'Something went wrong: ${t.length > 160 ? t.substring(0, 160) : t}';
  }
}
