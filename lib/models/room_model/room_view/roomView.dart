import 'package:flutter/material.dart';
import 'package:my_home/models/vollet_model/vollet_header.dart';

import '../../user.dart';
import '../room.dart';
import 'room_header.dart';

class RoomView extends StatelessWidget {
  final Function toggleView;
  final List<Room> rooms;
  final AppUser user;

  RoomView(this.user, this.rooms, this.toggleView);

  Container buildLamps() {
    List<Widget> lst = [];
    Container cnt = Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(10, 20, 10, 30),
      child: Column(
        children: lst,
      ),
    );
    lst.add(RoomHeader(user, rooms[0]));
    for (var i = 1; i < rooms.length; i++) {
      lst.add(Divider(
        color: Colors.black,
        thickness: 1,
      ));
      lst.add(RoomHeader(user, rooms[i]));
    }
    return cnt;
  }

  Container buildVollets() {
    List<Widget> lst = [];
    Container cnt = Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(10, 20, 10, 40),
      child: Column(
        children: lst,
      ),
    );
    lst.add(Divider(
      color: Colors.black,
      thickness: 1,
    ));
    lst.add(SizedBox(
      height: 10,
    ));
    int l = rooms.length;
    for (var i = 0; i < l; i++) {
      if (rooms[i].vollets.length > 0) {
        for (var j = 0; j < rooms[i].vollets.length; j++) {
          lst.add(VolletHeader(rooms[i].vollets[j]));
        }
      }
    }
    if (lst.length > 0) {
      return cnt;
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(left: 20, right: 20, top: 10),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.teal,
              ),
              onPressed: () => toggleView(-1),
            ),
            Text(
              'Back',
              style: TextStyle(
                color: Colors.teal,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 10.0,
        ),
        buildLamps(),
        buildVollets(),
      ],
    );
  }
}

// OLD VERSION
/*
 @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(left: 20, right: 20, top: 10),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.teal,
              ),
              onPressed: () => toggleView(-1),
            ),
            Text(
              'Back',
              style: TextStyle(
                color: Colors.teal,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 10.0,
        ),
        buildLamps(),
        buildVollets(),
      ],
    );
  }
*/
