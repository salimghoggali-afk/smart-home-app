import 'package:flutter/material.dart';

import 'room.dart';
import 'room_icon.dart';

class RoomFolder extends StatelessWidget {
  final Function togleView;
  final List<Room> rooms;
  final int index;

  RoomFolder(
    this.rooms,
    this.togleView,
    this.index,
  );

  Container buildFolder() {
    int l = rooms.length;
    List<Widget> lst = [];
    IntrinsicHeight row = IntrinsicHeight(
      child: Row(
        children: lst,
      ),
    );
    Container ctn = Container(
      decoration: new BoxDecoration(
        color: Colors.white, //background color of box
        border: Border.all(
          color: Colors.grey,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 25.0, // soften the shadow
            spreadRadius: 5.0, //extend the shadow
            offset: Offset(
              5.0, // Move to right 10  horizontally
              5.0, // Move to bottom 10 Vertically
            ),
          )
        ],
      ),
      child: row,
    );
    for (var i = 0; i < l; i++) {
      lst.add(RoomIcon(rooms.elementAt(i)));
      if ((i + 1) < l) {
        lst.add(
          VerticalDivider(
            color: Colors.grey,
            width: 2,
            thickness: 1.0,
            indent: 10,
            endIndent: 10,
          ),
        );
      }
    }
    return ctn;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        togleView(index);
      },
      splashColor: Colors.teal[200],
      child: buildFolder(),
    );
  }
}

/*
 @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        togleView(index);
      },
      splashColor: Colors.teal[200],
      child: Container(
        width: this.rooms.length < 2 ? 158 : 294,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.orange[200],
            width: 2.0,
          ),
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 3,
              blurRadius: 5,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: buildFolder(),
      ),
    );
  }
*/
