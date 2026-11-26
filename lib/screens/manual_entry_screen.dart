import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../core/firebase_link_config.dart';

/// Lets the user type or paste the Firebase details.
class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _form = GlobalKey<FormState>();
  final _apiKey = TextEditingController();
  final _appId = TextEditingController();
  final _projectId = TextEditingController();
  final _sender = TextEditingController();
  final _db = TextEditingController();
  final _bucket = TextEditingController();
  final _webClient = TextEditingController();
  bool _more = false;

  @override
  void dispose() {
    for (final c in [
      _apiKey, _appId, _projectId, _sender, _db, _bucket, _webClient
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(FirebaseLinkConfig c) {
    setState(() {
      _apiKey.text = c.apiKey;
      _appId.text = c.appId;
      _projectId.text = c.projectId;
      _sender.text = c.messagingSenderId;
      _db.text = c.databaseUrl ?? '';
      _bucket.text = c.storageBucket ?? '';
      _webClient.text = c.webClientId ?? '';
      _more = true;
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text ?? '';
    if (!mounted) return;
    if (raw.trim().isEmpty) {
      _snack('The clipboard is empty. Copy google-services.json first.');
      return;
    }
    try {
      _fill(FirebaseLinkConfig.parse(raw,
          androidPackage: 'com.ghoggalisalim.smarthome'));
      _snack('Details filled in from the clipboard.');
    } on FormatException catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  FirebaseLinkConfig _current() {
    String? opt(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    return FirebaseLinkConfig(
      apiKey: _apiKey.text.trim(),
      appId: _appId.text.trim(),
      projectId: _projectId.text.trim(),
      messagingSenderId: _sender.text.trim(),
      databaseUrl: opt(_db),
      storageBucket: opt(_bucket),
      webClientId: opt(_webClient),
    );
  }

  void _continue() {
    if (!_form.currentState!.validate()) return;
    final problems = _current().validate();
    if (problems.isNotEmpty) {
      _snack(problems.first);
      return;
    }
    Navigator.of(context).pop(_current());
  }

  String? Function(String?) _rule(RegExp re, String msg, {bool optional = false}) =>
      (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return optional ? null : 'Required';
        return re.hasMatch(t) ? null : msg;
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget field(TextEditingController c, String label, String hint,
            String? Function(String?) v,
            {TextInputType type = TextInputType.text}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextFormField(
            controller: c,
            validator: v,
            keyboardType: type,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(labelText: label, hintText: hint),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Project details')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Card(
                color: scheme.secondaryContainer,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Icon(Icons.content_paste_rounded,
                      color: scheme.onSecondaryContainer),
                  title: Text('Paste google-services.json',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSecondaryContainer)),
                  subtitle: Text('Copy the whole file, then tap here',
                      style: TextStyle(color: scheme.onSecondaryContainer)),
                  onTap: _paste,
                ),
              ),
              const SizedBox(height: 24),
              field(_apiKey, 'API key', 'AIza…',
                  _rule(RegExp(r'^AIza[0-9A-Za-z_\-]{35}$'), 'Starts with AIza, 39 characters')),
              field(_appId, 'Android app ID', '1:123456789:android:abc…',
                  _rule(RegExp(r'^1:\d+:android:[0-9a-f]+$'), 'Looks like 1:123:android:abc')),
              field(_projectId, 'Project ID', 'my-home-1234',
                  _rule(RegExp(r'^[a-z0-9][a-z0-9\-]{4,29}$'), 'Lower case letters, numbers and -')),
              field(_sender, 'Project number (sender ID)', '123456789',
                  _rule(RegExp(r'^\d+$'), 'Numbers only'),
                  type: TextInputType.number),
              field(
                  _db,
                  'Realtime Database URL',
                  'https://my-home-default-rtdb.firebaseio.com',
                  _rule(
                      RegExp(r'^https://[a-z0-9\-\.]+(firebaseio\.com|firebasedatabase\.app)/?$'),
                      'Must be a firebaseio.com or firebasedatabase.app address',
                      optional: true),
                  type: TextInputType.url),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState:
                    _more ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _more = true),
                    icon: const Icon(Icons.expand_more_rounded),
                    label: const Text('More options'),
                  ),
                ),
                secondChild: Column(children: [
                  field(_bucket, 'Storage bucket (optional)',
                      'my-home.appspot.com', (_) => null),
                  field(_webClient, 'Web client ID (optional)',
                      'For Google sign-in later', (_) => null),
                ]),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _continue, child: const Text('Continue')),
            ],
          ),
        ),
      ),
    );
  }
}
