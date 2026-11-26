import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'firebase_link_config.dart';

/// Result of checking a config against Google's servers.
class LinkCheck {
  const LinkCheck._(this.ok, this.message, {this.warning = false});
  const LinkCheck.ok() : this._(true, null);
  const LinkCheck.warning(String m) : this._(true, m, warning: true);
  const LinkCheck.error(String m) : this._(false, m);

  final bool ok;
  final bool warning;
  final String? message;
}

/// Saves the linked Firebase project on the phone and starts Firebase with it.
class LinkService {
  LinkService({FlutterSecureStorage? storage, http.Client? client})
      : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  static const _key = 'firebase_link_config_v1';
  final FlutterSecureStorage _storage;
  final http.Client _client;

  Future<FirebaseLinkConfig?> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      return FirebaseLinkConfig.fromMap(
          (jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      // A broken saved value should never block the app: start over.
      await _storage.delete(key: _key);
      return null;
    }
  }

  Future<void> save(FirebaseLinkConfig config) =>
      _storage.write(key: _key, value: config.encode());

  /// Asks Google if the API key belongs to a live project.
  ///
  /// Only a clear "this key is wrong" answer is an error. Other answers, such
  /// as a key limited to Android apps or no network, are warnings, because the
  /// Firebase SDK on the phone can still work.
  Future<LinkCheck> check(FirebaseLinkConfig config) async {
    try {
      final uri = Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/projects?key=${config.apiKey}');
      final res = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map;
        final id = body['projectId']?.toString();
        if (id != null && id != config.projectId && id != config.messagingSenderId) {
          return const LinkCheck.error(
              'The API key belongs to another Firebase project.');
        }
        return const LinkCheck.ok();
      }
      final text = res.body;
      if (text.contains('API_KEY_INVALID') || text.contains('API key not valid')) {
        return const LinkCheck.error('Google says this API key is not valid.');
      }
      if (text.contains('SERVICE_DISABLED') || text.contains('has not been used')) {
        return const LinkCheck.warning(
            'Authentication is not turned on in this Firebase project yet. '
            'You can link it now and turn it on later in the console.');
      }
      return const LinkCheck.warning(
          'The key could not be fully checked, but the app can still try it.');
    } catch (_) {
      return const LinkCheck.warning(
          'No internet connection, so the project was not checked online.');
    }
  }

  /// Starts (or restarts) the default Firebase app with this config.
  Future<FirebaseApp> start(FirebaseLinkConfig config) async {
    if (Firebase.apps.isNotEmpty) {
      final current = Firebase.app();
      if (current.options.appId == config.appId &&
          current.options.apiKey == config.apiKey) {
        return current;
      }
      await current.delete();
    }
    return Firebase.initializeApp(options: config.toOptions());
  }

  /// Forgets the linked project. The user goes back to the start screen.
  Future<void> reset() async {
    await _storage.delete(key: _key);
    if (Firebase.apps.isNotEmpty) {
      try {
        await Firebase.app().delete();
      } catch (_) {}
    }
  }
}
