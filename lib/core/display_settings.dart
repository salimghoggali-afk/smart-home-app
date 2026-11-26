import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme and text size, saved on this phone.
class DisplaySettings extends ChangeNotifier {
  DisplaySettings._();
  static final instance = DisplaySettings._();

  ThemeMode _mode = ThemeMode.system;
  double _textScale = 1.0;

  ThemeMode get mode => _mode;
  double get textScale => _textScale;

  static const textScales = <String, double>{
    'Normal': 1.0,
    'Large': 1.15,
    'Extra large': 1.3,
  };

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _mode = ThemeMode.values.firstWhere(
          (m) => m.name == p.getString('themeMode'),
          orElse: () => ThemeMode.system);
      _textScale = p.getDouble('textScale') ?? 1.0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode m) async {
    _mode = m;
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setString('themeMode', m.name);
    } catch (_) {}
  }

  Future<void> setTextScale(double s) async {
    _textScale = s;
    notifyListeners();
    try {
      (await SharedPreferences.getInstance()).setDouble('textScale', s);
    } catch (_) {}
  }
}
