import 'package:material_ui/material_ui.dart';

import '../core/home_repository.dart';
import '../core/visibility_settings.dart';
import '../ui/room_icons.dart';

/// Operator screen to create the homes, floors, rooms and lamps.
///
/// Nothing is ever deleted from Firebase: "Remove" marks the item
/// `archived: true`, so the numbers the board uses never move.
class ConfigurationScreen extends StatelessWidget {
  const ConfigurationScreen({super.key, required this.repo, required this.uid});

  final HomeRepository repo;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final vis = VisibilitySettings.instance;
    return ListenableBuilder(
      listenable: vis,
      builder: (context, _) => StreamBuilder<List<Home>>(
        stream: repo.watchHomes(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'The database refused access. Check that the rules from the guide are published.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final homes = snap.data;
          if (homes == null) return const Center(child: CircularProgressIndicator());
          final home = vis.pick(homes);
          return home == null
              ? _CreateHome(repo: repo, uid: uid)
              : _EditHome(repo: repo, uid: uid, home: home, homes: homes);
        },
      ),
    );
  }
}

Future<void> _run(BuildContext context, Future<void> Function() action,
    {String? done}) async {
  try {
    await action();
    if (done != null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(done)));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not save. Check the internet and the database rules.')));
    }
  }
}

Future<String?> _askName(BuildContext context, String title, String initial,
    {String label = 'Name'}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (v) => Navigator.pop(d, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(d, c.text), child: const Text('Save')),
      ],
    ),
  );
}

Future<bool> _confirm(BuildContext context, String title, String body) async =>
    await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Remove')),
        ],
      ),
    ) ==
    true;

String _floorName(int i) => i == 0 ? 'Ground floor' : 'Floor $i';

String _plural(int n, String one, String many) => '$n ${n == 1 ? one : many}';

class _CreateHome extends StatefulWidget {
  const _CreateHome({required this.repo, required this.uid, this.onDone});
  final HomeRepository repo;
  final String uid;
  final VoidCallback? onDone;

  @override
  State<_CreateHome> createState() => _CreateHomeState();
}

class _CreateHomeState extends State<_CreateHome> {
  final _name = TextEditingController(text: 'My home');
  int _floors = 1;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    await _run(context, () async {
      final h = await widget.repo.createHome(_name.text, widget.uid,
          floors: [for (var i = 0; i < _floors; i++) _floorName(i)]);
      await VisibilitySettings.instance.selectHome(h);
    }, done: 'Home created. Now add the rooms and lamps.');
    if (mounted) setState(() => _busy = false);
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Create a home',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
            'This saves the home in the Realtime Database of the linked project, '
            'under homes. You can rename everything later.',
            style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 28),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
              labelText: 'Home name', prefixIcon: Icon(Icons.home_outlined)),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              const Icon(Icons.layers_outlined),
              const SizedBox(width: 16),
              Expanded(
                child: Text('Number of floors',
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ),
              IconButton.filledTonal(
                onPressed: _floors > 1 ? () => setState(() => _floors--) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 40,
                child: Text('$_floors', textAlign: TextAlign.center, style: text.titleLarge),
              ),
              IconButton.filledTonal(
                onPressed: _floors < 10 ? () => setState(() => _floors++) : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _busy ? null : _create,
          icon: const Icon(Icons.add_home_outlined),
          label: const Text('Create home'),
        ),
      ],
    );
  }
}

class _EditHome extends StatelessWidget {
  const _EditHome({
    required this.repo,
    required this.uid,
    required this.home,
    required this.homes,
  });
  final HomeRepository repo;
  final String uid;
  final Home home;
  final List<Home> homes;

  Future<void> _homeMenu(BuildContext context, String v) async {
    switch (v) {
      case 'rename':
        final n = await _askName(context, 'Rename home', home.name);
        if (n != null && n.trim().isNotEmpty && context.mounted) {
          await _run(context, () => repo.renameHome(home.index, n));
        }
      case 'new':
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (c) => Scaffold(
            appBar: AppBar(title: const Text('New home')),
            body: _CreateHome(
                repo: repo, uid: uid, onDone: () => Navigator.of(c).maybePop()),
          ),
        ));
      case 'remove':
        if (await _confirm(context, 'Remove ${home.name}?',
                'It disappears from the app. Its data stays in Firebase, marked as removed.') &&
            context.mounted) {
          await _run(context, () => repo.archiveHome(home.index), done: 'Home removed.');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Stack(children: [
      ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        children: [
          if (homes.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (final h in homes)
                  ChoiceChip(
                    avatar: const Icon(Icons.home_outlined, size: 18),
                    label: Text(h.name),
                    selected: h.index == home.index,
                    onSelected: (_) => VisibilitySettings.instance.selectHome(h.index),
                  ),
              ]),
            ),
          Card(
            color: scheme.primaryContainer,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              leading: Icon(Icons.home_rounded, color: scheme.onPrimaryContainer),
              title: Text(home.name,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer)),
              subtitle: Text(
                  '${_plural(home.floors.length, 'floor', 'floors')} · '
                  '${_plural(home.roomCount, 'room', 'rooms')} · '
                  '${_plural(home.lampCount, 'lamp', 'lamps')}\nFirebase: homes/${home.index}',
                  style: TextStyle(color: scheme.onPrimaryContainer)),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                iconColor: scheme.onPrimaryContainer,
                onSelected: (v) => _homeMenu(context, v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename home')),
                  PopupMenuItem(value: 'new', child: Text('Add another home')),
                  PopupMenuItem(value: 'remove', child: Text('Remove home')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (final f in home.floors)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  initiallyExpanded: true,
                  shape: const Border(),
                  leading: const Icon(Icons.layers_outlined),
                  title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${_plural(f.rooms.length, 'room', 'rooms')} · ${_plural(f.lamps.length, 'lamp', 'lamps')} · floors/${f.index}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'rename') {
                        final n = await _askName(context, 'Rename floor', f.name);
                        if (n != null && n.trim().isNotEmpty && context.mounted) {
                          await _run(context, () => repo.renameFloor(home.index, f.index, n));
                        }
                      } else if (v == 'remove') {
                        if (await _confirm(context, 'Remove ${f.name}?',
                                'Its lamps are turned off, and the floor with its rooms disappears from the app.') &&
                            context.mounted) {
                          await _run(context, () => repo.archiveFloor(home.index, f));
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'remove', child: Text('Remove')),
                    ],
                  ),
                  children: [
                    for (final r in f.rooms)
                      ListTile(
                        leading: Icon(roomIcon(r.type)),
                        title: Text(r.name),
                        subtitle: Text([
                          capitalize(r.type),
                          _plural(f.allLampsOf(r).length, 'lamp', 'lamps'),
                          if (r.subRooms.isNotEmpty)
                            _plural(r.subRooms.length, 'sub-room', 'sub-rooms'),
                        ].join(' · ')),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _openRoom(context, repo, home.index, f.index, r.id),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () async {
                            final res = await _roomForm(context);
                            if (res != null && context.mounted) {
                              await _run(context,
                                  () => repo.addRoom(home.index, f.index, res.$1, res.$2),
                                  done: 'Room added. Tap it to add lamps.');
                            }
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add room'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (home.floors.isEmpty)
            Text('No floors yet. Tap "Add floor".', style: text.bodyMedium),
        ],
      ),
      Positioned(
        right: 20,
        bottom: 20,
        child: FloatingActionButton.extended(
          onPressed: () async {
            final n = await _askName(context, 'New floor', _floorName(home.floors.length));
            if (n != null && n.trim().isNotEmpty && context.mounted) {
              await _run(context, () => repo.addFloor(home.index, n), done: 'Floor added.');
            }
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add floor'),
        ),
      ),
    ]);
  }
}

void _openRoom(BuildContext context, HomeRepository repo, int h, int f, String roomId) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => _RoomEditor(repo: repo, homeIndex: h, floorIndex: f, roomId: roomId),
  ));
}

/// One room: its name and type, its lamps and its sub-rooms.
class _RoomEditor extends StatelessWidget {
  const _RoomEditor({
    required this.repo,
    required this.homeIndex,
    required this.floorIndex,
    required this.roomId,
  });
  final HomeRepository repo;
  final int homeIndex;
  final int floorIndex;
  final String roomId;

  static (Floor, Room)? _find(List<Home> homes, int h, int f, String id) {
    for (final home in homes) {
      if (home.index != h) continue;
      for (final floor in home.floors) {
        if (floor.index != f) continue;
        for (final r in floor.rooms) {
          if (r.id == id) return (floor, r);
          for (final s in r.subRooms) {
            if (s.id == id) return (floor, s);
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Home>>(
      stream: repo.watchHomes(),
      builder: (context, snap) {
        final found = snap.data == null ? null : _find(snap.data!, homeIndex, floorIndex, roomId);
        if (found == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: snap.data == null
                  ? const CircularProgressIndicator()
                  : const Text('This room was removed.'),
            ),
          );
        }
        final (floor, room) = found;
        return Scaffold(
          appBar: AppBar(title: Text(room.name)),
          body: _body(context, floor, room),
        );
      },
    );
  }

  Widget _body(BuildContext context, Floor floor, Room room) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final lamps = floor.lampsOf(room);
    final free = floor.freeLamps;
    final path = room.isSub
        ? 'floors/${floor.index}/rooms/${room.index}/rooms/${room.subIndex}'
        : 'floors/${floor.index}/rooms/${room.index}';

    Widget section(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
          child: Text(t, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Icon(roomIcon(room.type), color: scheme.onPrimaryContainer),
            ),
            title: Text(room.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${capitalize(room.type)} · ${floor.name}\n$path'),
            isThreeLine: true,
            trailing: IconButton(
              tooltip: 'Edit name and type',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final res = await _roomForm(context, room: room);
                if (res != null && context.mounted) {
                  await _run(context,
                      () => repo.updateRoom(homeIndex, floorIndex, room, res.$1, res.$2));
                }
              },
            ),
          ),
        ),
        section('Lamps'),
        if (lamps.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text('No lamps yet.', style: TextStyle(color: scheme.onSurfaceVariant)),
          ),
        for (final l in lamps)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: Icon(l.mode == LampMode.dimmer
                    ? Icons.tungsten_outlined
                    : Icons.lightbulb_outline_rounded),
                title: Text(l.name),
                subtitle: Text(
                    '${l.mode == LampMode.dimmer ? 'Dimmer' : 'On / Off'} · lamp ${l.position} '
                    '(floors/${floor.index}/lamps/${l.index})'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'rename') {
                      final n = await _askName(context, 'Rename lamp', l.name);
                      if (n != null && n.trim().isNotEmpty && context.mounted) {
                        await _run(context, () => repo.renameLamp(homeIndex, floorIndex, l, n));
                      }
                    } else if (v == 'dimmer' || v == 'switch') {
                      await _run(
                          context,
                          () => repo.setMode(homeIndex, floorIndex, l,
                              v == 'dimmer' ? LampMode.dimmer : LampMode.onOff));
                    } else if (v == 'remove') {
                      if (await _confirm(context, 'Remove ${l.name}?',
                              'The lamp is turned off and disappears from the app. '
                              'Its number stays reserved for the board.') &&
                          context.mounted) {
                        await _run(context, () => repo.archiveLamp(homeIndex, floorIndex, room, l));
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'rename', child: Text('Rename')),
                    if (l.mode == LampMode.onOff)
                      const PopupMenuItem(value: 'dimmer', child: Text('Make it a dimmer'))
                    else
                      const PopupMenuItem(value: 'switch', child: Text('Make it On / Off')),
                    const PopupMenuItem(value: 'remove', child: Text('Remove')),
                  ],
                ),
              ),
            ),
          ),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () async {
              final res = await showDialog<(String, LampMode)>(
                context: context,
                builder: (_) => _LampDialog(initialName: 'Lamp ${lamps.length + 1}'),
              );
              if (res != null && context.mounted) {
                await _run(context,
                    () => repo.addLamp(homeIndex, floor, room, res.$1, res.$2),
                    done: 'Lamp added.');
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add lamp'),
          ),
          if (free.isNotEmpty)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: () async {
                final pick = await showModalBottomSheet<Lamp>(
                  context: context,
                  showDragHandle: true,
                  builder: (c) => SafeArea(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
                        child: Text('Lamps on this floor that are in no room'),
                      ),
                      for (final l in free)
                        ListTile(
                          leading: const Icon(Icons.lightbulb_outline_rounded),
                          title: Text(l.name),
                          subtitle: Text('lamp ${l.position}'),
                          onTap: () => Navigator.pop(c, l),
                        ),
                    ]),
                  ),
                );
                if (pick != null && context.mounted) {
                  await _run(context, () => repo.assignLamp(homeIndex, floorIndex, room, pick));
                }
              },
              icon: const Icon(Icons.move_down_rounded),
              label: Text('Use a free lamp (${free.length})'),
            ),
        ]),
        if (!room.isSub) ...[
          section('Sub-rooms'),
          for (final s in room.subRooms)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: Icon(roomIcon(s.type)),
                  title: Text(s.name),
                  subtitle: Text(
                      '${capitalize(s.type)} · ${_plural(floor.lampsOf(s).length, 'lamp', 'lamps')}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openRoom(context, repo, homeIndex, floorIndex, s.id),
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                final res = await _roomForm(context, sub: true);
                if (res != null && context.mounted) {
                  await _run(context,
                      () => repo.addRoom(homeIndex, floorIndex, res.$1, res.$2, parent: room),
                      done: 'Sub-room added.');
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add sub-room'),
            ),
          ),
          Text('A sub-room, like a bathroom inside a bedroom, is shown inside the same panel.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
        const SizedBox(height: 28),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
          onPressed: () async {
            if (await _confirm(context, 'Remove ${room.name}?',
                    'Its lamps are turned off and the room disappears from the app.') &&
                context.mounted) {
              await _run(context, () => repo.archiveRoom(homeIndex, floor, room));
              if (context.mounted) Navigator.of(context).maybePop();
            }
          },
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text(room.isSub ? 'Remove sub-room' : 'Remove room'),
        ),
      ],
    );
  }
}

class _LampDialog extends StatefulWidget {
  const _LampDialog({required this.initialName});
  final String initialName;

  @override
  State<_LampDialog> createState() => _LampDialogState();
}

class _LampDialogState extends State<_LampDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  LampMode _mode = LampMode.onOff;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New lamp'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Lamp name'),
        ),
        const SizedBox(height: 16),
        SegmentedButton<LampMode>(
          segments: const [
            ButtonSegment(value: LampMode.onOff, label: Text('On / Off')),
            ButtonSegment(value: LampMode.dimmer, label: Text('Dimmer')),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        const SizedBox(height: 8),
        const Text('The user can change this later in the room panel.',
            style: TextStyle(fontSize: 12)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final n = _name.text.trim();
            Navigator.pop(context, (n.isEmpty ? widget.initialName : n, _mode));
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

Future<(String, String)?> _roomForm(BuildContext context, {Room? room, bool sub = false}) =>
    showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RoomForm(room: room, sub: sub),
    );

class _RoomForm extends StatefulWidget {
  const _RoomForm({this.room, this.sub = false});
  final Room? room;
  final bool sub;

  @override
  State<_RoomForm> createState() => _RoomFormState();
}

class _RoomFormState extends State<_RoomForm> {
  late final _name = TextEditingController(text: widget.room?.name ?? '');
  late String _type = widget.room?.type ?? (widget.sub ? 'bathroom' : roomTypes.first);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final title = widget.room != null
        ? 'Edit room'
        : (widget.sub ? 'New sub-room' : 'New room');
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: widget.room == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Room name'),
            ),
            const SizedBox(height: 16),
            Text('Type', style: text.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in roomTypes)
                  ChoiceChip(
                    avatar: Icon(roomIcon(t), size: 18),
                    label: Text(capitalize(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() {
                      final auto = _name.text.isEmpty ||
                          roomTypes.any((x) => capitalize(x) == _name.text);
                      _type = t;
                      if (auto) _name.text = capitalize(t);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final n = _name.text.trim().isEmpty ? capitalize(_type) : _name.text.trim();
                Navigator.pop(context, (n, _type));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
