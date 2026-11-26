import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';

/// The settings needed to connect the app to one Firebase project.
///
/// They come from a QR code or from manual entry, so the app is not tied to a
/// single project at build time.
class FirebaseLinkConfig {
  const FirebaseLinkConfig({
    required this.apiKey,
    required this.appId,
    required this.projectId,
    required this.messagingSenderId,
    this.databaseUrl,
    this.storageBucket,
    this.webClientId,
  });

  final String apiKey;
  final String appId;
  final String projectId;
  final String messagingSenderId;
  final String? databaseUrl;
  final String? storageBucket;

  /// OAuth web client id, used later for Google Sign-In.
  final String? webClientId;

  FirebaseOptions toOptions() => FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        projectId: projectId,
        messagingSenderId: messagingSenderId,
        databaseURL: databaseUrl,
        storageBucket: storageBucket,
      );

  Map<String, dynamic> toJson() => {
        'v': 1,
        'apiKey': apiKey,
        'appId': appId,
        'projectId': projectId,
        'messagingSenderId': messagingSenderId,
        if (databaseUrl != null) 'databaseURL': databaseUrl,
        if (storageBucket != null) 'storageBucket': storageBucket,
        if (webClientId != null) 'webClientId': webClientId,
      };

  String encode() => jsonEncode(toJson());

  /// Reads a config from text: our own QR format, the Firebase web config
  /// object (`firebaseConfig = {...}`), or a google-services.json file.
  ///
  /// Throws a [FormatException] with a message for the user when the text is
  /// not a usable config.
  static FirebaseLinkConfig parse(String raw, {String? androidPackage}) {
    final text = raw.trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('This is not a Firebase configuration.');
    }
    var body = text.substring(start, end + 1);
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      // The web console shows a JavaScript object with unquoted keys.
      body = body
          .replaceAllMapped(
              RegExp(r'([{,]\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:'),
              (m) => '${m[1]}"${m[2]}":')
          .replaceAll("'", '"')
          .replaceAll(RegExp(r',\s*}'), '}');
      try {
        decoded = jsonDecode(body);
      } on FormatException {
        throw const FormatException('The configuration text could not be read.');
      }
    }
    if (decoded is! Map) {
      throw const FormatException('This is not a Firebase configuration.');
    }
    final map = decoded.cast<String, dynamic>();
    if (map.containsKey('project_info') && map.containsKey('client')) {
      return _fromGoogleServices(map, androidPackage);
    }
    return fromMap(map);
  }

  static FirebaseLinkConfig fromMap(Map<String, dynamic> m) {
    String? s(String k) {
      final v = m[k];
      if (v == null) return null;
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }

    final config = FirebaseLinkConfig(
      apiKey: s('apiKey') ?? '',
      appId: s('appId') ?? '',
      projectId: s('projectId') ?? '',
      messagingSenderId: s('messagingSenderId') ?? '',
      databaseUrl: s('databaseURL') ?? s('databaseUrl'),
      storageBucket: s('storageBucket'),
      webClientId: s('webClientId'),
    );
    final problems = config.validate();
    if (problems.isNotEmpty) throw FormatException(problems.first);
    return config;
  }

  static FirebaseLinkConfig _fromGoogleServices(
      Map<String, dynamic> m, String? androidPackage) {
    final info = (m['project_info'] as Map).cast<String, dynamic>();
    final clients = (m['client'] as List).cast<Map>();
    if (clients.isEmpty) {
      throw const FormatException('google-services.json has no Android app.');
    }
    Map client = clients.first;
    if (androidPackage != null) {
      client = clients.firstWhere(
        (c) =>
            c['client_info']?['android_client_info']?['package_name'] ==
            androidPackage,
        orElse: () => clients.first,
      );
    }
    final oauth = (client['oauth_client'] as List? ?? const [])
        .cast<Map>()
        .where((o) => o['client_type'] == 3)
        .map((o) => o['client_id'] as String?)
        .firstWhere((id) => id != null, orElse: () => null);
    return fromMap({
      'apiKey': (client['api_key'] as List?)?.first?['current_key'],
      'appId': client['client_info']?['mobilesdk_app_id'],
      'projectId': info['project_id'],
      'messagingSenderId': info['project_number'],
      'databaseURL': info['firebase_url'],
      'storageBucket': info['storage_bucket'],
      'webClientId': oauth,
    });
  }

  /// Returns a list of problems in plain words; empty when the config is fine.
  List<String> validate() {
    final p = <String>[];
    if (!RegExp(r'^AIza[0-9A-Za-z_\-]{35}$').hasMatch(apiKey)) {
      p.add('The API key is missing or not valid. It starts with "AIza".');
    }
    if (!RegExp(r'^1:\d+:(android|web|ios):[0-9a-f]+$').hasMatch(appId)) {
      p.add('The App ID is missing or not valid. It looks like 1:1234:android:abcd.');
    } else if (!appId.contains(':android:')) {
      p.add('This App ID is for a web or iOS app. Use the Android app ID of the project.');
    }
    if (!RegExp(r'^[a-z0-9][a-z0-9\-]{4,29}$').hasMatch(projectId)) {
      p.add('The project ID is missing or not valid.');
    }
    if (!RegExp(r'^\d+$').hasMatch(messagingSenderId)) {
      p.add('The sender ID (project number) is missing or not valid.');
    }
    if (databaseUrl != null &&
        !RegExp(r'^https://[a-z0-9\-\.]+(firebaseio\.com|firebasedatabase\.app)/?$')
            .hasMatch(databaseUrl!)) {
      p.add('The database URL is not valid.');
    }
    return p;
  }
}
