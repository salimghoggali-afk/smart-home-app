import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_repository.dart';

/// How this phone shows one home.
enum HomeShow {
  /// The whole home.
  all,

  /// Only the ticked rooms.
  chosen,

  /// Not at all: the home is left out of the home list on this phone.
  hidden,
}

/// Which homes, and which parts of them, this phone shows. Saved on this
/// phone only, per linked Firebase project and per home in it.
///
/// - Each home: show everything (default), only the chosen rooms, or hide it.
/// - With "only the chosen rooms", floors without a chosen room are hidden,
///   and rooms added later stay hidden until someone ticks them.
class VisibilitySettings extends ChangeNotifier {
  VisibilitySettings._();
  static final instance = VisibilitySettings._();

  String _project = '';
  // v1.5/v1.6 kept one choice for the whole project; it is the default for
  // homes that have no choice of their own yet.
  bool _legacyLimited = false;
  final Map<int, HomeShow> _modes = {};
  Set<String> _rooms = {};
  int _home = 0;

  /// True when the open home shows only chosen rooms.
  bool get limited => modeOf(_home) == HomeShow.chosen;
  Set<String> get shownRooms => Set.unmodifiable(_rooms);

  /// The number of the home this phone opens (when there are several).
  int get selectedHome => _home;

  String get _kLimited => 'vis.$_project.limited';
  String get _kRooms => 'vis.$_project.rooms';
  String get _kHome => 'vis.$_project.home';
  String _kMode(int h) => 'vis.$_project.h$h.mode';

  Future<void> load(String projectId) async {
    _project = projectId;
    _modes.clear();
    try {
      final p = await SharedPreferences.getInstance();
      _legacyLimited = p.getBool(_kLimited) ?? false;
      _rooms = (p.getStringList(_kRooms) ?? const []).toSet();
      _home = p.getInt(_kHome) ?? 0;
      final prefix = 'vis.$projectId.h';
      for (final k in p.getKeys()) {
        if (!k.startsWith(prefix) || !k.endsWith('.mode')) continue;
        final h = int.tryParse(k.substring(prefix.length, k.length - 5));
        final m = HomeShow.values.where((x) => x.name == p.getString(k));
        if (h != null && m.isNotEmpty) _modes[h] = m.first;
      }
    } catch (_) {
      _legacyLimited = false;
      _rooms = {};
      _home = 0;
    }
    notifyListeners();
  }

  HomeShow modeOf(int home) =>
      _modes[home] ?? (_legacyLimited ? HomeShow.chosen : HomeShow.all);

  Future<void> setMode(int home, HomeShow mode) async {
    _modes[home] = mode;
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setString(_kMode(home), mode.name);
    } catch (_) {}
  }

  Future<void> setRooms(Set<String> rooms) async {
    _rooms = {...rooms};
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setStringList(_kRooms, _rooms.toList());
    } catch (_) {}
  }

  Future<void> selectHome(int index) async {
    _home = index;
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setInt(_kHome, index);
    } catch (_) {}
  }

  /// The homes this phone shows (not hidden).
  List<Home> visible(List<Home> homes) =>
      [for (final h in homes) if (modeOf(h.index) != HomeShow.hidden) h];

  /// The home to show: the chosen one, or the first shown one.
  Home? pick(List<Home> homes) => pickAny(visible(homes));

  /// The chosen home, hidden or not (for Configuration and Settings).
  Home? pickAny(List<Home> homes) {
    if (homes.isEmpty) return null;
    for (final h in homes) {
      if (h.index == _home) return h;
    }
    return homes.first;
  }

  bool showsRoom(String roomId) => _rooms.contains(roomId);

  /// The home as this phone should show it.
  Home filter(Home h) {
    if (modeOf(h.index) != HomeShow.chosen) return h;
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
