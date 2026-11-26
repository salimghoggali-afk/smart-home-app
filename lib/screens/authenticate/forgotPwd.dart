import 'package:flutter/material.dart';
import 'package:my_home/services/auth.dart';
import 'package:my_home/shared/constants.dart';
import 'package:my_home/shared/loading.dart';

class ForgotPwd extends StatefulWidget {
  final Function toggleView;

  ForgotPwd({
    this.toggleView,
  });
  @override
  _ForgotPwdState createState() => _ForgotPwdState();
}

class _ForgotPwdState extends State<ForgotPwd> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String error = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => widget.toggleView(),
              ),
              title: Text('Forgot PassWord'),
              centerTitle: true,
            ),
            body: Center(
              child: Container(
                padding:
                    EdgeInsets.symmetric(vertical: 100.0, horizontal: 20.0),
                child: Column(
                  children: [
                    Text(
                      'Please enter the email address associated with your ' +
                          Constants.appName +
                          ' account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
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
                          SizedBox(
                            height: 20.0,
                          ),
                          ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.blueGrey),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState.validate()) {
                                setState(() {
                                  loading = true;
                                });
                                await _auth.resetPassword(email);
                                widget.toggleView();
                              }
                            },
                            child: Text('Submit'),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
