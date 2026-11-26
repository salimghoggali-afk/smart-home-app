import 'package:material_ui/material_ui.dart';

import '../core/home_repository.dart';
import '../ui/room_icons.dart';

/// Owner screen to create the home and its floors and rooms in the database.
class ConfigurationScreen extends StatelessWidget {
  const ConfigurationScreen({super.key, required this.repo, required this.uid});

  final HomeRepository repo;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Home?>(
      stream: repo.watchHome(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'The database refused access. Check that the rules from the guide are published.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snap.hasData && snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final home = snap.data;
        return home == null
            ? _CreateHome(repo: repo, uid: uid)
            : _EditHome(repo: repo, home: home);
      },
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

class _CreateHome extends StatefulWidget {
  const _CreateHome({required this.repo, required this.uid});
  final HomeRepository repo;
  final String uid;

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
      final id = await widget.repo.createHome(_name.text, widget.uid);
      for (var i = 0; i < _floors; i++) {
        await widget.repo.addFloor(id, _floorName(i), i);
      }
    }, done: 'Home created. Now add the rooms.');
    if (mounted) setState(() => _busy = false);
  }

  static String _floorName(int i) => i == 0 ? 'Ground floor' : 'Floor $i';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Create your home',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('This saves the home in the Realtime Database of the linked project. '
            'You can rename everything later.',
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
                child: Text('$_floors',
                    textAlign: TextAlign.center, style: text.titleLarge),
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
  const _EditHome({required this.repo, required this.home});
  final HomeRepository repo;
  final Home home;

  Future<String?> _askName(BuildContext context, String title, String initial) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Name'),
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
            FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Delete')),
          ],
        ),
      ) ==
      true;

  Future<void> _roomDialog(BuildContext context, Floor floor, {Room? room}) async {
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RoomSheet(room: room),
    );
    if (result == null || !context.mounted) return;
    final (name, type) = result;
    if (room == null) {
      await _run(context,
          () => repo.addRoom(home.id, floor.id, name, type, floor.rooms.length),
          done: 'Room added.');
    } else {
      await _run(context, () => repo.updateRoom(home.id, floor.id, room.id, name, type));
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
          Card(
            color: scheme.primaryContainer,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              leading: Icon(Icons.home_rounded, color: scheme.onPrimaryContainer),
              title: Text(home.name,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer)),
              subtitle: Text('${home.floors.length} floors · ${home.roomCount} rooms',
                  style: TextStyle(color: scheme.onPrimaryContainer)),
              trailing: IconButton(
                tooltip: 'Rename home',
                icon: Icon(Icons.edit_outlined, color: scheme.onPrimaryContainer),
                onPressed: () async {
                  final n = await _askName(context, 'Rename home', home.name);
                  if (n != null && n.trim().isNotEmpty && context.mounted) {
                    await _run(context, () => repo.renameHome(home.id, n));
                  }
                },
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
                  subtitle: Text('${f.rooms.length} rooms'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'rename') {
                        final n = await _askName(context, 'Rename floor', f.name);
                        if (n != null && n.trim().isNotEmpty && context.mounted) {
                          await _run(context, () => repo.renameFloor(home.id, f.id, n));
                        }
                      } else if (v == 'delete') {
                        if (await _confirm(context, 'Delete ${f.name}?',
                                'Its ${f.rooms.length} rooms will be deleted too.') &&
                            context.mounted) {
                          await _run(context, () => repo.deleteFloor(home.id, f.id));
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  children: [
                    for (final r in f.rooms)
                      ListTile(
                        leading: Icon(roomIcon(r.type)),
                        title: Text(r.name),
                        subtitle: Text(capitalize(r.type)),
                        onTap: () => _roomDialog(context, f, room: r),
                        trailing: IconButton(
                          tooltip: 'Delete room',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () async {
                            if (await _confirm(context, 'Delete ${r.name}?', '') &&
                                context.mounted) {
                              await _run(context,
                                  () => repo.deleteRoom(home.id, f.id, r.id));
                            }
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _roomDialog(context, f),
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
            final n = await _askName(context, 'New floor',
                home.floors.isEmpty ? 'Ground floor' : 'Floor ${home.floors.length}');
            if (n != null && n.trim().isNotEmpty && context.mounted) {
              await _run(context, () => repo.addFloor(home.id, n, home.floors.length),
                  done: 'Floor added.');
            }
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add floor'),
        ),
      ),
    ]);
  }
}

class _RoomSheet extends StatefulWidget {
  const _RoomSheet({this.room});
  final Room? room;

  @override
  State<_RoomSheet> createState() => _RoomSheetState();
}

class _RoomSheetState extends State<_RoomSheet> {
  late final _name = TextEditingController(text: widget.room?.name ?? '');
  late String _type = widget.room?.type ?? roomTypes.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.room == null ? 'New room' : 'Edit room',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
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
    );
  }
}
