import 'package:firebase_database/firebase_database.dart';

/// Room types offered in the configuration.
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

/// How a lamp is controlled: a dimmer (0 to 100) or a simple switch.
enum LampMode { dimmer, onOff }

LampMode lampModeFrom(Object? v) => v == 'dimmer' ? LampMode.dimmer : LampMode.onOff;
String lampModeValue(LampMode m) => m == LampMode.dimmer ? 'dimmer' : 'switch';

/// A real lamp, stored in its floor's `lamps` list.
///
/// The app writes `order` ("none", then 0 to 100) and `locked` ("none", then
/// true or false). The board writes `state` (0 to 100) and `lockstate`.
class Lamp {
  Lamp({
    required this.index,
    required this.name,
    this.state = 0,
    this.order,
    this.locked,
    this.lockstate = false,
    this.mode = LampMode.onOff,
  });

  /// Place in the floor's list, from 0. Rooms refer to it as `index + 1`.
  final int index;
  final String name;
  final int state;
  final Object? order;
  final Object? locked;
  final bool lockstate;
  final LampMode mode;

  int get position => index + 1;
  bool get isOn => state > 0;

  /// The level the app last asked for, when the board has not reached it yet.
  int? get pendingLevel {
    final o = order;
    if (o is num && o.round() != state) return o.round();
    return null;
  }

  /// The lock the app last asked for, when the board has not confirmed it.
  bool? get pendingLock {
    final l = locked;
    if (l is bool && l != lockstate) return l;
    return null;
  }
}

/// A room. Holds only references (`position`, from 1) to its floor's lamps,
/// and may hold one level of sub-rooms.
class Room {
  Room({
    required this.id,
    required this.name,
    required this.type,
    this.index = 0,
    this.subIndex,
    List<int>? lampPositions,
    List<Room>? subRooms,
  })  : lampPositions = lampPositions ?? [],
        subRooms = subRooms ?? [];

  /// Stable id on this phone, for example "0/1/2" (home/floor/room).
  final String id;
  final String name;
  final String type;
  final int index;
  final int? subIndex;
  final List<int> lampPositions;
  final List<Room> subRooms;

  bool get isSub => subIndex != null;
}

class Floor {
  Floor({
    required this.id,
    required this.name,
    this.index = 0,
    this.order = 0,
    List<Room>? rooms,
    List<Lamp>? lamps,
  })  : rooms = rooms ?? [],
        lamps = lamps ?? [];

  final String id;
  final String name;
  final int index;
  final int order;
  final List<Room> rooms;

  /// The floor's lamps that are not removed.
  final List<Lamp> lamps;

  Lamp? lampAt(int position) {
    for (final l in lamps) {
      if (l.position == position) return l;
    }
    return null;
  }

  /// The lamps of a room (not its sub-rooms).
  List<Lamp> lampsOf(Room r) => [for (final p in r.lampPositions) ?lampAt(p)];

  /// The lamps of a room and its sub-rooms.
  List<Lamp> allLampsOf(Room r) => [
        ...lampsOf(r),
        for (final s in r.subRooms) ...lampsOf(s),
      ];

  /// Lamps that no room refers to.
  List<Lamp> get freeLamps {
    final used = <int>{
      for (final r in rooms) ...[
        ...r.lampPositions,
        for (final s in r.subRooms) ...s.lampPositions,
      ],
    };
    return [for (final l in lamps) if (!used.contains(l.position)) l];
  }
}

class Home {
  Home({required this.id, required this.name, required this.floors, this.index = 0});
  final String id;
  final String name;
  final int index;
  final List<Floor> floors;

  int get roomCount => floors.fold(0, (n, f) => n + f.rooms.length);
  int get lampCount => floors.fold(0, (n, f) => n + f.lamps.length);
}

/// Reads and writes the homes in the Realtime Database.
///
/// Layout (lists, so the board can find things by number; items are never
/// deleted, only marked `archived: true`, so numbers never move):
///   homes/{h}: name, createdAt, createdBy
///   homes/{h}/floors/{f}: name
///   homes/{h}/floors/{f}/lamps/{l}: name, order, state, locked, lockstate, mode
///   homes/{h}/floors/{f}/rooms/{r}: name, type, lamps/{i}/position
///   homes/{h}/floors/{f}/rooms/{r}/rooms/{s}: name, type, lamps/{i}/position
class HomeRepository {
  HomeRepository({FirebaseDatabase? db}) : _dbOverride = db;
  final FirebaseDatabase? _dbOverride;
  FirebaseDatabase get _db => _dbOverride ?? FirebaseDatabase.instance;

  DatabaseReference get _homes => _db.ref('homes');
  DatabaseReference _home(int h) => _homes.child('$h');
  DatabaseReference _floor(int h, int f) => _home(h).child('floors/$f');
  DatabaseReference _lamp(int h, int f, int l) => _floor(h, f).child('lamps/$l');
  DatabaseReference _room(int h, int f, Room r) => r.isSub
      ? _floor(h, f).child('rooms/${r.index}/rooms/${r.subIndex}')
      : _floor(h, f).child('rooms/${r.index}');

  /// All homes that are not removed, live.
  Stream<List<Home>> watchHomes() =>
      _homes.onValue.map((e) => parseHomes(e.snapshot.value));

  /// The next free number in a list.
  Future<int> _next(DatabaseReference list) async {
    final s = await list.orderByKey().limitToLast(1).get();
    var n = 0;
    for (final c in s.children) {
      final k = int.tryParse(c.key ?? '');
      if (k != null && k + 1 > n) n = k + 1;
    }
    return n;
  }

  Future<int> createHome(String name, String uid, {List<String> floors = const []}) async {
    final h = await _next(_homes);
    await _home(h).set({
      'name': name.trim(),
      'createdAt': ServerValue.timestamp,
      'createdBy': uid,
      if (floors.isNotEmpty)
        'floors': {
          for (var i = 0; i < floors.length; i++) '$i': {'name': floors[i]},
        },
    });
    return h;
  }

  Future<void> renameHome(int h, String name) =>
      _home(h).child('name').set(name.trim());

  Future<void> archiveHome(int h) => _home(h).child('archived').set(true);

  Future<void> addFloor(int h, String name) async {
    final list = _home(h).child('floors');
    final f = await _next(list);
    await list.child('$f').set({'name': name.trim()});
  }

  Future<void> renameFloor(int h, int f, String name) =>
      _floor(h, f).child('name').set(name.trim());

  Future<void> archiveFloor(int h, Floor floor) async {
    await _turnOff(h, floor.index, floor.lamps);
    await _floor(h, floor.index).child('archived').set(true);
  }

  Future<void> addRoom(int h, int f, String name, String type, {Room? parent}) async {
    final list = parent == null
        ? _floor(h, f).child('rooms')
        : _floor(h, f).child('rooms/${parent.index}/rooms');
    final r = await _next(list);
    await list.child('$r').set({'name': name.trim(), 'type': type});
  }

  Future<void> updateRoom(int h, int f, Room r, String name, String type) =>
      _room(h, f, r).update({'name': name.trim(), 'type': type});

  /// Removes a room: its lamps are turned off and marked removed too.
  Future<void> archiveRoom(int h, Floor floor, Room r) async {
    final lamps = floor.allLampsOf(r);
    await _turnOff(h, floor.index, lamps);
    for (final l in lamps) {
      await _lamp(h, floor.index, l.index).child('archived').set(true);
    }
    await _room(h, floor.index, r).child('archived').set(true);
  }

  /// Adds a new lamp to the floor's list and puts it in the room.
  Future<void> addLamp(int h, Floor floor, Room r, String name, LampMode mode) async {
    final list = _floor(h, floor.index).child('lamps');
    final l = await _next(list);
    await list.child('$l').set({
      'name': name.trim(),
      'order': 'none',
      'state': 0,
      'locked': 'none',
      'lockstate': false,
      'mode': lampModeValue(mode),
    });
    await _setRoomLamps(h, floor.index, r, [...r.lampPositions, l + 1]);
  }

  /// Puts a lamp that is already on the floor into the room.
  Future<void> assignLamp(int h, int f, Room r, Lamp lamp) =>
      _setRoomLamps(h, f, r, [...r.lampPositions, lamp.position]);

  Future<void> renameLamp(int h, int f, Lamp lamp, String name) =>
      _lamp(h, f, lamp.index).child('name').set(name.trim());

  /// Turns the lamp off, takes it out of the room and marks it removed.
  Future<void> archiveLamp(int h, int f, Room r, Lamp lamp) async {
    await _turnOff(h, f, [lamp]);
    await _setRoomLamps(
        h, f, r, [for (final p in r.lampPositions) if (p != lamp.position) p]);
    await _lamp(h, f, lamp.index).child('archived').set(true);
  }

  Future<void> _setRoomLamps(int h, int f, Room r, List<int> positions) =>
      _room(h, f, r).child('lamps').set({
        for (var i = 0; i < positions.length; i++) '$i': {'position': positions[i]},
      });

  Future<void> _turnOff(int h, int f, List<Lamp> lamps) async {
    for (final l in lamps) {
      if (l.isOn || (l.order is num && l.order != 0)) {
        try {
          await setLevel(h, f, l, 0);
        } catch (_) {}
      }
    }
  }

  // ----- Control -----

  /// Asks the board for a level: writes "none", then the number (0 to 100).
  Future<void> setLevel(int h, int f, Lamp lamp, int level) async {
    final ref = _lamp(h, f, lamp.index).child('order');
    await ref.set('none');
    await ref.set(level.clamp(0, 100));
  }

  /// Asks the board to ignore (true) or obey (false) the wall switch.
  Future<void> setLocked(int h, int f, Lamp lamp, bool locked) async {
    final ref = _lamp(h, f, lamp.index).child('locked');
    await ref.set('none');
    await ref.set(locked);
  }

  Future<void> setMode(int h, int f, Lamp lamp, LampMode mode) =>
      _lamp(h, f, lamp.index).child('mode').set(lampModeValue(mode));

  // ----- Reading -----

  /// Reads a Firebase list, which comes back as a List (with gaps as null)
  /// or as a Map with number keys.
  static List<(int, Map)> _items(Object? raw) {
    final out = <(int, Map)>[];
    if (raw is List) {
      for (var i = 0; i < raw.length; i++) {
        final v = raw[i];
        if (v is Map) out.add((i, v));
      }
    } else if (raw is Map) {
      raw.forEach((k, v) {
        final i = int.tryParse(k.toString());
        if (i != null && v is Map) out.add((i, v));
      });
      out.sort((a, b) => a.$1.compareTo(b.$1));
    }
    return out;
  }

  static bool _archived(Map m) => m['archived'] == true;

  static int _level(Object? v) {
    if (v is num) return v.round().clamp(0, 100);
    if (v is String) {
      if (v == 'on') return 100;
      return (num.tryParse(v)?.round() ?? 0).clamp(0, 100);
    }
    if (v == true) return 100;
    return 0;
  }

  static List<Home> parseHomes(Object? raw) => [
        for (final (h, m) in _items(raw))
          if (!_archived(m)) parseHome(h, m),
      ];

  static Home parseHome(int h, Map m) {
    final floors = <Floor>[];
    for (final (f, fv) in _items(m['floors'])) {
      if (_archived(fv)) continue;
      final lamps = <Lamp>[
        for (final (l, lv) in _items(fv['lamps']))
          if (!_archived(lv))
            Lamp(
              index: l,
              name: (lv['name'] ?? 'Lamp ${l + 1}').toString(),
              state: _level(lv['state']),
              order: lv['order'],
              locked: lv['locked'],
              lockstate: lv['lockstate'] == true,
              mode: lampModeFrom(lv['mode']),
            ),
      ];
      final live = {for (final l in lamps) l.position};
      List<int> refs(Map rv) => [
            for (final (_, x) in _items(rv['lamps']))
              if (x['position'] is num && live.contains((x['position'] as num).toInt()))
                (x['position'] as num).toInt(),
          ];
      final rooms = <Room>[];
      for (final (r, rv) in _items(fv['rooms'])) {
        if (_archived(rv)) continue;
        rooms.add(Room(
          id: '$h/$f/$r',
          name: (rv['name'] ?? 'Room ${r + 1}').toString(),
          type: (rv['type'] ?? 'living room').toString(),
          index: r,
          lampPositions: refs(rv),
          subRooms: [
            for (final (s, sv) in _items(rv['rooms']))
              if (!_archived(sv))
                Room(
                  id: '$h/$f/$r/$s',
                  name: (sv['name'] ?? 'Room ${s + 1}').toString(),
                  type: (sv['type'] ?? 'living room').toString(),
                  index: r,
                  subIndex: s,
                  lampPositions: refs(sv),
                ),
          ],
        ));
      }
      floors.add(Floor(
        id: '$h/$f',
        name: (fv['name'] ?? (f == 0 ? 'Ground floor' : 'Floor $f')).toString(),
        index: f,
        order: f,
        rooms: rooms,
        lamps: lamps,
      ));
    }
    return Home(
      id: '$h',
      index: h,
      name: (m['name'] ?? 'Home ${h + 1}').toString(),
      floors: floors,
    );
  }
}
