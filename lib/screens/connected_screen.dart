import 'package:material_ui/material_ui.dart';

import '../core/firebase_link_config.dart';
import '../core/link_service.dart';
import '../ui/app_logo.dart';
import 'link_start_screen.dart';

/// Shown when the app is linked. A placeholder until the home screens return.
class ConnectedScreen extends StatelessWidget {
  const ConnectedScreen(
      {super.key, required this.linkService, required this.config});

  final LinkService linkService;
  final FirebaseLinkConfig config;

  Future<void> _reset(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.link_off_rounded),
        title: const Text('Unlink this project?'),
        content: const Text(
            'The app will forget this Firebase project. You can link it again with the QR code.'),
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
    if (yes != true || !context.mounted) return;
    await linkService.reset();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LinkStartScreen(linkService: linkService)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Home'),
        actions: [
          PopupMenuButton<int>(
            onSelected: (_) => _reset(context),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 0,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.link_off_rounded),
                  title: Text('Unlink project'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Center(child: AppLogo(size: 88)),
              const SizedBox(height: 28),
              Text('Your home is linked',
                  textAlign: TextAlign.center,
                  style:
                      text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Sign-in and home control come in the next version.',
                  textAlign: TextAlign.center,
                  style:
                      text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 32),
              Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.cloud_done_rounded,
                        color: scheme.onPrimaryContainer),
                  ),
                  title: Text(config.projectId,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(config.databaseUrl ?? 'No database URL set'),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _reset(context),
                icon: const Icon(Icons.link_off_rounded),
                label: const Text('Unlink project'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
