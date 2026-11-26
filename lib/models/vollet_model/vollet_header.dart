import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_home/models/vollet_model/vollet.dart';

import '../../services/database.dart';
import 'volet_icon.dart';

class VolletHeader extends StatefulWidget {
  final Vollet volet;
  //final Timer timer = Timer(duration, callback);
  VolletHeader(this.volet);

  @override
  State<VolletHeader> createState() => _VolletHeaderState();
}

class _VolletHeaderState extends State<VolletHeader> {
  bool _buttonPressed = false;
  bool _timerFlg = false;
  int _counter = 0;

  void _launchTimer() {
    int xtime = (widget.volet.coursetime / 10).floor();
    Timer.periodic(Duration(milliseconds: xtime), (timer) {
      int st = widget.volet.state;
      if (widget.volet.order == 'up') {
        if (st > 0) {
          st = st - 10;
          String path = widget.volet.path;
          DataBaseService().updateData(path, {'state': st});
        } else {
          timer.cancel();
        }
      } else {
        if (widget.volet.order == 'down') {
          if (st < 100) {
            st = st + 10;
            String path = widget.volet.path;
            DataBaseService().updateData(path, {'state': st});
          } else {
            timer.cancel();
          }
        } else {
          timer.cancel();
        }
      }
    });
    _timerFlg = false;
  }

  void _whilePressed(String vl) async {
    while (_buttonPressed) {
      Map<String, dynamic> value = {'orderdesired': vl};
      String path = widget.volet.path;
      DataBaseService().updateData(path, {'orderdesired': 'none'});
      //DataBaseService().updateData(path, {'locked': _counter});
      DataBaseService().updateData(path, value);
      if (widget.volet.msgflag == 1) {
        _buttonPressed = false;
        Map<String, dynamic> value = {'orderdesired': 'stop'};
        String path = widget.volet.path;
        DataBaseService().updateData(path, {'orderdesired': 'none'});
        DataBaseService().updateData(path, value);
        DataBaseService().updateData(path, {'orderdesired': 'none'});
        //DataBaseService().updateData(path, value);
        //DataBaseService().updateData(path, {'locked': _counter});
        DataBaseService().updateData(path, value);
      }
      if (_timerFlg) {
        if (widget.volet.order != 'stop') {
          _launchTimer();
        }
      }

      // wait a 100 mili second
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          VoletIcon(widget.volet, widget.volet.titlev, 200, 200),
          Container(
            child: Column(
              children: [
                widget.volet.msgflag == 0
                    ? Listener(
                        onPointerDown: (details) {
                          if (_buttonPressed == false) {
                            _buttonPressed = true;
                            _timerFlg = true;
                            _whilePressed('up');
                          }
                        },
                        onPointerUp: (details) {
                          _buttonPressed = false;
                          _timerFlg = false;
                          Map<String, dynamic> value = {'orderdesired': 'stop'};
                          String path = widget.volet.path;
                          DataBaseService()
                              .updateData(path, {'orderdesired': 'none'});
                          DataBaseService().updateData(path, value);
                          DataBaseService()
                              .updateData(path, {'orderdesired': 'none'});
                          DataBaseService().updateData(path, value);
                          DataBaseService()
                              .updateData(path, {'orderdesired': 'none'});
                          DataBaseService().updateData(path, value);
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
                widget.volet.msgflag == 1
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
                              fontSize: 16,
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
                widget.volet.msgflag == 0
                    ? Listener(
                        onPointerDown: (details) {
                          if (_buttonPressed == false) {
                            _buttonPressed = true;
                            _timerFlg = true;
                            _whilePressed('down');
                          }
                        },
                        onPointerUp: (details) {
                          _buttonPressed = false;
                          _timerFlg = false;
                          Map<String, dynamic> value = {'orderdesired': 'stop'};
                          String path = widget.volet.path;
                          DataBaseService()
                              .updateData(path, {'orderdesired': 'none'});
                          DataBaseService().updateData(path, value);
                          DataBaseService()
                              .updateData(path, {'orderdesired': 'none'});
                          DataBaseService().updateData(path, value);
                          DataBaseService()
                              .updateData(path, {'orderdesired': 'none'});
                          DataBaseService().updateData(path, value);
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
                          onLongPress: () {
                            /* Map<String, dynamic> value = {
                              'orderdesired': 'down'
                            };
                            String path = widget.volet.path;
                            DataBaseService().updateData(path, value);
                            DataBaseService()
                                .updateData(path, {'orderdesired': 'none'});*/
                          },
                        ),
                      )
                    : SizedBox(
                        height: 5,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
