import 'package:flutter_test/flutter_test.dart';
import 'package:ocray_advmobprog/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('user data persists and logout clears authentication', () async {
    SharedPreferences.setMockInitialValues({});
    final service = UserService();

    await service.saveUserData({
      'id': 1,
      'username': 'emilys',
      'email': 'emily.johnson@x.dummyjson.com',
      'firstName': 'Emily',
      'lastName': 'Johnson',
      'gender': 'female',
      'image': 'https://dummyjson.com/icon/emilys/128',
      'accessToken': 'test-access-token',
      'refreshToken': 'test-refresh-token',
    });

    expect(await service.isLoggedIn(), isTrue);

    final user = await service.getUser();
    expect(user.id, 1);
    expect(user.username, 'emilys');
    expect(user.firstName, 'Emily');

    await service.logout();
    expect(await service.isLoggedIn(), isFalse);
  });
}
