import 'package:flutter_test/flutter_test.dart';
import 'package:smarthome/core/home_repository.dart';

void main() {
  // The shape Firebase returns: lists, with archived items left in place.
  final raw = [
    {
      'name': 'Villa',
      'floors': [
        {
          'name': 'Ground floor',
          'lamps': [
            {'name': 'Ceiling', 'order': 60, 'state': 60, 'locked': true, 'lockstate': true, 'mode': 'dimmer'},
            {'name': 'Old', 'archived': true, 'state': 100},
            {'name': 'Wall', 'order': 100, 'state': 0, 'locked': 'none', 'lockstate': false, 'mode': 'switch'},
            {'name': 'Spare', 'order': 'none', 'state': 0},
          ],
          'rooms': [
            {
              'name': 'Bedroom 1',
              'type': 'bedroom',
              'lamps': [{'position': 1}, {'position': 2}],
              'rooms': [
                {'name': 'Bath', 'type': 'bathroom', 'lamps': [{'position': 3}]},
              ],
            },
            {'name': 'Gone', 'type': 'kitchen', 'archived': true},
          ],
        },
      ],
    },
    {'name': 'Removed home', 'archived': true},
  ];

  test('reads homes, floors, lamps and rooms from lists', () {
    final homes = HomeRepository.parseHomes(raw);
    expect(homes.length, 1);
    final f = homes.single.floors.single;
    expect(f.name, 'Ground floor');
    expect(f.lamps.map((l) => l.name), ['Ceiling', 'Wall', 'Spare']);
    expect(f.rooms.single.name, 'Bedroom 1');
    final room = f.rooms.single;
    // Position 2 points to the archived lamp, so it is dropped.
    expect(f.lampsOf(room).map((l) => l.name), ['Ceiling']);
    expect(room.subRooms.single.name, 'Bath');
    expect(f.allLampsOf(room).map((l) => l.name), ['Ceiling', 'Wall']);
    expect(f.freeLamps.map((l) => l.name), ['Spare']);
  });

  test('lamp state, pending order and lock', () {
    final f = HomeRepository.parseHomes(raw).single.floors.single;
    final ceiling = f.lamps[0];
    expect(ceiling.state, 60);
    expect(ceiling.mode, LampMode.dimmer);
    expect(ceiling.pendingLevel, isNull);
    expect(ceiling.lockstate, isTrue);
    final wall = f.lamps[1];
    expect(wall.position, 3);
    expect(wall.pendingLevel, 100);
    expect(wall.pendingLock, isNull);
    expect(wall.mode, LampMode.onOff);
  });

  test('reads map-shaped lists too', () {
    final homes = HomeRepository.parseHomes({
      '0': {'name': 'A'},
      '2': {'name': 'C'},
    });
    expect(homes.map((h) => h.index), [0, 2]);
  });
}
