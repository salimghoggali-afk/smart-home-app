import 'package:my_home/models/lamp_model/lamp.dart';
import 'package:my_home/models/vollet_model/vollet.dart';

class Room {
  String name = '';
  String type = '';
  String path = '';
  bool locked = false;
  List<Lamp> lamps = [];
  List<Vollet> vollets = [];
}
