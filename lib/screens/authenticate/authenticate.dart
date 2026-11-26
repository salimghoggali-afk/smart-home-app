import 'package:flutter/material.dart';

import 'forgotPwd.dart';
import 'signIn.dart';

class Authenticate extends StatefulWidget {
  @override
  _AuthenticateState createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool showFrgtPwd = false;
  void toggleView() {
    setState(() {
      showFrgtPwd = !showFrgtPwd;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showFrgtPwd) {
      return ForgotPwd(toggleView: toggleView);
    } else {
      return SignIn(toggleView: toggleView);
    }
  }
}
