import 'package:material_ui/material_ui.dart';

import '../core/firebase_link_config.dart';
import '../core/link_service.dart';
import '../ui/app_logo.dart';
import 'auth_gate.dart';
import 'manual_entry_screen.dart';
import 'qr_scan_screen.dart';

/// Start screen: links the app to a Firebase project, by QR code or by hand.
class LinkStartScreen extends StatefulWidget {
  const LinkStartScreen(
      {super.key, required this.linkService, this.initialError});

  final LinkService linkService;
  final String? initialError;

  @override
  State<LinkStartScreen> createState() => _LinkStartScreenState();
}

class _LinkStartScreenState extends State<LinkStartScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(widget.initialError!)));
      });
    }
  }

  Future<void> _scan() async {
    final config = await Navigator.of(context).push<FirebaseLinkConfig>(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (config != null && mounted) await _review(config);
  }

  Future<void> _manual() async {
    final config = await Navigator.of(context).push<FirebaseLinkConfig>(
      MaterialPageRoute(builder: (_) => const ManualEntryScreen()),
    );
    if (config != null && mounted) await _review(config);
  }

  Future<void> _review(FirebaseLinkConfig config) async {
    final linked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _ReviewSheet(config: config, linkService: widget.linkService),
    );
    if (linked == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              AuthGate(linkService: widget.linkService, config: config),
        ),
        (_) => false,
      );
    }
  }

  void _help() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _HelpSheet(onManual: () {
        Navigator.of(context).pop();
        _manual();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),
                    const Center(child: AppLogo(size: 96)),
                    const SizedBox(height: 32),
                    Text('Welcome to My Home',
                        textAlign: TextAlign.center,
                        style: text.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text(
                      'Link the app to your home\'s Firebase project to get started.',
                      textAlign: TextAlign.center,
                      style: text.bodyLarge
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 36),
                    const _StepsCard(),
                    const Spacer(),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: _scan,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan QR code'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _help,
                      child: Text("Can't scan?",
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget step(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(body,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Column(children: [
          step(Icons.qr_code_2_rounded, 'Scan the link code',
              'The QR code holds the details of your home\'s Firebase project.'),
          step(Icons.verified_user_outlined, 'Check and confirm',
              'The app checks the project before it saves it.'),
          step(Icons.person_outline_rounded, 'Sign in',
              'The first account created becomes the owner of the home.'),
        ]),
      ),
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.config, required this.linkService});

  final FirebaseLinkConfig config;
  final LinkService linkService;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  LinkCheck? _check;
  bool _linking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.linkService.check(widget.config).then((c) {
      if (mounted) setState(() => _check = c);
    });
  }

  Future<void> _link() async {
    setState(() {
      _linking = true;
      _error = null;
    });
    try {
      await widget.linkService.start(widget.config);
      await widget.linkService.save(widget.config);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _linking = false;
        _error = 'Firebase could not start with these details.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final c = widget.config;
    final check = _check;

    Widget row(String label, String? value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(label,
                    style: text.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ),
              Expanded(
                child: Text(value ?? 'Not set',
                    style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: value == null ? scheme.outline : null)),
              ),
            ],
          ),
        );

    Widget status;
    if (check == null) {
      status = Row(children: [
        const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 12),
        Text('Checking the project online…', style: text.bodyMedium),
      ]);
    } else {
      final (icon, color, msg) = !check.ok
          ? (Icons.error_outline_rounded, scheme.error, check.message!)
          : check.warning
              ? (Icons.info_outline_rounded, scheme.tertiary, check.message!)
              : (
                  Icons.check_circle_outline_rounded,
                  scheme.primary,
                  'The project answered. Everything looks good.'
                );
      status = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(msg, style: text.bodyMedium)),
      ]);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Link this project?',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                row('Project', c.projectId),
                row('Database', c.databaseUrl),
                row('Storage', c.storageBucket),
                row('Google sign-in', c.webClientId == null ? null : 'Ready'),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          status,
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: text.bodyMedium?.copyWith(color: scheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed:
                (check == null || !check.ok || _linking) ? null : _link,
            child: _linking
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('Link project'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _HelpSheet extends StatelessWidget {
  const _HelpSheet({required this.onManual});
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget p(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(s, style: text.bodyMedium));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Can't scan the code?",
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            p('Ask for a new link QR code, or make it yourself with the QR maker page from google-services.json.'),
            p('Check that the camera is allowed for My Home in the phone settings, and that the code is well lit.'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onManual,
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Enter the details by hand'),
            ),
          ],
        ),
      ),
    );
  }
}
