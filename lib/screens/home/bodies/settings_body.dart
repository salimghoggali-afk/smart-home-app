import 'package:flutter/material.dart';
import 'package:my_home/models/user.dart';
import 'package:my_home/shared/constants.dart';

import '../sideBar.dart';

class SettingsBody extends StatelessWidget {
  final AppUser user;
  final Function toggleView;
  final int bodyIndex;
  SettingsBody({
    this.user,
    this.toggleView,
    this.bodyIndex,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.teal[800]),
        title: Text(
          Constants.appName,
          style: TextStyle(
            color: Colors.teal[800],
          ),
        ),
        backgroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              toggleView(0);
            },
          )
        ],
      ),
      drawer: SideBar(
        user: this.user,
        toggleView: toggleView,
        bodyIndex: bodyIndex,
      ),
      body: Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 30),
        color: Colors.white,
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.settings),
                Text(
                  '  Settings',
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              height: 200,
              width: 240,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {},
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/buttonicons/hardware.png'),
                        Text('Hardware'),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/buttonicons/users.png'),
                        Text('Users'),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
