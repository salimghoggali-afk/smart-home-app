import 'package:firebase_auth/firebase_auth.dart';

import 'floor.dart';
import 'house.dart';
import 'lamp_model/lamp.dart';
import 'room_model/room.dart';
import 'vollet_model/vollet.dart';

class AppUser {
  String uid;
  String firstName = '';
  String lastName = '';
  String birthdayDate = '';
  String creationDate = '';
  String attribute = '';
  String email = '';
  String imgUrl = '';
  List<House> houses = [];

  AppUser(User user) {
    this.uid = user.uid;
    this.email = user.email;
  }

  Future updateUser(Map<dynamic, dynamic> data) async {
    firstName = data["firstName"];
    lastName = data['lastName'];
    birthdayDate = data['birthdayDate'];
    creationDate = data['creationDate'];
    attribute = data['attribute'];
    imgUrl = data['imgUrl'];
  }

  Future updateUserHouses(List<dynamic> data) async {
    houses = [];
    int l = data.length;
    for (var i = 0; i < l; i++) {
      Map<dynamic, dynamic> map = data[i];
      createHouse(map, i);
    }
  }

  Future createHouse(Map<dynamic, dynamic> map, int nbr) async {
    House house = House();
    house.name = map['name'];
    house.creationDate = map['creationDate'];
    house.expDate = map['expDate'];
    house.simulator = map['simulator'];
    house.nbr = nbr;
    house.path = 'Homes/' + uid + '/' + nbr.toString() + '/';
    List<dynamic> data = map['floors'];
    createFloors(data, house);
    houses.add(house);
  }

  Future createFloors(List<dynamic> data, House house) async {
    Floor floor;
    List<dynamic> dataBis;

    int l = 0;

    if (data != null) {
      l = data.length;
    }
    for (var i = 0; i < l; i++) {
      Map<dynamic, dynamic> map = data[i];
      floor = Floor();
      floor.path = house.path + 'floors/' + i.toString() + '/';
      dataBis = map['lamps'];
      createLamps(dataBis, floor);
      dataBis = map['volets'];
      createVollets(dataBis, floor);
      dataBis = map['rooms'];
      createRooms(dataBis, floor);
      house.floors.add(floor);
    }
  }

  Future createRooms(List<dynamic> data, Floor floor) async {
    List<Room> lst;
    Room room;
    List<dynamic> dataBis;
    int l = 0;
    if (data != null) {
      l = data.length;
    }
    for (var i = 0; i < l; i++) {
      Map<dynamic, dynamic> map = data[i];
      lst = [];
      room = Room();
      setRoomAttribute(map, room);
      room.path = floor.path + 'rooms/' + i.toString() + '/';
      dataBis = map['lamps'];
      setLampComponents(dataBis, room, floor);
      dataBis = map['volets'];
      setVoletComponents(dataBis, room, floor);
      lst.add(room);
      dataBis = map['rooms'];
      createSubRooms(dataBis, lst, floor);
      floor.rooms.add(lst);
    }
  }

  Future createSubRooms(List<dynamic> data, List<Room> lst, Floor floor) async {
    Room room;
    List<dynamic> dataBis;
    int l = 0;
    if (data != null) {
      l = data.length;
    }
    for (var i = 0; i < l; i++) {
      Map<dynamic, dynamic> map = data[i];
      room = Room();
      setRoomAttribute(map, room);
      room.path = lst[0].path + 'rooms/' + i.toString() + '/';
      dataBis = map['lamps'];
      setLampComponents(dataBis, room, floor);
      dataBis = map['volets'];
      setVoletComponents(dataBis, room, floor);
      lst.add(room);
    }
  }

  Future setRoomAttribute(Map<dynamic, dynamic> map, Room room) async {
    room.name = map['name'];
    room.type = map['type'];
    room.locked = map['locked'];
  }

  Future setLampComponents(List<dynamic> data, Room room, Floor floor) async {
    int l = 0;
    if (data != null) {
      l = data.length;
    }
    for (var i = 0; i < l; i++) {
      Map<dynamic, dynamic> map = data[i];
      int j = map['position'] - 1;
      room.lamps.add(floor.lamps[j]);
    }
  }

  Future setVoletComponents(List<dynamic> data, Room room, Floor floor) async {
    int l = 0;
    if (data != null) {
      l = data.length;
    }
    for (var i = 0; i < l; i++) {
      Map<dynamic, dynamic> map = data[i];
      int j = map['position'] - 1;
      room.vollets.add(floor.volets[j]);
    }
  }

  Future createLamps(List<dynamic> data, Floor floor) async {
    Lamp lamp;
    int l = 0;
    if (data != null) {
      l = data.length;
    }
    for (var i = 0; i < l; i++) {
      Map<dynamic, dynamic> map = data[i];
      lamp = Lamp();
      lamp.position = map['position'];
      lamp.state = map['state'];
      lamp.name = map['name'];
      lamp.path = floor.path + 'lamps/' + i.toString() + '/';
      floor.lamps.add(lamp);
    }
  }

  Future createVollets(List<dynamic> data, Floor floor) async {
    Vollet volet;
    int l = 0;
    if (data != null) {
      l = data.length;
    }
    for (var i = 0; i < l; i++) {
      Map<dynamic, dynamic> map = data[i];
      volet = Vollet();
      volet.coursetime = map['coursetime'];
      volet.fincourse = map['fincourse'];
      volet.locked = map['locked'];
      volet.lockedorder = map['lockedorder'];
      volet.msg = map['msg'];
      volet.msgflag = map['msgflag'];
      volet.name = map['name'];
      volet.order = map['order'];
      volet.orderdesired = map['orderdesired'];
      volet.state = map['state'];
      volet.path = floor.path + 'volets/' + i.toString() + '/';
      floor.volets.add(volet);
    }
  }
}
