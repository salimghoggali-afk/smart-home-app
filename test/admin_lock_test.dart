import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smarthome/core/admin_lock.dart';

// Expected codes made with Python's hmac module, so the app and the
// generator page (browser WebCrypto) agree on the same standard math.
final _secret = List<int>.generate(32, (i) => i);

void main() {
  test('daily code matches the reference values', () async {
    expect(await AdminLock.codeFor(_secret, '2026-11-26'), '24132422');
    expect(await AdminLock.codeFor(_secret, '2026-11-27'), '15461815');
  });

  test('code changes every day and has 8 digits', () async {
    final a = await AdminLock.codeFor(_secret, '2026-11-26');
    final b = await AdminLock.codeFor(_secret, '2026-11-27');
    expect(a, isNot(b));
    expect(a.length, 8);
  });

  test('the two halves join back into the master secret', () {
    final half = List<int>.generate(32, (i) => (i * 37 + 11) & 0xff);
    final other = [for (var i = 0; i < 32; i++) _secret[i] ^ half[i]];
    expect(AdminLock.joinShares(base64Encode(half), base64Encode(other)), _secret);
    expect(AdminLock.joinShares('', ''), isNull);
  });

  test('the day follows Algeria time (UTC+1)', () {
    expect(AdminLock.algeriaDay(DateTime.utc(2026, 11, 26, 22, 59)), '2026-11-26');
    expect(AdminLock.algeriaDay(DateTime.utc(2026, 11, 26, 23, 0)), '2026-11-27');
    expect(AdminLock.algeriaDay(DateTime.utc(2026, 12, 31, 23, 30)), '2027-01-01');
  });
}
