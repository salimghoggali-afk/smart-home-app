import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../core/auth_service.dart';
import '../core/firebase_link_config.dart';
import '../core/home_repository.dart';
import '../core/link_service.dart';
import '../ui/app_logo.dart';
import '../ui/room_icons.dart';
import 'configuration_screen.dart';
import 'link_start_screen.dart';

enum _Page { home, configuration }

/// The signed-in app: a side menu with Home and Configuration.
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
  late Future<AccessLevel> _access = widget.auth.accessLevel();
  _Page _page = _Page.home;

  void _go(_Page p) {
    Navigator.of(context).pop(); // close the drawer
    setState(() => _page = p);
  }

  Future<void> _signOut() async {
    Navigator.of(context).maybePop();
    await widget.auth.signOut();
  }

  Future<void> _unlink() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.link_off_rounded),
        title: const Text('Unlink this project?'),
        content: const Text(
            'You will be signed out and the app will forget this Firebase project. '
            'Your home data stays in Firebase.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Unlink')),
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
          builder: (_) => LinkStartScreen(linkService: widget.linkService)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AccessLevel>(
      future: _access,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        final page = isOwner ? _page : _Page.home;
        return Scaffold(
          appBar: AppBar(
            title: Text(page == _Page.home ? 'My Home' : 'Configuration'),
          ),
          drawer: _buildDrawer(isOwner, page),
          body: page == _Page.home
              ? _HomeView(
                  repo: _repo,
                  isOwner: isOwner,
                  onConfigure: () => setState(() => _page = _Page.configuration),
                )
              : ConfigurationScreen(repo: _repo, uid: widget.user.uid),
        );
      },
    );
  }

  Widget _buildDrawer(bool isOwner, _Page page) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return NavigationDrawer(
      selectedIndex: page == _Page.home ? 0 : 1,
      onDestinationSelected: (i) => _go(i == 0 ? _Page.home : _Page.configuration),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(children: [
            const AppLogo(size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Home',
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text(widget.user.email ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(isOwner ? 'Owner' : 'Member',
                        style: text.labelSmall
                            ?.copyWith(color: scheme.onPrimaryContainer)),
                  ),
                ],
              ),
            ),
          ]),
        ),
        const Divider(indent: 24, endIndent: 24),
        const SizedBox(height: 8),
        const NavigationDrawerDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: Text('Home'),
        ),
        if (isOwner)
          const NavigationDrawerDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: Text('Configuration'),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Divider(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign out'),
            onTap: _signOut,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            leading: const Icon(Icons.link_off_rounded),
            title: const Text('Unlink project'),
            subtitle: Text(widget.config.projectId),
            onTap: () {
              Navigator.of(context).pop();
              _unlink();
            },
          ),
        ),
      ],
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({required this.repo, required this.isOwner, required this.onConfigure});

  final HomeRepository repo;
  final bool isOwner;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return StreamBuilder<Home?>(
      stream: repo.watchHome(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _Message(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load the home',
            body: 'Check the internet connection and the database rules.',
          );
        }
        if (!snap.hasData && snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final home = snap.data;
        if (home == null) {
          return _Message(
            icon: Icons.add_home_outlined,
            title: 'No home yet',
            body: isOwner
                ? 'Open Configuration in the side menu to create your home, its floors and rooms.'
                : 'The owner has not created the home yet.',
            action: isOwner
                ? FilledButton.icon(
                    onPressed: onConfigure,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Open Configuration'),
                  )
                : null,
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(home.name,
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${home.floors.length} floors · ${home.roomCount} rooms',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            if (home.floors.isEmpty)
              Text('No floors yet. Add them in Configuration.',
                  style: text.bodyMedium),
            for (final f in home.floors) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 8),
                child: Text(f.name,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              if (f.rooms.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('No rooms on this floor.',
                      style: text.bodyMedium?.copyWith(color: scheme.outline)),
                ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  for (final r in f.rooms)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: scheme.primaryContainer,
                              child: Icon(roomIcon(r.type),
                                  color: scheme.onPrimaryContainer),
                            ),
                            const Spacer(),
                            Text(r.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text(capitalize(r.type),
                                style: text.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess({required this.email, required this.onRetry, required this.onSignOut});
  final String email;
  final VoidCallback onRetry;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _Message(
          icon: Icons.hourglass_top_rounded,
          title: 'Waiting for access',
          body: 'You are signed in as $email, but the owner has not given you '
              'access to this home yet.',
          action: Column(children: [
            FilledButton(onPressed: onRetry, child: const Text('Check again')),
            const SizedBox(height: 8),
            TextButton(onPressed: onSignOut, child: const Text('Sign out')),
          ]),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body, this.action});
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
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
        ]),
      ),
    );
  }
}
