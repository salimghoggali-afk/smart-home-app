import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarthome/core/home_repository.dart';
import 'package:smarthome/core/visibility_settings.dart';
import 'package:smarthome/screens/floor_view.dart';
import 'package:smarthome/ui/theme.dart';

class _FakeRepo extends HomeRepository {
  _FakeRepo(this.raw);
  final Object raw;
  final sent = <String>[];

  @override
  Stream<List<Home>> watchHomes() => Stream.value(HomeRepository.parseHomes(raw));

  @override
  Future<void> setLevel(int h, int f, Lamp lamp, int level) async =>
      sent.add('level ${lamp.name} $level');

  @override
  Future<void> setLocked(int h, int f, Lamp lamp, bool locked) async =>
      sent.add('lock ${lamp.name} $locked');

  @override
  Future<void> setMode(int h, int f, Lamp lamp, LampMode mode) async =>
      sent.add('mode ${lamp.name} ${mode.name}');
}

final _raw = [
  {
    'name': 'Villa',
    'floors': [
      {
        'name': 'Ground floor',
        'lamps': [
          {'name': 'Ceiling', 'order': 60, 'state': 60, 'lockstate': true, 'mode': 'dimmer'},
          {'name': 'Bedside lamp with a long name', 'order': 0, 'state': 0, 'mode': 'switch'},
          {'name': 'Mirror', 'order': 100, 'state': 0, 'mode': 'switch'},
          {'name': 'Hall', 'state': 100},
        ],
        'rooms': [
          {
            'name': 'Chambre 1',
            'type': 'bedroom',
            'lamps': [{'position': 1}, {'position': 2}],
            'rooms': [
              {'name': 'Salle de bain', 'type': 'bathroom', 'lamps': [{'position': 3}]},
            ],
          },
          {'name': 'Hall', 'type': 'hall', 'lamps': [{'position': 4}]},
          {'name': 'Kitchen', 'type': 'kitchen'},
        ],
      },
      {'name': 'First floor'},
    ],
  },
];

Future<_FakeRepo> _pump(WidgetTester t, Brightness b) async {
  SharedPreferences.setMockInitialValues({});
  await VisibilitySettings.instance.load('test');
  t.view.physicalSize = const Size(360 * 3, 760 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final repo = _FakeRepo(_raw);
  await t.pumpWidget(MaterialApp(
    theme: buildTheme(b),
    home: Scaffold(
      body: FloorHomeView(repo: repo, isOwner: true, onConfigure: () {}),
    ),
  ));
  await t.pumpAndSettle();
  return repo;
}

void main() {
  for (final b in Brightness.values) {
    testWidgets('floor shows rooms and the opened room controls lamps (${b.name})',
        (t) async {
      final repo = await _pump(t, b);
      expect(find.text('Villa'), findsOneWidget);
      expect(find.text('Chambre 1'), findsOneWidget);
      expect(find.text('Ground floor'), findsOneWidget);

      await t.tap(find.text('Chambre 1'));
      await t.pumpAndSettle();
      expect(find.text('Salle de bain'), findsWidgets);
      expect(find.text('Sent 100%, waiting for the board'), findsOneWidget);

      await t.tap(find.text('All off'));
      await t.pumpAndSettle();
      expect(repo.sent, contains('level Ceiling 0'));

      await t.tap(find.text('On / Off').first);
      await t.pumpAndSettle();
      expect(repo.sent.last, startsWith('mode '));
    });
  }
}
