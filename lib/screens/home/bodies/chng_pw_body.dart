import 'package:flutter/material.dart';
import 'package:my_home/models/user.dart';
import 'package:my_home/services/auth.dart';
import 'package:my_home/shared/constants.dart';

import '../sideBar.dart';

class ChngPwBody extends StatelessWidget {
  final AppUser user;
  final Function toggleView;
  final int bodyIndex;
  ChngPwBody({
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
      body: Center(
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.only(left: 20, right: 20, top: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.security,
                  ),
                  Text(
                    '  Change Password',
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 50.0,
              ),
              Text(
                'In order to change your Password :\n',
              ),
              Text(
                '1- Do a Long Click on the button.\n2- Check your email and follow the instructions.',
                textAlign: TextAlign.left,
              ),
              SizedBox(
                height: 30,
              ),
              ElevatedButton(
                child: Text('Send a Request'),
                onLongPress: () async {
                  await AuthService().resetPassword(user.email);
                  toggleView(0);
                },
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
