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
    await v.save(limited: true, rooms: {'son'});
    final h = v.filter(_home());
    expect(h.floors.map((f) => f.id), ['f1']);
    expect(h.floors.single.rooms.map((r) => r.id), ['son']);
  });

  test('the choice is saved per linked home and survives a restart', () async {
    final v = VisibilitySettings.instance;
    await v.load('p1');
    await v.save(limited: true, rooms: {'son'});
    await v.load('p2');
    expect(v.limited, isFalse);
    await v.load('p1');
    expect(v.limited, isTrue);
    expect(v.shownRooms, {'son'});
  });
}
