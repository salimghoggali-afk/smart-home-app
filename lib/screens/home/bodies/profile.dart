import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_home/models/user.dart';
import 'package:my_home/services/database.dart';
import 'package:my_home/shared/loading.dart';

class Profile extends StatefulWidget {
  final AppUser user;
  final Function toggleView;

  Profile({
    this.user,
    this.toggleView,
  });

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _enbl_firstName = true;
  bool _enbl_lastName = true;
  bool _enbl_birthdayDate = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
      stream: DataBaseService(uid: widget.user.uid).userProfile,
      builder: (context, event) {
        if (event.hasData) {
          widget.user.updateUser(event.data.snapshot.value);
          return SafeArea(
            child: RawScrollbar(
              thumbColor: Colors.grey,
              thickness: 15,
              controller: _scrollController,
              //isAlwaysShown: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 50.0, horizontal: 30.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () async {
                            // Select Img from Gallery
                            PickedFile img = await ImagePicker()
                                .getImage(source: ImageSource.gallery);
                            // upload img to firebase storage
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.grey,
                            radius: 40,
                            child: Icon(
                              Icons.person,
                              color: Colors.grey[800],
                              size: 60.0,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 12.0,
                        ),
                        Text(
                          'My Profile',
                          style: TextStyle(
                            color: Colors.blueGrey[600],
                            fontSize: 22,
                          ),
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                        TextFormField(
                          initialValue: widget.user.firstName,
                          readOnly: _enbl_firstName,
                          decoration: InputDecoration(
                            labelText: 'First Name :',
                            suffixIcon: IconButton(
                              icon: Icon(
                                this._enbl_firstName ? Icons.edit : Icons.check,
                                color: this._enbl_firstName
                                    ? Colors.grey
                                    : Colors.redAccent,
                              ),
                              onPressed: () {
                                setState(() => this._enbl_firstName =
                                    !this._enbl_firstName);
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                        TextFormField(
                          initialValue: widget.user.lastName,
                          readOnly: _enbl_lastName,
                          decoration: InputDecoration(
                            labelText: 'Last Name :',
                            suffixIcon: IconButton(
                              icon: Icon(
                                this._enbl_lastName ? Icons.edit : Icons.check,
                                color: this._enbl_lastName
                                    ? Colors.grey
                                    : Colors.redAccent,
                              ),
                              onPressed: () {
                                setState(() =>
                                    this._enbl_lastName = !this._enbl_lastName);
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                        TextFormField(
                          initialValue: widget.user.birthdayDate,
                          readOnly: _enbl_birthdayDate,
                          decoration: InputDecoration(
                            labelText: 'Date of Birthday :',
                            suffixIcon: IconButton(
                              icon: Icon(
                                this._enbl_birthdayDate
                                    ? Icons.edit
                                    : Icons.check,
                                color: this._enbl_birthdayDate
                                    ? Colors.grey
                                    : Colors.redAccent,
                              ),
                              onPressed: () {
                                setState(() => this._enbl_birthdayDate =
                                    !this._enbl_birthdayDate);
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                        TextFormField(
                          initialValue: widget.user.email,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Email :',
                          ),
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            child: Text(
                              'Member since : ' + widget.user.creationDate,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return Loading();
        }
      },
    );
  }
}
