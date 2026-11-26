import 'package:flutter/material.dart';
import 'package:my_home/models/user.dart';
import 'package:my_home/services/auth.dart';

class SideBar extends StatelessWidget {
  final AuthService _auth = AuthService();
  final AppUser user;
  final int bodyIndex;
  final Function toggleView;

  SideBar({
    this.user,
    this.toggleView,
    this.bodyIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user.firstName + ' ' + user.lastName),
            accountEmail: Text(user.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(
                Icons.person,
                color: Colors.grey[800],
                size: 60.0,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home Page'),
            selected: bodyIndex == 0,
            onTap: () {
              Navigator.of(context).pop();
              toggleView(0);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('My Profile'),
            selected: bodyIndex == 1,
            onTap: () {
              Navigator.of(context).pop();
              toggleView(1);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.payment),
            title: Text('Payment'),
            selected: bodyIndex == 2,
            onTap: () {
              Navigator.of(context).pop();
              toggleView(2);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            selected: bodyIndex == 3,
            onTap: () {
              Navigator.of(context).pop();
              toggleView(3);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.security),
            title: Text('Change Password'),
            selected: bodyIndex == 4,
            onTap: () {
              Navigator.of(context).pop();
              toggleView(4);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sign Out'),
            onTap: () async {
              await _auth.signOut();
            },
          ),
          Divider(),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Image.network(
        '',
        width: 90.0,
        height: 90.0,
        fit: BoxFit.cover,
      ),
    );
  }
}
