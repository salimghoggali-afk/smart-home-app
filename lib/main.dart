import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'core/display_settings.dart';
import 'core/link_service.dart';
import 'screens/splash_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  await DisplaySettings.instance.load();
  runApp(MyHomeApp(linkService: LinkService()));
}

class MyHomeApp extends StatelessWidget {
  const MyHomeApp({super.key, required this.linkService});

  final LinkService linkService;

  @override
  Widget build(BuildContext context) {
    final display = DisplaySettings.instance;
    return ListenableBuilder(
      listenable: display,
      builder: (context, _) => MaterialApp(
        title: 'My Home',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: display.mode,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(display.textScale)),
          child: child!,
        ),
        home: SplashScreen(linkService: linkService),
      ),
    );
  }
}
