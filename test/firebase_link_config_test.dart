import 'package:flutter_test/flutter_test.dart';
import 'package:smarthome/core/firebase_link_config.dart';

const _key = 'AIzaSyA1234567890abcdefghijklmnopqrstuv';

void main() {
  test('reads our QR format', () {
    final c = FirebaseLinkConfig.parse('{"v":1,"apiKey":"$_key",'
        '"appId":"1:1234:android:abcdef","projectId":"my-home-1",'
        '"messagingSenderId":"1234",'
        '"databaseURL":"https://my-home-1-default-rtdb.firebaseio.com"}');
    expect(c.projectId, 'my-home-1');
    expect(c.toOptions().databaseURL, contains('firebaseio.com'));
    expect(FirebaseLinkConfig.parse(c.encode()).appId, c.appId);
  });

  test('reads google-services.json and picks our package', () {
    final c = FirebaseLinkConfig.parse('''
{"project_info":{"project_number":"999","firebase_url":"https://p-1-default-rtdb.firebaseio.com","project_id":"p-one","storage_bucket":"p-one.appspot.com"},
 "client":[
  {"client_info":{"mobilesdk_app_id":"1:999:android:aaaa","android_client_info":{"package_name":"other.app"}},"api_key":[{"current_key":"$_key"}]},
  {"client_info":{"mobilesdk_app_id":"1:999:android:bbbb","android_client_info":{"package_name":"com.ghoggalisalim.smarthome"}},
   "oauth_client":[{"client_id":"web-123.apps.googleusercontent.com","client_type":3}],
   "api_key":[{"current_key":"$_key"}]}]}
''', androidPackage: 'com.ghoggalisalim.smarthome');
    expect(c.appId, '1:999:android:bbbb');
    expect(c.messagingSenderId, '999');
    expect(c.webClientId, 'web-123.apps.googleusercontent.com');
  });

  test('reads the JavaScript object from the web console', () {
    final c = FirebaseLinkConfig.parse('''
const firebaseConfig = {
  apiKey: "$_key",
  projectId: "my-home-1",
  messagingSenderId: "1234",
  appId: "1:1234:android:abcdef",
};''');
    expect(c.projectId, 'my-home-1');
  });

  test('rejects bad input with a clear message', () {
    expect(() => FirebaseLinkConfig.parse('hello'),
        throwsA(isA<FormatException>()));
    expect(
        () => FirebaseLinkConfig.parse('{"apiKey":"bad","appId":"x",'
            '"projectId":"p-one","messagingSenderId":"1"}'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('API key'))));
    expect(
        () => FirebaseLinkConfig.parse('{"apiKey":"$_key",'
            '"appId":"1:1:web:abc","projectId":"p-one","messagingSenderId":"1"}'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('web or iOS'))));
  });
}
