import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../core/admin_lock.dart';
import '../core/auth_service.dart';
import '../core/firebase_link_config.dart';

const appVersion = '1.2.0';

/// Settings for the signed-in user. Opened only after the user re-enters
/// their own password.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
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

  Future<void> _changePassword(BuildContext context) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ChangePasswordSheet(lock: lock),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your password was changed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    Widget section(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(t.toUpperCase(),
              style: text.labelMedium?.copyWith(
                  color: scheme.primary, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        section('Account'),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: Text(user.email ?? ''),
              subtitle: Text(isOwner ? 'Owner of this home' : 'Member'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.password_rounded),
              title: const Text('Change my password'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _changePassword(context),
            ),
          ]),
        ),
        section('Linked project'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_done_outlined),
            title: Text(config.projectId),
            subtitle: Text(config.databaseUrl ?? 'No database URL'),
          ),
        ),
        section('About'),
        Card(
          child: Column(children: [
            const ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('My Home'),
              subtitle: Text('Version $appVersion'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.design_services_outlined),
              title: const Text('Designed by'),
              subtitle: const Text('Mr. Salim GHOGGALI and Mr. Karim HADDAD'),
              subtitleTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ]),
        ),
      ],
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
