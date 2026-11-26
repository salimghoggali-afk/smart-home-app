import 'package:material_ui/material_ui.dart';

import '../core/auth_service.dart';
import '../core/firebase_link_config.dart';
import '../core/link_service.dart';
import '../ui/app_logo.dart';

/// Email and password sign-in. When the home has no owner yet, it offers to
/// create the owner account instead.
class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.auth,
    required this.linkService,
    required this.config,
  });

  final AuthService auth;
  final LinkService linkService;
  final FirebaseLinkConfig config;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool? _hasOwner; // null while loading
  bool _register = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOwner();
  }

  Future<void> _loadOwner() async {
    try {
      final has = await widget.auth.hasOwner();
      if (!mounted) return;
      setState(() {
        _hasOwner = has;
        _register = !has;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasOwner = true;
        _error = 'Could not reach the database. Check the internet, the '
            'database URL and the database rules.';
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        await widget.auth.register(_email.text, _password.text);
      } else {
        await widget.auth.signIn(_email.text, _password.text);
      }
      // AuthGate swaps this screen out when the user changes.
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Type your email first, then tap "Forgot password".');
      return;
    }
    try {
      await widget.auth.resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('A reset link was sent to $email.')));
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.message(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final firstOwner = _hasOwner == false;

    final title = _register
        ? (firstOwner ? 'Create the owner account' : 'Create an account')
        : 'Sign in';
    final subtitle = _register
        ? (firstOwner
            ? 'You are the first person here. This account will own the home.'
            : 'The owner must give you access before you can use the home.')
        : 'Welcome back to ${widget.config.projectId}.';

    return Scaffold(
      appBar: AppBar(
      ),
      body: SafeArea(
        child: _hasOwner == null
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  children: [
                    const Center(child: AppLogo(size: 72)),
                    const SizedBox(height: 24),
                    Text(title,
                        textAlign: TextAlign.center,
                        style: text.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(subtitle,
                        textAlign: TextAlign.center,
                        style: text.bodyLarge
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline_rounded)),
                      validator: (v) => (v ?? '').trim().contains('@')
                          ? null
                          : 'Enter a valid email',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: !_showPassword,
                      autofillHints: [
                        _register ? AutofillHints.newPassword : AutofillHints.password
                      ],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      validator: (v) => (v ?? '').length >= (_register ? 8 : 1)
                          ? null
                          : (_register ? 'At least 8 characters' : 'Required'),
                    ),
                    if (_register) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirm,
                        obscureText: !_showPassword,
                        decoration: const InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: Icon(Icons.lock_outline_rounded)),
                        validator: (v) => v == _password.text
                            ? null
                            : 'The passwords do not match',
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_error!,
                            style: TextStyle(color: scheme.onErrorContainer)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5))
                          : Text(_register ? 'Create account' : 'Sign in'),
                    ),
                    const SizedBox(height: 8),
                    if (!_register)
                      TextButton(
                          onPressed: _forgot,
                          child: const Text('Forgot password?')),
                    if (!firstOwner)
                      TextButton(
                        onPressed: () => setState(() {
                          _register = !_register;
                          _error = null;
                        }),
                        child: Text(_register
                            ? 'I already have an account'
                            : 'New here? Create an account'),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
