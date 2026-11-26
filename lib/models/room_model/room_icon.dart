import 'package:flutter/material.dart';
import 'package:my_home/models/lamp_model/lamp_icon.dart';

import 'room.dart';
import 'room_icon_bkgrd.dart';

class RoomIcon extends StatelessWidget {
  final Room room;

  RoomIcon(
    this.room,
  );

  @override
  Widget build(BuildContext context) {
    int n = room.lamps.length;
    int m = 0;
    room.lamps.forEach((element) {
      if (element.state == 0) m++;
    });
    return Container(
      width: 116,
      height: 100,
      padding: EdgeInsets.only(left: 10, top: 5, right: 10, bottom: 5),
      // color: Colors.white,
      decoration: new BoxDecoration(
        color: Colors.white, //background color of box
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          LampIcon(room.lamps),
          Container(
            width: 80,
            child: Column(
              children: [
                Text(
                  room.name,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                RoomIConBkGnd(room.vollets),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/*
 RotatedBox(
            quarterTurns: 1,
            child: Text(
              room.name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.fade,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
  @override
  Widget build(BuildContext context) {
    int n = room.lamps.length;
    int m = 0;
    room.lamps.forEach((element) {
      if (element.state == 0) m++;
    });
    return Container(
        width: 130,
        height: 132,
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey,
            width: 2.0,
          ),
        ),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            RoomIConBkGnd(room.vollets),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      child: room.locked == true
                          ? Icon(
                              Icons.lock_outline,
                              color: Colors.red,
                            )
                          : Container(
                              height: 25,
                            ),
                    ),
                  ],
                ),
                LampIcon(room.lamps),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Image.asset('assets/roomicons/' + room.type + '.png'),
                        Text(
                          room.name,
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Opacity(
              opacity:
                  0.3 * m / n, // 0.3 * Nbr of Off Lamps * Total Nbr of Lamps
              child: Container(
                color: Colors.black,
              ),
            ),
          ],
        ));
  }
 */
