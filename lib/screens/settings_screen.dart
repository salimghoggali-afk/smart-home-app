import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:material_ui/material_ui.dart';

import '../core/admin_lock.dart';
import '../core/auth_service.dart';
import '../core/display_settings.dart';
import '../core/firebase_link_config.dart';
import '../core/home_repository.dart';
import '../core/visibility_settings.dart';
import '../ui/room_icons.dart';

const appVersion = '1.5.0';

Widget _section(BuildContext context, String t) {
  final scheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(t.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.primary, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
  );
}

/// Settings > Profile: the signed-in person's account.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.lock,
    required this.config,
    required this.isOwner,
  });

  final User user;
  final AdminLock lock;
  final FirebaseLinkConfig config;
  final bool isOwner;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _name;

  DatabaseReference get _nameRef =>
      FirebaseDatabase.instance.ref('users/${widget.user.uid}/name');

  @override
  void initState() {
    super.initState();
    _nameRef.get().then((s) {
      if (mounted) setState(() => _name = (s.value as String?) ?? '');
    }).catchError((_) {
      if (mounted) setState(() => _name = '');
    });
  }

  Future<void> _editName() async {
    final c = TextEditingController(text: _name);
    final v = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (v == null) return;
    try {
      await _nameRef.set(v);
      if (mounted) setState(() => _name = v);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save the name.')));
      }
    }
  }

  Future<void> _changePassword() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ChangePasswordSheet(lock: widget.lock),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your password was changed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final name = _name;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              (name != null && name.isNotEmpty ? name : widget.user.email ?? '?')
                  .substring(0, 1)
                  .toUpperCase(),
              style: text.headlineMedium?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(name == null || name.isEmpty ? 'No name yet' : name,
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        Text(widget.isOwner ? 'Owner of this home' : 'Member',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        _section(context, 'Account'),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Name'),
              subtitle: Text(name == null ? '…' : (name.isEmpty ? 'Add your name' : name)),
              trailing: const Icon(Icons.edit_outlined),
              onTap: name == null ? null : _editName,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.mail_outline_rounded),
              title: const Text('Email'),
              subtitle: Text(widget.user.email ?? ''),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.password_rounded),
              title: const Text('Change my password'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _changePassword,
            ),
          ]),
        ),
        _section(context, 'Linked home'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_done_outlined),
            title: Text(widget.config.projectId),
            subtitle: Text(widget.config.databaseUrl ?? 'No database URL'),
          ),
        ),
        _section(context, 'About'),
        const Card(
          child: Column(children: [
            ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('My Home'),
              subtitle: Text('Version $appVersion'),
            ),
            Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Icon(Icons.design_services_outlined),
              title: Text('Designed by'),
              subtitle: Text('Mr. Salim GHOGGALI and Mr. Karim HADDAD'),
            ),
          ]),
        ),
      ],
    );
  }
}

/// Settings > Display: theme and text size for this phone.
class DisplayScreen extends StatelessWidget {
  const DisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = DisplaySettings.instance;
    return ListenableBuilder(
      listenable: d,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          _section(context, 'Theme'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('Auto')),
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light')),
              ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark')),
            ],
            selected: {d.mode},
            onSelectionChanged: (s) => d.setMode(s.first),
          ),
          const SizedBox(height: 8),
          Text('Auto follows the phone setting.',
              style: Theme.of(context).textTheme.bodySmall),
          _section(context, 'Text size'),
          Card(
            child: RadioGroup<double>(
              groupValue: d.textScale,
              onChanged: (v) {
                if (v != null) d.setTextScale(v);
              },
              child: Column(children: [
                for (final e in DisplaySettings.textScales.entries)
                  RadioListTile<double>(
                    value: e.value,
                    title: Text(e.key, textScaler: TextScaler.linear(e.value / d.textScale)),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Settings > Shown on this phone: choose which rooms this phone shows.
/// Opens only with the signed-in account's password, so whoever uses the
/// phone cannot undo it.
class VisibilityScreen extends StatelessWidget {
  const VisibilityScreen({super.key, required this.repo});
  final HomeRepository repo;

  @override
  Widget build(BuildContext context) {
    final v = VisibilitySettings.instance;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: v,
      builder: (context, _) => StreamBuilder<Home?>(
        stream: repo.watchHome(),
        builder: (context, snap) {
          final home = snap.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                'Choose what this phone shows. Use it, for example, on a child\'s '
                'phone to show only their room. The choice is saved on this '
                'phone only, and only your password can change it.',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Card(
                child: RadioGroup<bool>(
                  groupValue: v.limited,
                  onChanged: (x) {
                    if (x != null) v.save(limited: x, rooms: v.shownRooms);
                  },
                  child: const Column(children: [
                    RadioListTile<bool>(
                      value: false,
                      title: Text('Show the whole home'),
                    ),
                    RadioListTile<bool>(
                      value: true,
                      title: Text('Show only the rooms I choose'),
                      subtitle: Text('Rooms added later stay hidden until you tick them.'),
                    ),
                  ]),
                ),
              ),
              if (v.limited) ...[
                _section(context, 'Rooms shown on this phone'),
                if (home == null)
                  snap.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : const Text('No home yet. Create it in Operator > Configuration.')
                else if (home.roomCount == 0)
                  const Text('No rooms yet. Add them in Operator > Configuration.')
                else
                  for (final f in home.floors)
                    if (f.rooms.isNotEmpty)
                      Card(
                        child: Column(children: [
                          ListTile(
                            title: Text(f.name,
                                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                            trailing: TextButton(
                              onPressed: () {
                                final ids = f.rooms.map((r) => r.id).toSet();
                                final all = ids.every(v.shownRooms.contains);
                                v.save(
                                    limited: true,
                                    rooms: all
                                        ? v.shownRooms.difference(ids)
                                        : v.shownRooms.union(ids));
                              },
                              child: Text(f.rooms.every((r) => v.shownRooms.contains(r.id))
                                  ? 'Hide all'
                                  : 'Show all'),
                            ),
                          ),
                          for (final r in f.rooms)
                            CheckboxListTile(
                              secondary: Icon(roomIcon(r.type)),
                              title: Text(r.name),
                              subtitle: Text(capitalize(r.type)),
                              value: v.shownRooms.contains(r.id),
                              onChanged: (on) {
                                final next = {...v.shownRooms};
                                on == true ? next.add(r.id) : next.remove(r.id);
                                v.save(limited: true, rooms: next);
                              },
                            ),
                        ]),
                      ),
                const SizedBox(height: 8),
                Text(
                  'Choosing the devices and options inside each room will come '
                  'here once devices are added to the app.',
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.lock});
  final AdminLock lock;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_a.text.length < 8) {
      setState(() => _error = 'Use at least 8 characters.');
      return;
    }
    if (_a.text != _b.text) {
      setState(() => _error = 'The passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.lock.changeOwnPassword(_a.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
          Text('Change my password',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _a,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _b,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Confirm new password', errorText: _error),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
