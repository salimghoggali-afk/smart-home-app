import 'package:flutter/cupertino.dart';
import 'package:my_home/models/vollet_model/vollet.dart';

class VoletIcon extends StatelessWidget {
  final Vollet volet;
  final String title;
  final double w;
  final double h;
  VoletIcon(
    this.volet,
    this.title,
    this.w,
    this.h,
  );

  @override
  Widget build(BuildContext context) {
    int st = volet.state;
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          margin: EdgeInsets.all(5),
          width: w,
          height: h,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/shutter$st.png'),
            ),
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
