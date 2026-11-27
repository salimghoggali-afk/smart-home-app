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
/// Device options inside a room will be added here once devices exist.
class VisibilitySettings extends ChangeNotifier {
  VisibilitySettings._();
  static final instance = VisibilitySettings._();

  String _project = '';
  bool _limited = false;
  Set<String> _rooms = {};

  bool get limited => _limited;
  Set<String> get shownRooms => Set.unmodifiable(_rooms);

  String get _kLimited => 'vis.$_project.limited';
  String get _kRooms => 'vis.$_project.rooms';

  Future<void> load(String projectId) async {
    _project = projectId;
    try {
      final p = await SharedPreferences.getInstance();
      _limited = p.getBool(_kLimited) ?? false;
      _rooms = (p.getStringList(_kRooms) ?? const []).toSet();
    } catch (_) {
      _limited = false;
      _rooms = {};
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

  bool showsRoom(String roomId) => !_limited || _rooms.contains(roomId);

  /// The home as this phone should show it.
  Home filter(Home h) {
    if (!_limited) return h;
    final floors = <Floor>[
      for (final f in h.floors)
        if (f.rooms.any((r) => showsRoom(r.id)))
          Floor(
            id: f.id,
            name: f.name,
            order: f.order,
            rooms: [for (final r in f.rooms) if (showsRoom(r.id)) r],
          ),
    ];
    return Home(id: h.id, name: h.name, floors: floors);
  }
}
