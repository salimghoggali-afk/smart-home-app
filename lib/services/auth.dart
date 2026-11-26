import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_home/models/user.dart';

import 'database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String email;
  String password;

  // auth change user stream
  Stream<AppUser> get user {
    return _auth
        .authStateChanges()
        .map((User user) => _fromUserToAppUser(user));
  }

  // form User To App User

  AppUser _fromUserToAppUser(User user) {
    if (user != null) {
      var usr = AppUser(user);
      DataBaseService(uid: usr.uid).getUserData(usr);
      DataBaseService(uid: usr.uid).getUserHouses(usr);
      return usr;
    } else {
      return null;
    }
  }

  // Sign in
  Future emailSignIn({String email, String password}) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User user = result.user;
      return _fromUserToAppUser(user);
    } on FirebaseAuthException catch (e) {
      print(e.toString());
      return null;
    }
  }
  // Register

  // Sign out
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> resetPassword(String email) async {
    _auth.sendPasswordResetEmail(email: email);
  }

  Future changePassword(
      String email, String password, String newPassword) async {
    User user = _auth.currentUser;
    user.updatePassword(newPassword);
  }
}
