import 'package:flutter_test/flutter_test.dart';
import 'package:ocray_advmobprog/utils/chat_user_search.dart';

void main() {
  test('one letter finds a first name immediately', () {
    final user = {
      'firstName': 'Emily',
      'lastName': 'Johnson',
      'email': 'emily@example.com',
    };

    expect(chatUserMatchesSearch(user, 'e'), isTrue);
    expect(chatUserMatchesSearch(user, 'john'), isTrue);
    expect(chatUserMatchesSearch(user, 'x'), isTrue); // email domain
    expect(chatUserMatchesSearch(user, 'z'), isFalse);
  });

  test('email search ignores case and outer spaces', () {
    final user = {'displayName': 'Mia Cruz', 'email': 'Mia@Example.com'};

    expect(chatUserMatchesSearch(user, ' MIA@ '), isTrue);
    expect(chatUserMatchesSearch(user, 'cru'), isTrue);
    expect(chatUserDisplayName(user), 'Mia Cruz');
  });

  test('username and name-only profiles can be found', () {
    expect(chatUserMatchesSearch({'username': 'alex99'}, 'a'), isTrue);
    expect(chatUserMatchesSearch({'name': 'Sam Lee'}, 'lee'), isTrue);
  });
}
