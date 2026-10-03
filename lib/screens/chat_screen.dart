import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../utils/chat_user_search.dart';
import 'chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _usersStream = _chatService
      .getUsersStream();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Enhancement 1 and 2: Display other registered users and filter by
  // name or email using the search field.
  //Ocray do this completed//
  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Center(
        child: Text('Sign in with a Firebase account to use chat.'),
      );
    }

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search by name or email',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchText.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchText = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
              ],
              onChanged: (value) => setState(() => _searchText = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _usersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MessageState(
                    icon: Icons.cloud_off_outlined,
                    message: 'Unable to load users.\n${snapshot.error}',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final query = _searchText.trim().toLowerCase();
                // Update suggestions on every keystroke, including one letter.
                final users = snapshot.data!
                    .where((user) => chatUserMatchesSearch(user, query))
                    .toList();
                if (query.isNotEmpty) {
                  users.sort((first, second) {
                    bool startsWithQuery(Map<String, dynamic> user) {
                      final name = chatUserDisplayName(user).toLowerCase();
                      final email = (user['email'] ?? '')
                          .toString()
                          .toLowerCase();
                      return name.startsWith(query) || email.startsWith(query);
                    }

                    final firstStarts = startsWithQuery(first);
                    final secondStarts = startsWithQuery(second);
                    if (firstStarts != secondStarts) {
                      return firstStarts ? -1 : 1;
                    }
                    return chatUserDisplayName(first).toLowerCase().compareTo(
                      chatUserDisplayName(second).toLowerCase(),
                    );
                  });
                }

                if (users.isEmpty) {
                  return _MessageState(
                    icon: Icons.person_search_outlined,
                    message: query.isEmpty
                        ? 'No other users have chat profiles yet.'
                        : 'No user matches your search.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (query.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: Text(
                          'Suggested users',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        itemCount: users.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final name = chatUserDisplayName(user);
                          final email = (user['email'] ?? '').toString();
                          final uid = (user['uid'] ?? '').toString();

                          return TweenAnimationBuilder<double>(
                            key: ValueKey(uid),
                            duration: Duration(
                              milliseconds: 220 + (index * 35),
                            ),
                            tween: Tween(begin: 0, end: 1),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(24 * (1 - value), 0),
                                child: child,
                              ),
                            ),
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  child: Text(
                                    name.isEmpty ? '?' : name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  name.isEmpty ? 'Unknown user' : name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.chat_bubble_outline),
                                onTap: uid.isEmpty
                                    ? null
                                    : () => Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => ChatDetailsScreen(
                                            otherUserId: uid,
                                            otherUserName: name,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
