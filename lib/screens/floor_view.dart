import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/display_settings.dart';
import '../core/home_repository.dart';
import '../core/visibility_settings.dart';
import '../ui/room_icons.dart';

/// Colors of the floor screen, for light and dark themes.
class FloorPalette {
  const FloorPalette._({
    required this.dark,
    required this.ink,
    required this.muted,
    required this.line,
    required this.segBg,
    required this.pill,
    required this.sheet,
    required this.scrim,
    required this.tileOn,
    required this.tileOff,
    required this.off,
    required this.offIcon,
    required this.accent,
    required this.tints,
  });

  final bool dark;
  final Color ink, muted, line, segBg, pill, sheet, scrim;
  final Color tileOn, tileOff, off, offIcon, accent;
  final Map<String, Color> tints;

  static const warm = Color(0xFFFFC857);
  static const onWarm = Color(0xFF3A2600);

  static const light = FloorPalette._(
    dark: false,
    ink: Color(0xFF10262B),
    muted: Color(0xFF465F66),
    line: Color(0x2410262B),
    segBg: Color(0xFFD2DDDA),
    pill: Color(0xFFFFFFFF),
    sheet: Color(0xFFFFFFFF),
    scrim: Color(0x2E10262B),
    tileOn: Color(0xFFFFF6E3),
    tileOff: Color(0xFFE8EEED),
    off: Color(0xFFD6E0DE),
    offIcon: Color(0xFF5F777C),
    accent: Color(0xFF0B8F80),
    tints: {
      'hall': Color(0xFFDCE3E7),
      'living': Color(0xFFD2E3E8),
      'kitchen': Color(0xFFE8E3CB),
      'bathroom': Color(0xFFCFE6EA),
      'stairs': Color(0xFFE0D9EC),
      'bedroom': Color(0xFFDBD9EF),
    },
  );

  static const night = FloorPalette._(
    dark: true,
    ink: Color(0xFFEEF6F5),
    muted: Color(0xFF9FB7BB),
    line: Color(0x1AFFFFFF),
    segBg: Color(0x14FFFFFF),
    pill: Color(0xFF1C3C47),
    sheet: Color(0xFF10262F),
    scrim: Color(0x66040C10),
    tileOn: Color(0xFF173843),
    tileOff: Color(0xFF142F38),
    off: Color(0x12FFFFFF),
    offIcon: Color(0xFF8FA9AE),
    accent: Color(0xFF3FE0C5),
    tints: {
      'hall': Color(0xFF1F2A31),
      'living': Color(0xFF173441),
      'kitchen': Color(0xFF2A2B1D),
      'bathroom': Color(0xFF11343F),
      'stairs': Color(0xFF28233A),
      'bedroom': Color(0xFF211F3E),
    },
  );

  static FloorPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? night : light;

  Color tint(String type) => tints[_family(type)]!;

  static String _family(String type) => switch (type) {
        'living room' || 'dining room' || 'livingroom' => 'living',
        'bedroom' || 'office' => 'bedroom',
        'kitchen' => 'kitchen',
        'bathroom' || 'toilet' => 'bathroom',
        'stairs' || 'corridor' => 'stairs',
        _ => 'hall',
      };
}

/// Shows a snack bar when sending to the board fails.
Future<void> _send(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Could not send. Check the internet connection.')));
    }
  }
}

String _countLabel(int n, String one, String many) => '$n ${n == 1 ? one : many}';

/// The Home page: floors as tabs, each room as a panel. Tap a panel to open
/// it on top of the floor and control its lamps.
class FloorHomeView extends StatefulWidget {
  const FloorHomeView({
    super.key,
    required this.repo,
    required this.isOwner,
    required this.onConfigure,
  });

  final HomeRepository repo;
  final bool isOwner;
  final VoidCallback onConfigure;

  @override
  State<FloorHomeView> createState() => _FloorHomeViewState();
}

class _FloorHomeViewState extends State<FloorHomeView> {
  final _homes = ValueNotifier<List<Home>?>(null);
  StreamSubscription<List<Home>>? _sub;
  Object? _error;
  int _floor = 0;

  VisibilitySettings get _vis => VisibilitySettings.instance;

  @override
  void initState() {
    super.initState();
    _sub = widget.repo.watchHomes().listen(
      (h) {
        _homes.value = h;
        if (_error != null) setState(() => _error = null);
      },
      onError: (Object e) {
        if (mounted) setState(() => _error = e);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _homes.dispose();
    super.dispose();
  }

  /// The home as this phone shows it.
  Home? _current() {
    final all = _homes.value;
    if (all == null) return null;
    final h = _vis.pick(all);
    return h == null ? null : _vis.filter(h);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return const HomeMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load the home',
        body: 'Check the internet connection and the database rules.',
      );
    }
    return ListenableBuilder(
      listenable: Listenable.merge([_vis, _homes]),
      builder: (context, _) {
        final all = _homes.value;
        if (all == null) return const Center(child: CircularProgressIndicator());
        final home = _current();
        final shown = _vis.visible(all);
        if (home == null && all.isNotEmpty) {
          return const HomeMessage(
            icon: Icons.visibility_off_outlined,
            title: 'No home shown',
            body: 'Every home is hidden on this phone. '
                'Show one in Settings > Shown on this phone.',
          );
        }
        if (home == null) {
          return HomeMessage(
            icon: Icons.add_home_outlined,
            title: 'No home yet',
            body: widget.isOwner
                ? 'Open Operator > Configuration to create the home, its floors, rooms and lamps.'
                : 'The owner has not created the home yet.',
            action: widget.isOwner
                ? FilledButton.icon(
                    onPressed: widget.onConfigure,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Open Configuration'),
                  )
                : null,
          );
        }
        if (_vis.limited && home.roomCount == 0) {
          return const HomeMessage(
            icon: Icons.visibility_off_outlined,
            title: 'Nothing to show',
            body: 'This phone shows only chosen rooms, and none is chosen yet. '
                'Choose them in Settings > Shown on this phone.',
          );
        }
        final fi = home.floors.isEmpty ? 0 : _floor.clamp(0, home.floors.length - 1);
        return _FloorPage(
          home: home,
          homeCount: shown.length,
          floorIndex: fi,
          onFloor: (i) => setState(() => _floor = i),
          onPickHome: () => _pickHome(shown),
          onOpen: (floor, room) => _openRoom(home.index, floor.index, room.id),
          repo: widget.repo,
        );
      },
    );
  }

  Future<void> _pickHome(List<Home> homes) async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final h in homes)
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(h.name),
              subtitle: Text(
                  '${_countLabel(h.floors.length, 'floor', 'floors')} · ${_countLabel(h.roomCount, 'room', 'rooms')}'),
              trailing: h.index == _vis.pick(homes)?.index
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.pop(c, h.index),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (chosen != null) {
      setState(() => _floor = 0);
      await _vis.selectHome(chosen);
    }
  }

  void _openRoom(int homeIndex, int floorIndex, String roomId) {
    final p = FloorPalette.of(context);
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: p.scrim,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (c, a, b) => ListenableBuilder(
        listenable: Listenable.merge([_vis, _homes]),
        builder: (c, _) {
          final home = _current();
          Floor? floor;
          for (final f in home?.floors ?? const <Floor>[]) {
            if (f.index == floorIndex) floor = f;
          }
          final room = floor == null ? null : _findRoom(floor, roomId);
          if (home == null || home.index != homeIndex || floor == null || room == null) {
            return const SizedBox.shrink();
          }
          return _RoomSheet(repo: widget.repo, home: home, floor: floor, room: room);
        },
      ),
      transitionBuilder: (c, anim, _, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(curve),
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
    );
  }
}

/// The pseudo room that holds a floor's lamps that no room uses.
Room freeLampsRoom(Floor f) => Room(
      id: 'free:${f.id}',
      name: 'Other lamps',
      type: 'hall',
      lampPositions: [for (final l in f.freeLamps) l.position],
    );

Room? _findRoom(Floor f, String id) {
  if (id.startsWith('free:')) {
    return f.freeLamps.isEmpty ? null : freeLampsRoom(f);
  }
  for (final r in f.rooms) {
    if (r.id == id) return r;
  }
  return null;
}

class _FloorPage extends StatelessWidget {
  const _FloorPage({
    required this.home,
    required this.homeCount,
    required this.floorIndex,
    required this.onFloor,
    required this.onPickHome,
    required this.onOpen,
    required this.repo,
  });

  final Home home;
  final int homeCount;
  final int floorIndex;
  final ValueChanged<int> onFloor;
  final VoidCallback onPickHome;
  final void Function(Floor, Room) onOpen;
  final HomeRepository repo;

  @override
  Widget build(BuildContext context) {
    final p = FloorPalette.of(context);
    final text = Theme.of(context).textTheme;
    final allLamps = [for (final f in home.floors) ...f.lamps];
    final on = allLamps.where((l) => l.isOn).length;
    final locked = allLamps.where((l) => l.lockstate).length;
    final floor = home.floors.isEmpty ? null : home.floors[floorIndex];
    final display = DisplaySettings.instance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      children: [
        Row(children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: homeCount > 1 ? onPickHome : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Flexible(
                    child: Text(home.name,
                        overflow: TextOverflow.ellipsis,
                        style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800, color: p.ink)),
                  ),
                  if (homeCount > 1)
                    Icon(Icons.expand_more_rounded, color: p.muted),
                ]),
              ),
            ),
          ),
          IconButton.filledTonal(
            tooltip: p.dark ? 'Light mode' : 'Dark mode',
            onPressed: () =>
                display.setMode(p.dark ? ThemeMode.light : ThemeMode.dark),
            icon: Icon(p.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Chip(
            glow: on > 0,
            icon: Icons.lightbulb_rounded,
            label: on == 0 ? 'All lights off' : '${_countLabel(on, 'light', 'lights')} on',
          ),
          _Chip(
            icon: Icons.lock_rounded,
            label: locked == 0 ? 'No switch locked' : '$locked locked',
          ),
        ]),
        const SizedBox(height: 18),
        if (home.floors.isEmpty)
          Text('No floors yet. Add them in Operator > Configuration.',
              style: text.bodyMedium?.copyWith(color: p.muted))
        else ...[
          _FloorTabs(home: home, selected: floorIndex, onSelect: onFloor),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _RoomGrid(
              key: ValueKey(floor!.id),
              floor: floor,
              onOpen: (r) => onOpen(floor, r),
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.glow = false});
  final IconData icon;
  final String label;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final p = FloorPalette.of(context);
    final bg = glow
        ? (p.dark ? const Color(0x24FFC857) : const Color(0xFFFFF1CF))
        : (p.dark ? const Color(0x10FFFFFF) : Colors.white);
    final fg = glow ? (p.dark ? const Color(0xFFFFD98A) : const Color(0xFF7A4F00)) : p.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: p.line),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: glow ? FloorPalette.warm : fg),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

class _FloorTabs extends StatelessWidget {
  const _FloorTabs({required this.home, required this.selected, required this.onSelect});
  final Home home;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = FloorPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.segBg, borderRadius: BorderRadius.circular(999)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (var i = 0; i < home.floors.length; i++)
            _tab(context, p, home.floors[i], i == selected, () => onSelect(i)),
        ]),
      ),
    );
  }

  Widget _tab(BuildContext context, FloorPalette p, Floor f, bool sel, VoidCallback tap) {
    final on = f.lamps.where((l) => l.isOn).length;
    return GestureDetector(
      onTap: tap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? p.pill : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: sel && !p.dark
              ? const [BoxShadow(color: Color(0x1A10262B), blurRadius: 8, offset: Offset(0, 2))]
              : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(f.name,
              style: TextStyle(
                  color: sel ? p.ink : p.muted,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w600)),
          if (on > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                  color: FloorPalette.warm, borderRadius: BorderRadius.circular(999)),
              child: Text('$on on',
                  style: const TextStyle(
                      color: FloorPalette.onWarm, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
      ),
    );
  }
}

class _RoomGrid extends StatelessWidget {
  const _RoomGrid({super.key, required this.floor, required this.onOpen});
  final Floor floor;
  final ValueChanged<Room> onOpen;

  @override
  Widget build(BuildContext context) {
    final p = FloorPalette.of(context);
    final rooms = [
      ...floor.rooms,
      if (floor.freeLamps.isNotEmpty) freeLampsRoom(floor),
    ];
    if (rooms.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('No rooms on this floor yet.',
            textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
      );
    }
    return LayoutBuilder(builder: (context, c) {
      const gap = 12.0;
      final half = (c.maxWidth - gap) / 2;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final r in rooms)
          SizedBox(
            width: r.subRooms.isEmpty ? half : c.maxWidth,
            child: _RoomCard(floor: floor, room: r, onTap: () => onOpen(r)),
          ),
      ]);
    });
  }
}

/// Lock label for a set of lamps, from what the board reports.
String _lockLabel(List<Lamp> lamps) {
  final n = lamps.where((l) => l.lockstate).length;
  if (n == 0) return 'Unlocked';
  if (n == lamps.length) return 'Locked';
  return '$n locked';
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.floor, required this.room, required this.onTap});
  final Floor floor;
  final Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = FloorPalette.of(context);
    final lamps = floor.allLampsOf(room);
    final on = lamps.where((l) => l.isOn).length;
    final avg = lamps.isEmpty ? 0.0 : lamps.fold<int>(0, (s, l) => s + l.state) / lamps.length;
    final glow = on == 0 ? 0.0 : 0.25 + 0.55 * (avg / 100);
    final wide = room.subRooms.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: on == 0 ? p.tint(room.type) : null,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: p.line),
            gradient: on == 0
                ? null
                : RadialGradient(
                    center: const Alignment(0.8, -1.0),
                    radius: 1.3,
                    colors: [
                      FloorPalette.warm.withValues(alpha: glow),
                      p.tint(room.type),
                    ],
                    stops: const [0, 0.75],
                  ),
          ),
          child: Stack(children: [
            Positioned(
              right: -14,
              bottom: -18,
              child: Icon(roomIcon(room.type),
                  size: 110, color: p.ink.withValues(alpha: p.dark ? 0.07 : 0.06)),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: wide ? 0 : 156),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: wide ? _wide(p, lamps) : _single(p, lamps, on),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _badge(FloorPalette p, List<Lamp> lamps) {
    final label = lamps.isEmpty ? 'No lamps' : _lockLabel(lamps);
    final locked = lamps.any((l) => l.lockstate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: p.dark ? const Color(0x14FFFFFF) : const Color(0xB3FFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(locked ? Icons.lock_rounded : Icons.lock_open_rounded, size: 12, color: p.muted),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: p.muted, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _icon(FloorPalette p, bool lit) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: lit ? FloorPalette.warm : (p.dark ? const Color(0x14FFFFFF) : const Color(0xCCFFFFFF)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: lit
              ? const [BoxShadow(color: Color(0x73FFC857), blurRadius: 14)]
              : null,
        ),
        child: Icon(roomIcon(room.type),
            size: 21, color: lit ? FloorPalette.onWarm : p.offIcon),
      );

  Widget _single(FloorPalette p, List<Lamp> lamps, int on) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _icon(p, on > 0),
          const SizedBox(height: 18),
          Text(capitalize(room.type).toUpperCase(),
              style: TextStyle(
                  fontSize: 10, letterSpacing: 1, color: p.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(room.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.ink)),
          const SizedBox(height: 4),
          Text(
              lamps.isEmpty
                  ? 'No lamps'
                  : '${_countLabel(lamps.length, 'lamp', 'lamps')} · $on on',
              style: TextStyle(fontSize: 12, color: p.muted)),
          const SizedBox(height: 6),
          _badge(p, lamps),
        ],
      );

  Widget _wide(FloorPalette p, List<Lamp> all) {
    final parts = [room, ...room.subRooms];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _icon(p, all.any((l) => l.isOn)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(capitalize(room.type).toUpperCase(),
                style: TextStyle(
                    fontSize: 10, letterSpacing: 1, color: p.muted, fontWeight: FontWeight.w700)),
            Text(room.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.ink)),
          ]),
        ),
        _badge(p, all),
      ]),
      const SizedBox(height: 22),
      IntrinsicHeight(
        child: Row(children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0)
              Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 10), color: p.line),
            Expanded(child: _section(p, parts[i], i == 0)),
          ],
        ]),
      ),
    ]);
  }

  Widget _section(FloorPalette p, Room r, bool main) {
    final lamps = floor.lampsOf(r);
    final on = lamps.where((l) => l.isOn).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(roomIcon(r.type), size: 14, color: on > 0 ? const Color(0xFFE0A21C) : p.muted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(main ? 'Main' : r.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.ink)),
        ),
      ]),
      const SizedBox(height: 2),
      Text(lamps.isEmpty ? 'No lamps' : '${lamps.length} · $on on',
          style: TextStyle(fontSize: 12, color: p.muted)),
    ]);
  }
}

/// The opened room, on top of the floor.
class _RoomSheet extends StatelessWidget {
  const _RoomSheet({
    required this.repo,
    required this.home,
    required this.floor,
    required this.room,
  });

  final HomeRepository repo;
  final Home home;
  final Floor floor;
  final Room room;

  @override
  Widget build(BuildContext context) {
    final p = FloorPalette.of(context);
    final size = MediaQuery.of(context).size;
    final all = floor.allLampsOf(room);
    final parts = [room, ...room.subRooms];

    Future<void> setAll(bool on) => _send(context, () async {
          for (final l in all) {
            await repo.setLevel(home.index, floor.index, l, on ? 100 : 0);
          }
        });

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: size.height * 0.12, left: 12, right: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520, maxHeight: size.height * 0.74),
            child: Material(
              color: p.sheet,
              elevation: 10,
              shadowColor: const Color(0x5510262B),
              borderRadius: BorderRadius.circular(28),
              clipBehavior: Clip.antiAlias,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
                  child: Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: p.tint(room.type), borderRadius: BorderRadius.circular(14)),
                      child: Icon(roomIcon(room.type), color: p.ink),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(room.name,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800, color: p.ink)),
                        Text(
                            '${floor.name} · ${_countLabel(all.length, 'lamp', 'lamps')} · '
                            '${all.where((l) => l.isOn).length} on',
                            style: TextStyle(color: p.muted, fontSize: 13)),
                      ]),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: p.muted),
                    ),
                  ]),
                ),
                if (all.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            backgroundColor: FloorPalette.warm,
                            foregroundColor: FloorPalette.onWarm,
                          ),
                          onPressed: () => setAll(true),
                          icon: const Icon(Icons.lightbulb_rounded),
                          label: const Text('All on'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            foregroundColor: p.ink,
                            side: BorderSide(color: p.line),
                          ),
                          onPressed: () => setAll(false),
                          icon: const Icon(Icons.lightbulb_outline_rounded),
                          label: const Text('All off'),
                        ),
                      ),
                    ]),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                    children: [
                      if (all.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                              'No lamps in this room yet. Add them in Operator > Configuration.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: p.muted)),
                        ),
                      for (final part in parts) ...[
                        if (parts.length > 1 && floor.lampsOf(part).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
                            child: Row(children: [
                              Icon(roomIcon(part.type), size: 16, color: p.muted),
                              const SizedBox(width: 6),
                              Text(part == room ? room.name : part.name,
                                  style: TextStyle(
                                      color: p.muted, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        for (final l in floor.lampsOf(part))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: LampTile(
                              key: ValueKey('${floor.id}/${l.index}'),
                              lamp: l,
                              onLevel: (v) => _send(
                                  context, () => repo.setLevel(home.index, floor.index, l, v)),
                              onLock: (v) => _send(
                                  context, () => repo.setLocked(home.index, floor.index, l, v)),
                              onMode: (m) => _send(
                                  context, () => repo.setMode(home.index, floor.index, l, m)),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// One lamp: on/off button, lock, level, and the choice of Dimmer or On / Off.
class LampTile extends StatefulWidget {
  const LampTile({
    super.key,
    required this.lamp,
    required this.onLevel,
    required this.onLock,
    required this.onMode,
  });

  final Lamp lamp;
  final ValueChanged<int> onLevel;
  final ValueChanged<bool> onLock;
  final ValueChanged<LampMode> onMode;

  @override
  State<LampTile> createState() => _LampTileState();
}

class _LampTileState extends State<LampTile> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final p = FloorPalette.of(context);
    final l = widget.lamp;
    final on = l.isOn;
    final pending = l.pendingLevel;
    final lockPending = l.pendingLock;
    final shown = _drag?.round() ?? l.state;
    final status = pending != null
        ? 'Sent ${pending == 0 ? 'off' : '$pending%'}, waiting for the board'
        : (on ? 'On' : 'Off');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: on ? p.tileOn : p.tileOff,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: on ? const Color(0x55FFC857) : p.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          GestureDetector(
            onTap: () => widget.onLevel(on ? 0 : 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? FloorPalette.warm : p.off,
                boxShadow: on
                    ? [
                        BoxShadow(
                            color: const Color(0x8CFFC857), blurRadius: 8 + l.state / 4)
                      ]
                    : null,
              ),
              child: Icon(on ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                  color: on ? FloorPalette.onWarm : p.offIcon),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: p.ink)),
              const SizedBox(height: 2),
              Text(status,
                  maxLines: 2,
                  style: TextStyle(
                      fontSize: 12,
                      color: pending != null ? const Color(0xFFB7791F) : p.muted)),
            ]),
          ),
          if (l.mode == LampMode.dimmer)
            Text('$shown%',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: on ? p.ink : p.muted))
          else
            Switch(
              value: pending != null ? pending > 0 : on,
              activeThumbColor: FloorPalette.onWarm,
              activeTrackColor: FloorPalette.warm,
              onChanged: (v) => widget.onLevel(v ? 100 : 0),
            ),
          const SizedBox(width: 4),
          Tooltip(
            message: l.lockstate
                ? 'Wall switch locked. Tap to unlock.'
                : 'Wall switch works. Tap to lock it.',
            child: InkResponse(
              onTap: () => widget.onLock(!(lockPending ?? l.lockstate)),
              radius: 24,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Stack(alignment: Alignment.center, children: [
                  Icon(
                    (lockPending ?? l.lockstate) ? Icons.lock_rounded : Icons.lock_open_rounded,
                    color: l.lockstate ? p.accent : p.muted,
                  ),
                  if (lockPending != null)
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(strokeWidth: 2, color: p.accent),
                    ),
                ]),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: SegmentedButton<LampMode>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                selectedBackgroundColor: p.dark ? const Color(0x333FE0C5) : const Color(0xFFD5EFEB),
                foregroundColor: p.muted,
                selectedForegroundColor: p.ink,
                side: BorderSide(color: p.line),
              ),
              segments: const [
                ButtonSegment(
                    value: LampMode.onOff,
                    icon: Icon(Icons.toggle_on_outlined, size: 18),
                    label: Text('On / Off')),
                ButtonSegment(
                    value: LampMode.dimmer,
                    icon: Icon(Icons.tune_rounded, size: 18),
                    label: Text('Dimmer')),
              ],
              selected: {l.mode},
              onSelectionChanged: (s) => widget.onMode(s.first),
            ),
          ),
        ]),
        if (l.mode == LampMode.dimmer)
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: FloorPalette.warm,
              thumbColor: FloorPalette.warm,
              inactiveTrackColor: p.off,
              trackHeight: 8,
            ),
            child: Slider(
              value: (_drag ?? (pending ?? l.state).toDouble()).clamp(0, 100),
              min: 0,
              max: 100,
              divisions: 20,
              label: '${(_drag ?? l.state).round()}%',
              onChanged: (v) => setState(() => _drag = v),
              onChangeEnd: (v) {
                setState(() => _drag = null);
                widget.onLevel(v.round());
              },
            ),
          ),
      ]),
    );
  }
}

/// A centered icon, title and text, used for empty and error states.
class HomeMessage extends StatelessWidget {
  const HomeMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 24),
            Text(title,
                textAlign: TextAlign.center,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
