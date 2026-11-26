import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../core/auth_service.dart';
import '../core/firebase_link_config.dart';
import '../core/link_service.dart';
import 'home_shell.dart';
import 'sign_in_screen.dart';

/// Shows the sign-in screen until someone is signed in, then the home.
/// The app never opens without a signed-in user.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.linkService, required this.config});

  final LinkService linkService;
  final FirebaseLinkConfig config;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final linkService = widget.linkService;
    final config = widget.config;
    return StreamBuilder<User?>(
      stream: auth.userChanges,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null) {
          return SignInScreen(auth: auth, linkService: linkService, config: config);
        }
        return HomeShell(
          key: ValueKey(user.uid),
          auth: auth,
          user: user,
          linkService: linkService,
          config: config,
        );
      },
    );
  }
}
