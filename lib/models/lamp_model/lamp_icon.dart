import 'package:flutter/material.dart';

import 'lamp.dart';

class LampIcon extends StatelessWidget {
  final List<Lamp> lamps;

  LampIcon(this.lamps);

  Column buildLamps() {
    List<Container> containers = [];
    lamps.forEach((element) {
      containers.add(
        Container(
          width: 15, // 5/6 of height 30 vs 25
          height: 18,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: element.state != 0
                  ? AssetImage('assets/bulb.png')
                  : AssetImage('assets/bulboff.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    });
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: containers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildLamps();
  }
}

// OLD VERSION RETURN A ROW INSTEAD OF A COLUMN
