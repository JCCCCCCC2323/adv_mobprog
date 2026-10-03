// Read-only helpers for searching the profiles already in Firestore.
String chatUserDisplayName(Map<String, dynamic> user) {
  final firstName = (user['firstName'] ?? '').toString().trim();
  final lastName = (user['lastName'] ?? '').toString().trim();
  final fullName = '$firstName $lastName'.trim();
  if (fullName.isNotEmpty) return fullName;

  for (final key in ['displayName', 'name', 'username', 'email']) {
    final value = (user[key] ?? '').toString().trim();
    if (value.isNotEmpty) return value;
  }
  return 'Unknown user';
}

bool chatUserMatchesSearch(Map<String, dynamic> user, String searchText) {
  final query = searchText.trim().toLowerCase();
  if (query.isEmpty) return true;

  final fields = [
    chatUserDisplayName(user),
    user['firstName'],
    user['lastName'],
    user['displayName'],
    user['name'],
    user['username'],
    user['email'],
  ];
  return fields.any(
    (value) => (value ?? '').toString().toLowerCase().contains(query),
  );
}
