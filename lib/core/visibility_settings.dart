import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_repository.dart';

/// Which parts of the home this phone shows. Saved on this phone only, one
/// choice per linked home (Firebase project).
///
/// - Show everything (default), or
/// - Show only the chosen rooms. Floors without a chosen room are hidden, and
///   rooms added later stay hidden until someone ticks them.
///
class VisibilitySettings extends ChangeNotifier {
  VisibilitySettings._();
  static final instance = VisibilitySettings._();

  String _project = '';
  bool _limited = false;
  Set<String> _rooms = {};
  int _home = 0;

  bool get limited => _limited;
  Set<String> get shownRooms => Set.unmodifiable(_rooms);

  /// The number of the home this phone opens (when there are several).
  int get selectedHome => _home;

  String get _kLimited => 'vis.$_project.limited';
  String get _kRooms => 'vis.$_project.rooms';
  String get _kHome => 'vis.$_project.home';

  Future<void> load(String projectId) async {
    _project = projectId;
    try {
      final p = await SharedPreferences.getInstance();
      _limited = p.getBool(_kLimited) ?? false;
      _rooms = (p.getStringList(_kRooms) ?? const []).toSet();
      _home = p.getInt(_kHome) ?? 0;
    } catch (_) {
      _limited = false;
      _rooms = {};
      _home = 0;
    }
    notifyListeners();
  }

  Future<void> save({required bool limited, required Set<String> rooms}) async {
    _limited = limited;
    _rooms = {...rooms};
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kLimited, limited);
      await p.setStringList(_kRooms, _rooms.toList());
    } catch (_) {}
  }

  Future<void> selectHome(int index) async {
    _home = index;
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setInt(_kHome, index);
    } catch (_) {}
  }

  /// The home to show from the list: the chosen one, or the first.
  Home? pick(List<Home> homes) {
    if (homes.isEmpty) return null;
    for (final h in homes) {
      if (h.index == _home) return h;
    }
    return homes.first;
  }

  bool showsRoom(String roomId) => !_limited || _rooms.contains(roomId);

  /// The home as this phone should show it.
  Home filter(Home h) {
    if (!_limited) return h;
    final floors = <Floor>[
      for (final f in h.floors)
        if (f.rooms.any((r) => showsRoom(r.id)))
          _limit(f),
    ];
    return Home(id: h.id, index: h.index, name: h.name, floors: floors);
  }

  /// A floor with only the shown rooms, and only their lamps.
  Floor _limit(Floor f) {
    final rooms = [for (final r in f.rooms) if (showsRoom(r.id)) r];
    final used = {
      for (final r in rooms) ...[
        ...r.lampPositions,
        for (final s in r.subRooms) ...s.lampPositions,
      ],
    };
    return Floor(
      id: f.id,
      name: f.name,
      index: f.index,
      order: f.order,
      rooms: rooms,
      lamps: [for (final l in f.lamps) if (used.contains(l.position)) l],
    );
  }
}
