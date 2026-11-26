import 'package:flutter/material.dart';
import 'package:my_home/models/vollet_model/volet_icon.dart';
import 'package:my_home/models/vollet_model/vollet.dart';

class RoomIConBkGnd extends StatelessWidget {
  final List<Vollet> vollets;

  RoomIConBkGnd(this.vollets);

  Row buildRow() {
    int l = this.vollets == null ? 0 : this.vollets.length;
    Column cln;
    List<Widget> listCln;
    List<Widget> list = [];
    Row row = Row(
      children: list,
    );
    double h = 20;
    double w = 20;
    for (var i = 0; i < l; i += 2) {
      listCln = [];
      cln = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: listCln,
      );
      int st = vollets.elementAt(i).state;
      listCln.add(
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
      );
      if ((i + 1) < l) {
        int st = vollets.elementAt(i + 1).state;
        listCln.add(VoletIcon(vollets[i], '', w, h));
      }
      list.add(cln);
    }

    return row;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: buildRow(),
    );
  }
}

/*
 if ((i + 2) < l) {
          int st = vollets.elementAt(i + 2).state;
          listCln.add(
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
          );
        }
 List<TableRow> buildTable() {
    int l = this.vollets == null ? 0 : this.vollets.length;
    int m;
    int n;
    if (l % 2 == 0) {
      m = l == 2 ? 2 : l ~/ 2;
      n = m;
    } else {
      m = l ~/ 2 + 1;
      n = m;
    }

    double w = 120/M;
    double h = W;
    List<TableRow> tblRows = [];
    List<Container> row = [];
    for (var i = 0; i < m; i++) {
      row = [];
      for (var j = 0; j < n; j++) {
        if (((i) * n + (j + 1)) > l) {
          row.add(Container());
        } else {
          int st = vollets.elementAt((i) * n + j).state;
          row.add(Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/shutter$st.png'),
                fit: BoxFit.cover,
              ),
            ),
          ));
        }
      }
      tblRows.add(TableRow(
        children: row,
      ));
    }

    return tblRows;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      child: Table(
        children: buildTable(),
      ),
    );
  }
*/
