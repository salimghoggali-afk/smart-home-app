import 'package:flutter/material.dart';
import 'package:my_home/services/auth.dart';
import 'package:my_home/shared/loading.dart';

class SignIn extends StatefulWidget {
  final Function toggleView;

  SignIn({
    this.toggleView,
  });
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String error = '';
  bool _showPassword = false;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            body: ListView(
              padding: EdgeInsets.symmetric(vertical: 150.0, horizontal: 20.0),
              shrinkWrap: true,
              children: [
                Text(
                  'Smart Home',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal),
                ),
                Text(
                  'Designed by',
                  textAlign: TextAlign.center,
                ),
                Text(
                  'S. Ghoggali & k. Haddad',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  'Version 1.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9),
                ),
                Text(
                  'Copyright 2020',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9),
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: 20.0,
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          icon: Icon(Icons.email),
                          hintText: 'Email',
                        ),
                        onChanged: (val) {
                          setState(() {
                            email = val;
                          });
                        },
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      TextFormField(
                        obscureText: !this._showPassword,
                        decoration: InputDecoration(
                          icon: Icon(Icons.security_sharp),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.remove_red_eye,
                              color: this._showPassword
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() =>
                                  this._showPassword = !this._showPassword);
                            },
                          ),
                          hintText: 'Password',
                        ),
                        onChanged: (val) {
                          setState(() {
                            password = val;
                          });
                        },
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.blueGrey),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState.validate()) {
                            setState(() {
                              loading = true;
                            });
                            dynamic result = await _auth.emailSignIn(
                              email: email,
                              password: password,
                            );
                            if (result == null) {
                              setState(() {
                                loading = false;
                                error = 'wrong email or password!';
                              });
                            }
                          }
                        },
                        child: Text('Sign In'),
                      ),
                      SizedBox(
                        height: 12.0,
                      ),
                      Text(
                        error,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14.0,
                        ),
                      ),
                      SizedBox(
                        height: 12.0,
                      ),
                      TextButton(
                        onPressed: () {
                          widget.toggleView();
                        },
                        child: Text(
                          'Forgot Password',
                          style: TextStyle(color: Colors.teal, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}
