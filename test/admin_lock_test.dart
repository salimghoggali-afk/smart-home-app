import 'package:flutter_test/flutter_test.dart';
import 'package:smarthome/core/admin_lock.dart';

// Made with Python: hashlib.pbkdf2_hmac('sha256', code, bytes(range(16)), 10000)
// The QR maker page uses the browser's PBKDF2, which follows the same standard.
const _record =
    r'pbkdf2-sha256$10000$AAECAwQFBgcICQoLDA0ODw==$jELRIlqI1odCd76J35ZiQ0If6JhfHykj/WndLJ64V3Y=';

void main() {
  test('accepts the right code from another PBKDF2 implementation', () async {
    expect(await AdminLock.verify('My-Config#Code2026', _record), isTrue);
  });

  test('refuses a wrong code', () async {
    expect(await AdminLock.verify('My-Config#Code2027', _record), isFalse);
    expect(await AdminLock.verify('', _record), isFalse);
  });

  test('refuses broken records', () async {
    expect(await AdminLock.verify('x', 'plain-text-code'), isFalse);
    expect(AdminLock.parseRecord(r'pbkdf2-sha256$5$AA==$AA=='), isNull);
    expect(AdminLock.parseRecord(42), isNull);
  });

  test('round trip with a new random salt', () async {
    final r = await AdminLock.makeRecord('Another#Code99', rounds: 10000);
    expect(await AdminLock.verify('Another#Code99', r), isTrue);
    expect(await AdminLock.verify('another#code99', r), isFalse);
  });
}
