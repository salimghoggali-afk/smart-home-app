import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'core/link_service.dart';
import 'screens/splash_screen.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(MyHomeApp(linkService: LinkService()));
}

class MyHomeApp extends StatelessWidget {
  const MyHomeApp({super.key, required this.linkService});

  final LinkService linkService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Home',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: SplashScreen(linkService: linkService),
    );
  }
}
