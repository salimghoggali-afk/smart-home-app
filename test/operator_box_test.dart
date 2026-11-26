import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:smarthome/core/admin_lock.dart';
import 'package:smarthome/screens/unlock_sheet.dart';

class _FakeLock extends AdminLock {
  _FakeLock({this.ready = true});
  final bool ready;
  bool unlocked = false;

  @override
  bool get operatorUnlocked => unlocked;

  @override
  Future<({bool ready, String contact, String? problem})> operatorInfo() async =>
      (
        ready: ready,
        contact: AdminLock.defaultContact,
        problem: ready ? null : 'No operator secret is set for this home yet.'
      );

  @override
  Future<bool> unlockOperator(String code, String projectId) async {
    unlocked = code == '12345678';
    return unlocked;
  }
}

Future<bool?> _open(WidgetTester t, AdminLock lock) async {
  bool? result;
  await t.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (c) => TextButton(
          onPressed: () async => result = await askOperatorCode(c, lock, 'p'),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await t.tap(find.text('open'));
  await t.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('box shows the field and how to get the code', (t) async {
    await _open(t, _FakeLock());
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('How to get the code'), findsOneWidget);
    expect(find.textContaining('+213 665 98 09 64'), findsOneWidget);
    expect(find.textContaining('+213 674 43 45 78'), findsOneWidget);
  });

  testWidgets('wrong code shows an error and keeps the box open', (t) async {
    await _open(t, _FakeLock());
    await t.enterText(find.byType(TextField), '11111111');
    await t.tap(find.text('Verify and open'));
    await t.pumpAndSettle();
    expect(find.textContaining('not valid today'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('right code closes the box and grants access', (t) async {
    final lock = _FakeLock();
    bool? result;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (c) => TextButton(
            onPressed: () async => result = await askOperatorCode(c, lock, 'p'),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), '12345678');
    await t.tap(find.text('Verify and open'));
    await t.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(result, isTrue);
    expect(find.text('Access granted.'), findsOneWidget);
  });

  testWidgets('home without a secret explains the problem', (t) async {
    await _open(t, _FakeLock(ready: false));
    await t.enterText(find.byType(TextField), '12345678');
    await t.tap(find.text('Verify and open'));
    await t.pumpAndSettle();
    expect(find.textContaining('No operator secret'), findsOneWidget);
  });
}
