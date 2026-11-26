import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_home/models/room_model/room.dart';

import '../../services/database.dart';
import '../floor.dart';
import '../house.dart';
import 'volet_icon.dart';
import 'vollet.dart';

class VolletsViewer extends StatefulWidget {
  final House house;
  List<Vollet> volets = [];
  List<Vollet> voletsSelected = [];
  List<bool> voletSel = [];
  List<String> voletsTitle = [];

  VolletsViewer(this.house) {
    initVolets();
  }

  void initVolets() {
    String str1, str2;
    for (var i = 0; i < house.floors.length; i++) {
      Floor floor = house.floors[i];
      str1 = 'Floor ' + (i + 1).toString();
      for (var j = 0; j < floor.rooms.length; j++) {
        List<Room> rooms = floor.rooms[j];
        for (var k = 0; k < rooms.length; k++) {
          str2 = rooms[0].name;

          if (k != 0) str2 = str2 + ' ' + rooms[k].name;
          for (var l = 0; l < rooms[k].vollets.length; l++) {
            String strh, strv;
            if (rooms[k].vollets.length > 1) {
              strv = str2 + '\n' + (l + 1).toString();
              strh = str2 + ' (' + (l + 1).toString() + ')';
            } else {
              strv = str2;
              strh = str2;
            }

            volets.add(rooms[k].vollets[l]);
            strv = strv + ' \n' + str1;
            strh = strh + ' ' + str1;
            rooms[k].vollets[l].titlev = strv;

            rooms[k].vollets[l].titleh = strh;
            voletSel.add(false);
            voletsTitle.add(strh);
          }
        }
      }
    }
  }

  @override
  _VolletsViewerState createState() => _VolletsViewerState();
}

class _VolletsViewerState extends State<VolletsViewer> {
  int _toggleView = 0;
  bool _buttonPressed = false;

  void _whilePressed(String vl) async {
    while (_buttonPressed) {
      for (var i = 0; i < widget.voletsSelected.length; i++) {
        Map<String, dynamic> value = {'orderdesired': vl};
        String path = widget.voletsSelected[i].path;
        DataBaseService().updateData(path, value);
        DataBaseService().updateData(path, {'orderdesired': 'none'});
      }
      if (widget.volets[1].msgflag == 1) {
        _buttonPressed = false;
        for (var i = 0; i < widget.voletsSelected.length; i++) {
          Map<String, dynamic> value = {'orderdesired': 'stop'};
          String path = widget.voletsSelected[i].path;
          DataBaseService().updateData(path, value);
          DataBaseService().updateData(path, {'orderdesired': 'none'});
        }
      }
      // wait a second
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  Center buildVollets() {
    List<Widget> lst = [];
    Center cnt = Center(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(10, 20, 10, 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: lst,
            ),
            Column(
              children: [
                widget.volets[1].msgflag == 0
                    ? Listener(
                        onPointerDown: (details) {
                          if (_buttonPressed == false) {
                            _buttonPressed = true;
                            _whilePressed('up');
                          }
                        },
                        onPointerUp: (details) {
                          _buttonPressed = false;
                          for (var i = 0;
                              i < widget.voletsSelected.length;
                              i++) {
                            Map<String, dynamic> value = {
                              'orderdesired': 'stop'
                            };
                            String path = widget.voletsSelected[i].path;
                            DataBaseService().updateData(path, value);
                            DataBaseService()
                                .updateData(path, {'orderdesired': 'none'});
                          }
                        },
                        child: ElevatedButton(
                          child: Icon(
                            Icons.arrow_upward,
                            color: Colors.black,
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.blueGrey[100],
                          ),
                          onPressed: () {
                            // HapticFeedback.heavyImpact();
                          },
                        ),
                      )
                    : SizedBox(
                        height: 5,
                      ),
                SizedBox(
                  height: 10,
                ),
                widget.volets[1].msgflag == 1
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_reset_sharp,
                            color: Colors.red,
                            size: 64.0,
                            semanticLabel: '',
                          ),
                          Text(
                            'Bad Connexion',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        height: 5,
                      ),
                SizedBox(
                  height: 10,
                ),
                widget.volets[1].msgflag == 1
                    ? Listener(
                        onPointerDown: (details) {
                          if (_buttonPressed == false) {
                            _buttonPressed = true;
                            _whilePressed('stop');
                          }
                        },
                        onPointerUp: (details) {
                          _buttonPressed = false;
                          for (var i = 0;
                              i < widget.voletsSelected.length;
                              i++) {
                            Map<String, dynamic> value = {
                              'orderdesired': 'stop'
                            };
                            String path = widget.voletsSelected[i].path;
                            DataBaseService().updateData(path, value);
                            DataBaseService()
                                .updateData(path, {'orderdesired': 'none'});
                          }
                        },
                        child: ElevatedButton(
                          child: Icon(
                            Icons.arrow_downward,
                            color: Colors.black,
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.blueGrey[100],
                          ),
                          onPressed: () {
                            //HapticFeedback.heavyImpact();
                          },
                        ),
                      )
                    : SizedBox(
                        height: 5,
                      ),
              ],
            ),
          ],
        ),
      ),
    );

    //lst = [];
    List<Widget> children = [];
    widget.voletsSelected.add(widget.volets[1]);
    widget.voletsSelected.add(widget.volets[2]);
    widget.voletsSelected.add(widget.volets[3]);
    children.add(VoletIcon(widget.volets[1], widget.volets[1].titlev, 90, 90));
    children.add(VoletIcon(widget.volets[2], widget.volets[2].titlev, 90, 90));
    children.add(VoletIcon(widget.volets[3], widget.volets[3].titlev, 90, 90));
    lst.add(Row(
      children: children,
    ));
    children = [];

    widget.voletsSelected.add(widget.volets[4]);
    widget.voletsSelected.add(widget.volets[5]);
    widget.voletsSelected.add(widget.volets[6]);
    children.add(VoletIcon(widget.volets[4], widget.volets[4].titlev, 90, 90));
    children.add(VoletIcon(widget.volets[5], widget.volets[5].titlev, 90, 90));
    children.add(VoletIcon(widget.volets[6], widget.volets[6].titlev, 90, 90));
    lst.add(Row(
      children: children,
    ));
    children = [];

    widget.voletsSelected.add(widget.volets[8]);
    widget.voletsSelected.add(widget.volets[9]);
    children.add(VoletIcon(widget.volets[8], widget.volets[8].titlev, 90, 90));
    children.add(VoletIcon(widget.volets[9], widget.volets[9].titlev, 90, 90));

    lst.add(Row(
      children: children,
    ));
    return cnt;
  }

  Container buildSeclectList() {
    List<ListTile> lst = [];
    Container ctn = Container(
      padding: EdgeInsets.fromLTRB(30, 20, 30, 40),
      child: Column(
        children: lst,
      ),
    );
    for (var i = 0; i < widget.volets.length; i++) {
      lst.add(
        ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/shutter' +
                    widget.volets[i].state.toString() +
                    '.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          title: Text(
            widget.voletsTitle[i],
            style: TextStyle(fontSize: 11),
          ),
          trailing: widget.voletSel[i]
              ? Icon(
                  Icons.check_circle,
                  color: Colors.teal,
                )
              : Icon(
                  Icons.check_circle,
                  color: Colors.grey,
                ),
          onTap: () {
            setState(() {
              if (!widget.voletSel[i]) {
                widget.voletsSelected.add(widget.volets[i]);
              } else {
                widget.voletsSelected.remove(widget.volets[i]);
              }
              widget.voletSel[i] = !widget.voletSel[i];
            });
          },
        ),
      );
    }
    return ctn;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.playlist_add_check),
                iconSize: 48,
                onPressed: () {
                  setState(() {
                    if (_toggleView == 0) {
                      _toggleView = 0;
                    } else {
                      _toggleView = 0;
                    }
                  });
                },
              )
            ],
          ),
          _toggleView == 0 ? buildVollets() : buildSeclectList(),
        ],
      ),
    );
  }
}
