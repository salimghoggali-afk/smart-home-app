import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/admin_lock.dart';
import '../core/auth_service.dart';

/// Shows a box asking for today's operator code. Returns true when the code
/// is valid and the Operator menu is unlocked.
Future<bool> askOperatorCode(
    BuildContext context, AdminLock lock) async {
  if (lock.operatorUnlocked) return true;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _UnlockBox(
          icon: Icons.engineering_outlined,
          title: 'Operator code',
          subtitle: 'This menu is for the installer. Enter today\'s 8-digit '
              'operator code.',
          noticeTitle: 'How to get the code',
          fieldLabel: 'Today\'s code',
          numeric: true,
          loadInfo: lock.operatorInfo,
          check: lock.unlockOperator,
          wrongMessage: 'This code is not valid today. Check the 8 digits, or '
              'ask for today\'s code again.',
        ),
      ) ==
      true;
}

/// Shows a box asking for the signed-in user's own password. Returns true
/// when unlocked.
Future<bool> askOwnPassword(
    BuildContext context, AdminLock lock, String email) async {
  if (lock.settingsUnlocked) return true;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _UnlockBox(
          icon: Icons.lock_person_outlined,
          title: 'Confirm it is you',
          subtitle: 'Enter the password of $email to open Settings.',
          fieldLabel: 'Your password',
          check: lock.unlockSettings,
          wrongMessage: 'The password is wrong.',
        ),
      ) ==
      true;
}

typedef _Info = ({bool ready, String contact, String? problem});

class _UnlockBox extends StatefulWidget {
  const _UnlockBox({
    required this.icon,
    required this.title,
    required this.fieldLabel,
    required this.check,
    required this.wrongMessage,
    this.subtitle,
    this.noticeTitle,
    this.loadInfo,
    this.numeric = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? noticeTitle;
  final String fieldLabel;
  final bool numeric;
  final Future<bool> Function(String) check;
  final String wrongMessage;
  final Future<_Info> Function()? loadInfo;

  @override
  State<_UnlockBox> createState() => _UnlockBoxState();
}

class _UnlockBoxState extends State<_UnlockBox> {
  final _field = TextEditingController();
  bool _busy = false;
  bool _show = false;
  String? _error;
  _Info? _info;
  Future<_Info>? _infoLoad;
  int _fails = 0;

  @override
  void initState() {
    super.initState();
    _infoLoad = widget.loadInfo?.call();
    _infoLoad?.then((i) {
      if (mounted) setState(() => _info = i);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  bool get _complete =>
      widget.numeric ? _field.text.length == AdminLock.digits : _field.text.isNotEmpty;

  Future<void> _submit() async {
    if (_busy) return;
    if (!_complete) {
      setState(() => _error = widget.numeric
          ? 'Enter all ${AdminLock.digits} digits.'
          : 'Enter your password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // The home must have an operator secret, and this phone must be signed
      // in with the owner account, before any code can be checked.
      final info = _info ?? await _infoLoad;
      if (info != null && !info.ready) {
        if (mounted) setState(() => _error = info.problem);
        return;
      }
      final ok = await widget.check(_field.text);
      if (!mounted) return;
      if (ok) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        Navigator.of(context).pop(true);
        messenger?.showSnackBar(
            const SnackBar(content: Text('Access granted.')));
        return;
      }
      _fails++;
      // Slow down repeated guesses.
      if (_fails >= 3) await Future<void>.delayed(Duration(seconds: 2 * _fails));
      if (!mounted) return;
      setState(() => _error = widget.wrongMessage);
      _field.clear();
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final info = _info;
    final notice = info?.contact ??
        (widget.loadInfo != null ? AdminLock.defaultContact : null);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primaryContainer,
                child: Icon(widget.icon, color: scheme.onPrimaryContainer, size: 26),
              ),
            ),
            const SizedBox(height: 14),
            Text(widget.title,
                textAlign: TextAlign.center,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 6),
              Text(widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ],
            if (notice != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.support_agent_rounded,
                      color: scheme.onSecondaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.noticeTitle != null)
                          Text(widget.noticeTitle!,
                              style: text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSecondaryContainer)),
                        const SizedBox(height: 4),
                        Text(
                          'The code changes every day and works only on the '
                          'day it is given. $notice',
                          style: TextStyle(color: scheme.onSecondaryContainer),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 18),
            TextField(
              controller: _field,
              autofocus: true,
              obscureText: !widget.numeric && !_show,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType:
                  widget.numeric ? TextInputType.number : TextInputType.visiblePassword,
              inputFormatters: widget.numeric
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(AdminLock.digits),
                    ]
                  : null,
              textAlign: widget.numeric ? TextAlign.center : TextAlign.start,
              style: widget.numeric
                  ? text.headlineSmall
                      ?.copyWith(letterSpacing: 6, fontWeight: FontWeight.w600)
                  : null,
              onSubmitted: (_) => _submit(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                labelText: widget.fieldLabel,
                hintText: widget.numeric ? '00000000' : null,
                prefixIcon: widget.numeric ? null : const Icon(Icons.key_rounded),
                errorText: _error,
                errorMaxLines: 4,
                suffixIcon: widget.numeric
                    ? null
                    : IconButton(
                        icon: Icon(_show
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => _show = !_show),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Verify and open'),
            ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
