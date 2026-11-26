import 'package:material_ui/material_ui.dart';

import '../core/firebase_link_config.dart';
import '../core/link_service.dart';
import '../ui/app_logo.dart';
import '../ui/theme.dart';
import 'auth_gate.dart';
import 'link_start_screen.dart';

/// First screen. Plays a short animation while it loads the saved Firebase
/// link, then opens the start screen (no link yet) or the connected screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.linkService});

  final LinkService linkService;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
      parent: _c, curve: const Interval(0, 0.45, curve: Curves.easeOutBack));
  late final Animation<double> _glow = CurvedAnimation(
      parent: _c, curve: const Interval(0.35, 0.8, curve: Curves.easeInOut));
  late final Animation<double> _text = CurvedAnimation(
      parent: _c, curve: const Interval(0.5, 1, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final minTime = Future<void>.delayed(const Duration(milliseconds: 1900));
    FirebaseLinkConfig? config;
    String? startError;
    try {
      config = await widget.linkService.load();
      if (config != null) await widget.linkService.start(config);
    } catch (e) {
      startError = 'The saved project could not start. Please link it again.';
      config = null;
      await widget.linkService.reset();
    }
    await minTime;
    if (!mounted) return;
    final next = config != null
        ? AuthGate(linkService: widget.linkService, config: config)
        : LinkStartScreen(
            linkService: widget.linkService, initialError: startError);
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, _, _) => next,
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.night,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.1,
            colors: [Color(0xFF12323F), AppColors.night, AppColors.nightDeep],
          ),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Column(
            children: [
              const Spacer(flex: 5),
              Transform.scale(
                scale: 0.6 + 0.4 * _scale.value,
                child: Opacity(
                  opacity: _scale.value.clamp(0, 1).toDouble(),
                  child: AppLogo(size: 132, glow: _glow.value),
                ),
              ),
              const SizedBox(height: 28),
              Opacity(
                opacity: _text.value,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - _text.value)),
                  child: Column(
                    children: [
                      Text('My Home',
                          style: text.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      Text('Your home, in your hand',
                          style: text.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.65))),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 4),
              Opacity(
                opacity: _text.value,
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.glow),
                ),
              ),
              const SizedBox(height: 56),
            ],
          ),
        ),
      ),
    );
  }
}
