import 'package:flutter/material.dart';

import '../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  //Ocray do this completed//
  // Returning users stay signed in when the app opens again.
  Future<void> _checkAuthentication() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    try {
      final loggedIn = await _userService.isLoggedIn();
      if (!mounted) return;

      if (loggedIn) {
        final userData = await _userService.getUserData();
        if (!mounted) return;
        if ((userData['id'] as int? ?? 0) > 0) {
          Navigator.pushReplacementNamed(context, '/home', arguments: userData);
          return;
        }
      }
    } catch (_) {
      // Missing or unreadable saved data should return to sign in safely.
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const navy = Color(0xFF263C86);
    const gold = Color(0xFFFFC928);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF161B32), Color(0xFF252C4E)]
                : const [Color(0xFFF8F5FF), Color(0xFFE8ECFF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 136,
                  height: 136,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: navy.withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/nuicon.jpeg',
                    fit: BoxFit.contain,
                    semanticLabel: 'NUDB Exchange logo',
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'NUDB Exchange',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: isDark ? Colors.white : navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your campus finds, all in one place.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : const Color(0xFF5E6688),
                  ),
                ),
                const Spacer(),
                const CircularProgressIndicator(color: gold, strokeWidth: 3),
                const SizedBox(height: 16),
                Text(
                  'Getting things ready...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white70 : const Color(0xFF5E6688),
                  ),
                ),
                const SizedBox(height: 38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
