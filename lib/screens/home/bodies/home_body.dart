import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:my_home/models/floor.dart';
import 'package:my_home/models/floor_icon.dart';
import 'package:my_home/models/house.dart';
import 'package:my_home/models/user.dart';
import 'package:my_home/models/vollet_model/vollets_viewer.dart';
import 'package:my_home/services/database.dart';
import 'package:my_home/shared/constants.dart';
import 'package:my_home/shared/loading.dart';

import '../sideBar.dart';

class HomeBody extends StatefulWidget {
  final AppUser user;
  final Function toggleView;
  final int bodyIndex;
  final List<House> houses;

  HomeBody({
    this.user,
    this.toggleView,
    this.bodyIndex,
    this.houses,
  });

  @override
  _HomeBodyState createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  List<Tab> createTabs() {
    List<Tab> tabs = [];
    if (widget.user.houses.isEmpty) return tabs;
    House house = widget.user.houses[0];
    List<Floor> floors = house.floors;
    int l = floors.length;
    int ii;
    for (var i = 0; i < l; i++) {
      ii = i + 1;
      tabs.add(Tab(
        child: Text('Floor $ii'),
      ));
    }
    tabs.add(Tab(
      child: Text('Shut'),
    ));
    return tabs;
  }

  List<Widget> createTabBarViews() {
    List<Widget> tabViews = [];
    if (widget.user.houses.isEmpty) return tabViews;
    House house = widget.user.houses[0];
    List<Floor> floors = house.floors;
    int l = floors.length;
    for (var i = 0; i < l; i++) {
      tabViews.add(FloorIcon(
        widget.user,
        floor: floors[i],
      ));
    }

    tabViews.add(VolletsViewer(house));
    return tabViews;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
      stream: DataBaseService(uid: widget.user.uid).userHomes,
      builder: (context, event) {
        if (event.hasData) {
          List<dynamic> data = event.data.snapshot.value;
          widget.user.updateUserHouses(data);
          return DefaultTabController(
            initialIndex: 0,
            length: widget.user.houses.isEmpty
                ? 0
                : widget.user.houses[0].floors.length + 1,
            child: Scaffold(
              backgroundColor: Colors.grey[100],
              appBar: AppBar(
                iconTheme: IconThemeData(color: Colors.teal[800]),
                title: Text(
                  Constants.appName,
                  style: TextStyle(
                    color: Colors.teal[800],
                  ),
                ),
                //brightness: Brightness.dark,
                backgroundColor: Colors.white,
                actions: <Widget>[
                  TextButton(
                    child: Container(
                      padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
                      color: widget.user.houses[0].simulator == 'on'
                          ? Colors.red
                          : Colors.white,
                      child: Text(
                        'AUTO',
                        style: TextStyle(
                          color: widget.user.houses[0].simulator == 'on'
                              ? Colors.white
                              : Colors.grey,
                        ),
                      ),
                    ),
                    onLongPress: () {
                      String path = widget.user.houses[0].path;
                      String simulator = 'on';
                      if (widget.user.houses[0].simulator == 'on')
                        simulator = 'off';
                      Map<String, dynamic> value = {'simulator': simulator};
                      DataBaseService().updateData(path, value);
                    },
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.home),
                    onPressed: () {
                      widget.toggleView(0);
                    },
                  ),
                ],

                bottom: TabBar(
                  indicatorWeight: 3.5,
                  tabs: createTabs(),
                  labelColor: Colors.teal,
                  indicatorColor: Colors.teal,
                  unselectedLabelColor: Colors.blueGrey[200],
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              drawer: SideBar(
                user: this.widget.user,
                toggleView: widget.toggleView,
                bodyIndex: widget.bodyIndex,
              ),
              body: TabBarView(
                children: createTabBarViews(),
              ),
              bottomNavigationBar: BottomNavigationBar(
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home one',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home two',
                  ),
                ],
              ),
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              iconTheme: IconThemeData(color: Colors.teal[800]),
              title: Text(
                Constants.appName,
                style: TextStyle(
                  color: Colors.teal[800],
                ),
              ),
              backgroundColor: Colors.white,
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.home),
                  onPressed: () {
                    widget.toggleView(0);
                  },
                )
              ],
            ),
            drawer: SideBar(
              user: this.widget.user,
              toggleView: widget.toggleView,
              bodyIndex: widget.bodyIndex,
            ),
            body: Loading(),
          );
        }
      },
    );
  }
}
