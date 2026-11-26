import 'package:flutter/material.dart';
import 'package:my_home/models/user.dart';
import 'package:provider/provider.dart';
import 'authenticate/authenticate.dart';
import 'home/home.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser>(context);
    if (user == null) {
      return Authenticate();
    } else {
      return Home(
        user: user,
      );
    }
  }
}

/*
Home(
        user: user,
      );
      */
