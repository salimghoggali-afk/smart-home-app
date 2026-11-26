import 'package:flutter/material.dart';

import 'floor.dart';
import 'room_model/room.dart';
import 'room_model/room_folder.dart';
import 'room_model/room_view/roomView.dart';
import 'user.dart';

class FloorIcon extends StatefulWidget {
  Floor floor;
  final AppUser user;

  FloorIcon(this.user, {this.floor});

  @override
  _FloorIconState createState() => _FloorIconState();
}

class _FloorIconState extends State<FloorIcon> {
  int index = -1;

  void toggleView(int index) {
    setState(() {
      this.index = index;
    });
  }

  Container createFloor() {
    List<List<Room>> rooms = widget.floor.rooms;
    int l = widget.floor.rooms.length;
    List<List<Room>> rooms1 = [];
    List<int> rooms1Index = [];
    List<List<Room>> rooms2 = [];
    List<int> rooms2Index = [];
    List<List<Room>> rooms3 = [];
    List<int> rooms3Index = [];
    List<Widget> lst = [];
    lst.add(Divider());
    for (var i = 0; i < l; i++) {
      switch (rooms[i].length) {
        case 1:
          rooms1.add(rooms[i]);
          rooms1Index.add(i);
          break;
        case 2:
          rooms2.add(rooms[i]);
          rooms2Index.add(i);
          break;
        case 3:
          rooms3.add(rooms[i]);
          rooms3Index.add(i);
          break;
      }
    }
    Container ctn = Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: lst,
      ),
    );
    for (var i = 0; i < rooms3.length; i++) {
      lst.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          RoomFolder(
            rooms3[i],
            toggleView,
            rooms3Index[i],
          ),
        ],
      ));
      lst.add(Divider());
    }
    int j = 0;
    for (var i = 0; i < rooms2.length; i++) {
      j++;
      if (i < rooms1.length) {
        lst.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            RoomFolder(
              rooms2[i],
              toggleView,
              rooms2Index[i],
            ),
            RoomFolder(
              rooms1[i],
              toggleView,
              rooms1Index[i],
            ),
          ],
        ));
      } else {
        lst.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            RoomFolder(
              rooms2[i],
              toggleView,
              rooms2Index[i],
            ),
          ],
        ));
      }

      lst.add(Divider());
    }
    for (var i = j; i < rooms1.length; i += 3) {
      if ((i + 2) < rooms1.length) {
        lst.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            RoomFolder(
              rooms1[i],
              toggleView,
              rooms1Index[i],
            ),
            RoomFolder(
              rooms1[i + 1],
              toggleView,
              rooms1Index[i + 1],
            ),
            RoomFolder(
              rooms1[i + 2],
              toggleView,
              rooms1Index[i + 2],
            ),
          ],
        ));
      } else {
        if ((i + 1) < rooms1.length) {
          lst.add(Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RoomFolder(
                rooms1[i],
                toggleView,
                rooms1Index[i],
              ),
              RoomFolder(
                rooms1[i + 1],
                toggleView,
                rooms1Index[i + 1],
              ),
            ],
          ));
        } else {
          lst.add(Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RoomFolder(
                rooms1[i],
                toggleView,
                rooms1Index[i],
              ),
            ],
          ));
        }
      }
      lst.add(Divider());
    }
    return ctn;
  }

  @override
  Widget build(BuildContext context) {
    if (index == -1) {
      return SingleChildScrollView(
        child: createFloor(),
      );
    } else {
      return RoomView(widget.user, widget.floor.rooms[index], toggleView);
    }
  }
}

/*
List<Widget> createFloor() {
    List<Widget> lst = [];
    int l = widget.floor.rooms.length;

    for (var i = 0; i < l; i++) {
      lst.add(RoomFolder(
        widget.floor.rooms[i],
        toggleView,
        i,
      ));
      lst.add(Divider());
    }
    return lst;
  }

  @override
  Widget build(BuildContext context) {
    if (index == -1) {
      return Container(
        child: ListView(
          padding: EdgeInsets.all(30),
          children: createFloor(),
        ),
      );
    } else {
      return RoomView(widget.user, widget.floor.rooms[index], toggleView);
    }
  }
*/
