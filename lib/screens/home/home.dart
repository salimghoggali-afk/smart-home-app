import 'package:flutter/material.dart';
import 'package:my_home/models/user.dart';

import 'bodies/chng_pw_body.dart';
import 'bodies/home_body.dart';
import 'bodies/payment_body.dart';
import 'bodies/profile_body.dart';
import 'bodies/settings_body.dart';

class Home extends StatefulWidget {
  final AppUser user;

  Home({this.user});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int bodyIndex = 0;
  void toggleView(int bodyIndex) {
    setState(() {
      this.bodyIndex = bodyIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (bodyIndex == 0) {
      return HomeBody(
        user: widget.user,
        toggleView: this.toggleView,
        bodyIndex: this.bodyIndex,
      );
    }
    if (bodyIndex == 1) {
      return ProfileBody(
        user: widget.user,
        toggleView: this.toggleView,
        bodyIndex: this.bodyIndex,
      );
    }
    if (bodyIndex == 2) {
      return PaymentBody(
        user: widget.user,
        toggleView: this.toggleView,
        bodyIndex: this.bodyIndex,
      );
    }
    if (bodyIndex == 3) {
      return SettingsBody(
        user: widget.user,
        toggleView: this.toggleView,
        bodyIndex: this.bodyIndex,
      );
    }
    if (bodyIndex == 4) {
      return ChngPwBody(
        user: widget.user,
        toggleView: this.toggleView,
        bodyIndex: this.bodyIndex,
      );
    }
    return Container();
  }
}
