import 'package:flutter_test/flutter_test.dart';
import 'package:ocray_advmobprog/utils/firebase_profile_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Firebase profiles stay separate for different UIDs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = FirebaseProfileCache(prefs);

    await cache.save('account-a', {
      'firstName': 'Ana',
      'email': 'ana@example.com',
    });
    await cache.save('account-b', {
      'firstName': 'Ben',
      'email': 'ben@example.com',
    });

    expect(cache.load('account-a')['firstName'], 'Ana');
    expect(cache.load('account-b')['firstName'], 'Ben');
    expect(cache.load('account-c'), isEmpty);
  });
}
