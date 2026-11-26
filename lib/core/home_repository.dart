import 'package:firebase_database/firebase_database.dart';

/// Room types offered in the configuration, from the original app.
const roomTypes = <String>[
  'living room',
  'bedroom',
  'kitchen',
  'dining room',
  'bathroom',
  'toilet',
  'office',
  'hall',
  'corridor',
  'stairs',
  'balcony',
  'garage',
  'garden',
  'entrance',
];

class Room {
  Room({required this.id, required this.name, required this.type, this.order = 0});
  final String id;
  final String name;
  final String type;
  final int order;
}

class Floor {
  Floor({required this.id, required this.name, this.order = 0, List<Room>? rooms})
      : rooms = rooms ?? [];
  final String id;
  final String name;
  final int order;
  final List<Room> rooms;
}

class Home {
  Home({required this.id, required this.name, required this.floors});
  final String id;
  final String name;
  final List<Floor> floors;

  int get roomCount => floors.fold(0, (n, f) => n + f.rooms.length);
}

/// Reads and writes the home tree in the Realtime Database.
///
/// Layout (ids are push keys, so items never shift when one is deleted):
///   homes/{homeId}: name, createdAt, createdBy
///   homes/{homeId}/floors/{floorId}: name, order
///   homes/{homeId}/floors/{floorId}/rooms/{roomId}: name, type, order
class HomeRepository {
  HomeRepository({FirebaseDatabase? db}) : _dbOverride = db;
  final FirebaseDatabase? _dbOverride;
  FirebaseDatabase get _db => _dbOverride ?? FirebaseDatabase.instance;

  DatabaseReference get _homes => _db.ref('homes');

  /// The first home, live. Null when none exists yet.
  Stream<Home?> watchHome() => _homes.limitToFirst(1).onValue.map((e) {
        final v = e.snapshot.value;
        if (v is! Map || v.isEmpty) return null;
        final entry = v.entries.first;
        return _parseHome(entry.key.toString(), entry.value);
      });

  Future<String> createHome(String name, String uid) async {
    final ref = _homes.push();
    await ref.set({
      'name': name.trim(),
      'createdAt': ServerValue.timestamp,
      'createdBy': uid,
    });
    return ref.key!;
  }

  Future<void> renameHome(String homeId, String name) =>
      _homes.child('$homeId/name').set(name.trim());

  Future<void> addFloor(String homeId, String name, int order) =>
      _homes.child('$homeId/floors').push().set({'name': name.trim(), 'order': order});

  Future<void> renameFloor(String homeId, String floorId, String name) =>
      _homes.child('$homeId/floors/$floorId/name').set(name.trim());

  Future<void> deleteFloor(String homeId, String floorId) =>
      _homes.child('$homeId/floors/$floorId').remove();

  Future<void> addRoom(
          String homeId, String floorId, String name, String type, int order) =>
      _homes.child('$homeId/floors/$floorId/rooms').push().set({
        'name': name.trim(),
        'type': type,
        'order': order,
      });

  Future<void> updateRoom(String homeId, String floorId, String roomId,
          String name, String type) =>
      _homes
          .child('$homeId/floors/$floorId/rooms/$roomId')
          .update({'name': name.trim(), 'type': type});

  Future<void> deleteRoom(String homeId, String floorId, String roomId) =>
      _homes.child('$homeId/floors/$floorId/rooms/$roomId').remove();

  static Home _parseHome(String id, Object? raw) {
    final m = raw is Map ? raw : const {};
    final floors = <Floor>[];
    final rawFloors = m['floors'];
    if (rawFloors is Map) {
      rawFloors.forEach((fid, fv) {
        if (fv is! Map) return;
        final rooms = <Room>[];
        final rawRooms = fv['rooms'];
        if (rawRooms is Map) {
          rawRooms.forEach((rid, rv) {
            if (rv is! Map) return;
            rooms.add(Room(
              id: rid.toString(),
              name: (rv['name'] ?? '').toString(),
              type: (rv['type'] ?? 'living room').toString(),
              order: (rv['order'] as num?)?.toInt() ?? 0,
            ));
          });
        }
        rooms.sort((a, b) => a.order.compareTo(b.order));
        floors.add(Floor(
          id: fid.toString(),
          name: (fv['name'] ?? '').toString(),
          order: (fv['order'] as num?)?.toInt() ?? 0,
          rooms: rooms,
        ));
      });
    }
    floors.sort((a, b) => a.order.compareTo(b.order));
    return Home(id: id, name: (m['name'] ?? 'My home').toString(), floors: floors);
  }
}
