import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../core/admin_lock.dart';
import '../core/auth_service.dart';
import '../core/firebase_link_config.dart';
import '../core/home_repository.dart';
import '../core/link_service.dart';
import '../core/visibility_settings.dart';
import '../ui/app_logo.dart';
import 'configuration_screen.dart';
import 'floor_view.dart';
import 'link_start_screen.dart';
import 'settings_screen.dart';
import 'unlock_sheet.dart';

enum _Page { home, configuration, profile, display, visibility }

/// The signed-in app. Side menu:
///   Home
///   Operator (daily operator code): Configuration, Unlink the home
///   Settings (user's own password): Profile, Display
///   Sign out
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.auth,
    required this.user,
    required this.linkService,
    required this.config,
  });

  final AuthService auth;
  final User user;
  final LinkService linkService;
  final FirebaseLinkConfig config;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _repo = HomeRepository();
  final _lock = AdminLock();
  late Future<AccessLevel> _access = widget.auth.accessLevel();
  _Page _page = _Page.home;

  @override
  void initState() {
    super.initState();
    VisibilitySettings.instance.load(widget.config.projectId);
  }

  Future<bool> _operator() => askOperatorCode(context, _lock);
  Future<bool> _settings() =>
      askOwnPassword(context, _lock, widget.user.email ?? '');

  Future<void> _open(_Page p) async {
    Navigator.of(context).pop(); // close the drawer
    final ok = switch (p) {
      _Page.home => true,
      _Page.configuration => await _operator(),
      _Page.profile || _Page.visibility => await _settings(),
      _Page.display => true, // Display stays open without a password.
    };
    if (ok && mounted) setState(() => _page = p);
  }

  Future<void> _unlinkProtected() async {
    Navigator.of(context).pop();
    if (await _operator() && mounted) await _unlink();
  }

  Future<void> _signOut() async {
    Navigator.of(context).pop();
    _lock.lockAll();
    await widget.auth.signOut();
  }

  Future<void> _unlink() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.link_off_rounded),
        title: const Text('Unlink this home?'),
        content: const Text(
          'You will be signed out and the app will forget this Firebase project. '
          'The home data stays in Firebase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await widget.auth.signOut();
    } catch (_) {}
    await widget.linkService.reset();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LinkStartScreen(linkService: widget.linkService),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AccessLevel>(
      future: _access,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final level = snap.data ?? AccessLevel.none;
        if (level == AccessLevel.none) {
          return _NoAccess(
            email: widget.user.email ?? '',
            onRetry: () => setState(() => _access = widget.auth.accessLevel()),
            onSignOut: widget.auth.signOut,
          );
        }
        final isOwner = level == AccessLevel.owner;
        // Protected pages lock again after a few minutes.
        var page = _page;
        if (page == _Page.configuration && !_lock.operatorUnlocked) {
          page = _Page.home;
        }
        if ((page == _Page.profile || page == _Page.visibility) &&
            !_lock.settingsUnlocked) {
          page = _Page.home;
        }
        final title = switch (page) {
          _Page.home => '',
          _Page.configuration => 'Configuration',
          _Page.profile => 'Profile',
          _Page.display => 'Display',
          _Page.visibility => 'Shown on this phone',
        };
        final dark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          backgroundColor: page == _Page.home
              ? (dark ? const Color(0xFF0B1D26) : const Color(0xFFEEF3F2))
              : null,
          appBar: AppBar(title: Text(title)),
          drawer: Builder(builder: (_) => _buildDrawer(isOwner, page)),
          body: switch (page) {
            _Page.home => FloorHomeView(
              repo: _repo,
              isOwner: isOwner,
              onConfigure: () async {
                if (await _operator() && mounted) {
                  setState(() => _page = _Page.configuration);
                }
              },
            ),
            _Page.configuration =>
              isOwner
                  ? ConfigurationScreen(repo: _repo, uid: widget.user.uid)
                  : const _OwnerOnly(),
            _Page.profile => ProfileScreen(
              user: widget.user,
              lock: _lock,
              config: widget.config,
              isOwner: isOwner,
            ),
            _Page.display => const DisplayScreen(),
            _Page.visibility => VisibilityScreen(repo: _repo),
          },
        );
      },
    );
  }

  Widget _buildDrawer(bool isOwner, _Page page) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );
    Widget item({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool selected = false,
      double indent = 0,
    }) => Padding(
      padding: EdgeInsets.fromLTRB(12 + indent, 2, 12, 2),
      child: ListTile(
        shape: shape,
        selected: selected,
        selectedTileColor: scheme.secondaryContainer,
        selectedColor: scheme.onSecondaryContainer,
        leading: Icon(icon),
        title: Text(label),
        onTap: onTap,
      ),
    );
    Widget lockIcon(bool open) => Icon(
      open ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
      size: 18,
      color: scheme.onSurfaceVariant,
    );
    Widget group({
      required IconData icon,
      required String label,
      required bool open,
      required bool expanded,
      required List<Widget> children,
    }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: shape,
          collapsedShape: shape,
          initiallyExpanded: expanded,
          leading: Icon(icon),
          title: Text(label),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              lockIcon(open),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
          children: children,
        ),
      ),
    );

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  const AppLogo(size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Home',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.user.email ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isOwner ? 'Owner' : 'Member',
                            style: text.labelSmall?.copyWith(
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(indent: 24, endIndent: 24),
            const SizedBox(height: 8),
            item(
              icon: page == _Page.home
                  ? Icons.home_rounded
                  : Icons.home_outlined,
              label: 'Home',
              selected: page == _Page.home,
              onTap: () => _open(_Page.home),
            ),
            group(
              icon: Icons.engineering_outlined,
              label: 'Operator',
              open: _lock.operatorUnlocked,
              expanded: page == _Page.configuration,
              children: [
                item(
                  icon: Icons.tune_rounded,
                  label: 'Configuration',
                  selected: page == _Page.configuration,
                  indent: 16,
                  onTap: () => _open(_Page.configuration),
                ),
                item(
                  icon: Icons.link_off_rounded,
                  label: 'Unlink the home',
                  indent: 16,
                  onTap: _unlinkProtected,
                ),
              ],
            ),
            group(
              icon: Icons.settings_outlined,
              label: 'Settings',
              open: _lock.settingsUnlocked,
              expanded:
                  page == _Page.profile ||
                  page == _Page.display ||
                  page == _Page.visibility,
              children: [
                item(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  selected: page == _Page.profile,
                  indent: 16,
                  onTap: () => _open(_Page.profile),
                ),
                item(
                  icon: Icons.palette_outlined,
                  label: 'Display',
                  selected: page == _Page.display,
                  indent: 16,
                  onTap: () => _open(_Page.display),
                ),
                item(
                  icon: Icons.visibility_outlined,
                  label: 'Shown on this phone',
                  selected: page == _Page.visibility,
                  indent: 16,
                  onTap: () => _open(_Page.visibility),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Divider(),
            ),
            item(
              icon: Icons.logout_rounded,
              label: 'Sign out',
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerOnly extends StatelessWidget {
  const _OwnerOnly();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Configuration is unlocked, but only the owner\'s account can change the home. '
          'Sign in with the owner account on this phone to configure it.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess({
    required this.email,
    required this.onRetry,
    required this.onSignOut,
  });
  final String email;
  final VoidCallback onRetry;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: HomeMessage(
          icon: Icons.hourglass_top_rounded,
          title: 'Waiting for access',
          body:
              'You are signed in as $email, but the owner has not given you '
              'access to this home yet.',
          action: Column(
            children: [
              FilledButton(
                onPressed: onRetry,
                child: const Text('Check again'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: onSignOut, child: const Text('Sign out')),
            ],
          ),
        ),
      ),
    );
  }
}
