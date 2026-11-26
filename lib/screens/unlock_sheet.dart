import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/admin_lock.dart';
import '../core/auth_service.dart';

/// Asks for today's operator code. Returns true when unlocked.
Future<bool> askOperatorCode(
    BuildContext context, AdminLock lock, String projectId) async {
  if (lock.operatorUnlocked) return true;
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _UnlockSheet(
          icon: Icons.engineering_outlined,
          title: 'Operator code',
          subtitle: 'Enter today\'s 8-digit code. It changes every day.',
          fieldLabel: 'Today\'s code',
          numeric: true,
          loadInfo: lock.operatorInfo,
          check: (c) => lock.unlockOperator(c, projectId),
          wrongMessage: 'This code is not valid today.',
        ),
      ) ==
      true;
}

/// Asks for the signed-in user's own password. Returns true when unlocked.
Future<bool> askOwnPassword(
    BuildContext context, AdminLock lock, String email) async {
  if (lock.settingsUnlocked) return true;
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _UnlockSheet(
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

class _UnlockSheet extends StatefulWidget {
  const _UnlockSheet({
    required this.icon,
    required this.title,
    required this.fieldLabel,
    required this.check,
    required this.wrongMessage,
    this.subtitle,
    this.loadInfo,
    this.numeric = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String fieldLabel;
  final bool numeric;
  final Future<bool> Function(String) check;
  final String wrongMessage;
  final Future<({bool ready, String contact, String? problem})> Function()? loadInfo;

  @override
  State<_UnlockSheet> createState() => _UnlockSheetState();
}

class _UnlockSheetState extends State<_UnlockSheet> {
  final _field = TextEditingController();
  bool _busy = false;
  bool _show = false;
  String? _error;
  ({bool ready, String contact, String? problem})? _info;
  int _fails = 0;

  @override
  void initState() {
    super.initState();
    widget.loadInfo?.call().then((i) {
      if (mounted) setState(() => _info = i);
    });
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_field.text.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await widget.check(_field.text);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
        return;
      }
      _fails++;
      // Slow down repeated guesses.
      if (_fails >= 3) await Future<void>.delayed(Duration(seconds: 2 * _fails));
      if (!mounted) return;
      setState(() => _error = widget.wrongMessage);
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
    final waitingInfo = widget.loadInfo != null && info == null;
    final blocked = info != null && !info.ready;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 28,
              backgroundColor: scheme.primaryContainer,
              child: Icon(widget.icon, color: scheme.onPrimaryContainer, size: 28),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.title,
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 6),
            Text(widget.subtitle!,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          ],
          if (info != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: blocked ? scheme.errorContainer : scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Icon(Icons.support_agent_rounded,
                    color: blocked
                        ? scheme.onErrorContainer
                        : scheme.onSecondaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    blocked ? '${info.problem} ${info.contact}' : info.contact,
                    style: TextStyle(
                        color: blocked
                            ? scheme.onErrorContainer
                            : scheme.onSecondaryContainer),
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 20),
          if (waitingInfo)
            const Center(child: CircularProgressIndicator())
          else if (!blocked) ...[
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
                  ? text.headlineSmall?.copyWith(letterSpacing: 6, fontWeight: FontWeight.w600)
                  : null,
              onSubmitted: (_) => _submit(),
              onChanged: widget.numeric
                  ? (v) {
                      if (v.length == AdminLock.digits) _submit();
                    }
                  : null,
              decoration: InputDecoration(
                labelText: widget.fieldLabel,
                prefixIcon: widget.numeric ? null : const Icon(Icons.key_rounded),
                errorText: _error,
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
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Unlock'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
