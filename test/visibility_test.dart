import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarthome/core/home_repository.dart';
import 'package:smarthome/core/visibility_settings.dart';

Home _home() => Home(id: 'h', name: 'Home', floors: [
      Floor(id: 'f0', name: 'Ground', rooms: [
        Room(id: 'living', name: 'Living', type: 'living room'),
        Room(id: 'kitchen', name: 'Kitchen', type: 'kitchen'),
      ]),
      Floor(id: 'f1', name: 'First', rooms: [
        Room(id: 'son', name: 'Son', type: 'bedroom'),
        Room(id: 'parents', name: 'Parents', type: 'bedroom'),
      ]),
    ]);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('shows the whole home by default', () async {
    final v = VisibilitySettings.instance;
    await v.load('p1');
    expect(v.filter(_home()).roomCount, 4);
  });

  test('shows only chosen rooms and hides empty floors', () async {
    final v = VisibilitySettings.instance;
    await v.load('p1');
    await v.setMode(0, HomeShow.chosen);
    await v.setRooms({'son'});
    final h = v.filter(_home());
    expect(h.floors.map((f) => f.id), ['f1']);
    expect(h.floors.single.rooms.map((r) => r.id), ['son']);
  });

  test('the choice is saved per linked home and survives a restart', () async {
    final v = VisibilitySettings.instance;
    await v.load('p1');
    await v.setMode(0, HomeShow.chosen);
    await v.setRooms({'son'});
    await v.load('p2');
    expect(v.limited, isFalse);
    await v.load('p1');
    expect(v.limited, isTrue);
    expect(v.shownRooms, {'son'});
  });

  test('each home of the project has its own choice', () async {
    final v = VisibilitySettings.instance;
    await v.load('p3');
    await v.setMode(0, HomeShow.chosen);
    await v.setMode(1, HomeShow.hidden);
    final homes = [
      Home(id: '0', index: 0, name: 'Villa', floors: []),
      Home(id: '1', index: 1, name: 'Flat', floors: []),
      Home(id: '2', index: 2, name: 'Farm', floors: []),
    ];
    expect(v.modeOf(2), HomeShow.all);
    expect(v.visible(homes).map((h) => h.name), ['Villa', 'Farm']);
    await v.selectHome(1);
    // A hidden home is never opened on the Home page, but Settings can still edit it.
    expect(v.pick(homes)?.name, 'Villa');
    expect(v.pickAny(homes)?.name, 'Flat');
    await v.load('p3');
    expect(v.modeOf(1), HomeShow.hidden);
  });

  test('a v1.6 choice for the whole project still applies', () async {
    SharedPreferences.setMockInitialValues({'vis.old.limited': true});
    final v = VisibilitySettings.instance;
    await v.load('old');
    expect(v.modeOf(0), HomeShow.chosen);
    expect(v.modeOf(5), HomeShow.chosen);
  });
}
