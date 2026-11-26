import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_home/services/database.dart';

import '../../user.dart';
import '../room.dart';

class RoomHeader extends StatefulWidget {
  final AppUser user;
  final Room room;

  RoomHeader(this.user, this.room);

  @override
  _RoomHeaderState createState() => _RoomHeaderState();
}

class _RoomHeaderState extends State<RoomHeader> {
  final _formKey = GlobalKey<FormState>();
  bool _enbl = true;
  List<String> fields = [];
  String roomName;

  void editingNames() {
    int l = fields.length;
    String name = roomName;
    if (name != widget.room.name) {
      Map<String, dynamic> value = {'name': name};
      String path = widget.room.path;
      DataBaseService().updateData(path, value);
    }
    l = widget.room.lamps.length;
    for (var i = 0; i < l; i++) {
      name = fields[i];
      if (name != widget.room.lamps[i].name) {
        Map<String, dynamic> value = {'name': name};
        String path = widget.room.lamps[i].path;
        DataBaseService().updateData(path, value);
      }
    }
  }

  Column buildLampsColumn() {
    List<Widget> lst = [];
    int l = widget.room.lamps.length;
    roomName = widget.room.name;
    TextFormField txt;
    for (var i = 0; i < l; i++) {
      txt = TextFormField(
        initialValue: widget.room.lamps[i].name,
        readOnly: _enbl,
        enableInteractiveSelection: false,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          focusedBorder: _enbl
              ? InputBorder.none
              : UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
          enabledBorder: _enbl
              ? InputBorder.none
              : UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
          //errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          suffix: ElevatedButton(
            child: Text('O/F'),
            onPressed: _enbl
                ? () {
                    String order = 'off';
                    if (widget.room.lamps[i].state == 0) order = 'on';
                    Map<String, dynamic> value = {'order': order};
                    String path = widget.room.lamps[i].path;
                    DataBaseService().updateData(path, {'order': 'none'});
                    DataBaseService().updateData(path, value);
                    HapticFeedback.heavyImpact();
                  }
                : null,
          ),
          prefix: widget.room.lamps[i].state != 0
              ? Image.asset('assets/bulb.png')
              : Image.asset('assets/bulboff.png'),
        ),
        onChanged: (val) {
          fields[i] = val;
        },
      );
      fields.add(widget.room.lamps[i].name);
      lst.add(txt);
    }
    return Column(
      children: lst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton(
                child: widget.room.locked == false
                    ? Icon(
                        Icons.lock_open_outlined,
                        color: Colors.white,
                      )
                    : Icon(
                        Icons.lock_outline,
                        color: Colors.red,
                      ),
                style: ElevatedButton.styleFrom(
                  primary: widget.room.locked == false
                      ? Colors.blueGrey
                      : Colors.blueGrey[50],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {},
                onLongPress: () {
                  bool bl = !widget.room.locked;
                  Map<String, dynamic> value = {'locked': bl};
                  for (var i = 0; i < widget.room.lamps.length; i++) {
                    DataBaseService()
                        .updateData(widget.room.lamps[i].path, value);
                  }
                  DataBaseService().updateData(widget.room.path, value);
                },
              )
            ],
          ),
          TextFormField(
            initialValue: widget.room.name,
            readOnly: _enbl,
            enableInteractiveSelection: false,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: InputBorder.none,
              focusedBorder: _enbl
                  ? InputBorder.none
                  : UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
              enabledBorder: _enbl
                  ? InputBorder.none
                  : UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
              //errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              suffix: ElevatedButton(
                child: Icon(
                  this._enbl ? Icons.edit : Icons.check,
                  color: this._enbl ? Colors.grey : Colors.redAccent,
                ),
                style: ElevatedButton.styleFrom(
                  primary: Colors.white,
                ),
                onPressed: () {},
                onLongPress: () {
                  if (_enbl == false) {
                    editingNames();
                  }
                  setState(() => this._enbl = !this._enbl);
                },
              ),
              prefix:
                  Image.asset('assets/roomicons/' + widget.room.type + '.png'),
            ),
            onChanged: (val) {
              roomName = val;
            },
          ),
          buildLampsColumn(),
        ],
      ),
    );
  }
}
