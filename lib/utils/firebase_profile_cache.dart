import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FirebaseProfileCache {
  FirebaseProfileCache(this.prefs);

  final SharedPreferences prefs;

  String _key(String uid) => 'firebaseProfile:$uid';

  Map<String, dynamic> load(String uid) {
    final encoded = prefs.getString(_key(uid));
    if (encoded == null) return {};

    try {
      final value = jsonDecode(encoded);
      return value is Map<String, dynamic> ? value : {};
    } on FormatException {
      return {};
    }
  }

  Future<void> save(String uid, Map<String, dynamic> profile) =>
      prefs.setString(_key(uid), jsonEncode(profile));
}
