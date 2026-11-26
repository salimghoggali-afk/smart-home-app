import 'package:flutter_test/flutter_test.dart';
import 'package:smarthome/core/admin_lock.dart';

// Expected codes made with Python's hmac module, so the app and the
// generator page (browser WebCrypto) agree on the same standard math.
final _secret = List<int>.generate(32, (i) => i);

void main() {
  test('daily code matches the reference values', () async {
    expect(await AdminLock.codeFor(_secret, 'my-home-demo', '2026-11-26'), '33155906');
    expect(await AdminLock.codeFor(_secret, 'my-home-demo', '2026-11-27'), '05405846');
  });

  test('code changes with the home', () async {
    final a = await AdminLock.codeFor(_secret, 'my-home-demo', '2026-11-26');
    final b = await AdminLock.codeFor(_secret, 'other-home', '2026-11-26');
    expect(a, isNot(b));
    expect(a.length, 8);
  });

  test('the day follows Algeria time (UTC+1)', () {
    expect(AdminLock.algeriaDay(DateTime.utc(2026, 11, 26, 22, 59)), '2026-11-26');
    expect(AdminLock.algeriaDay(DateTime.utc(2026, 11, 26, 23, 0)), '2026-11-27');
    expect(AdminLock.algeriaDay(DateTime.utc(2026, 12, 31, 23, 30)), '2027-01-01');
  });
}
