import 'lamp_model/lamp.dart';
import 'room_model/room.dart';
import 'vollet_model/vollet.dart';

class Floor {
  List<List<Room>> rooms = [];
  List<Lamp> lamps = [];
  List<Vollet> volets = [];
  String path;
}
