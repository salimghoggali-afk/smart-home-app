import 'package:firebase_database/firebase_database.dart';
import 'package:my_home/models/user.dart';

class DataBaseService {
  final String uid;

  DataBaseService({
    this.uid,
  });

  final fb = FirebaseDatabase.instance.ref();

  Future updateUserData(AppUser user) async {
    fb.child('users/$uid').set({
      'firstName': user.firstName,
      'lastName': user.lastName,
    });
  }

  Future getUserData(AppUser user) async {
    fb.child('users/' + uid).once().then((DatabaseEvent event) {
      Map<dynamic, dynamic> data = event.snapshot.value;
      user.updateUser(data);
    });
  }

  Future getUserHouses(AppUser user) async {
    fb.child('Homes/' + uid + '/').once().then((DatabaseEvent event) {
      List<dynamic> data = event.snapshot.value;
      user.updateUserHouses(data);
    });
  }

  Future updateData(String path, Map<String, dynamic> value) async {
    print(path);
    fb.child(path).once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) fb.child(path).update(value);
    });
  }

  // Get user profile stream
  Stream<dynamic> get userProfile {
    return fb.child('users/$uid').onValue;
  }

  // Get user Homes stream
  Stream<dynamic> get userHomes {
    return fb.child('Homes/$uid').onValue;
  }
}
