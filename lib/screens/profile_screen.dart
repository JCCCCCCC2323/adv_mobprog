import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  // Enhancement 3: Load profile data through UserService and LoginType.
  //Ocray do this completed//
  void _refreshProfile() {
    _profileFuture =
        Future.wait<dynamic>([
          _userService.getUserData(),
          _userService.getLoginType(),
        ]).then((results) {
          final profile = Map<String, dynamic>.from(
            results[0] as Map<String, dynamic>,
          );
          profile['loginType'] = results[1] as LoginType;
          return profile;
        });
  }

  Future<String?> _askForText({
    required String title,
    required String label,
    bool obscureText = false,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: obscureText,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _updateUsername(String currentUsername) async {
    final username = await _askForText(
      title: 'Update Username',
      label: 'New username',
      initialValue: currentUsername,
    );
    if (username == null || username.length < 3) return;

    try {
      await _userService.updateUsername(username: username);
      final data = await _userService.getUserData();
      await _userService.saveFirebaseUserProfile(
        firstName: data['firstName'] as String? ?? '',
        lastName: data['lastName'] as String? ?? '',
        age: data['age'] as int? ?? 0,
        contactNumber: data['contactNumber'] as String? ?? '',
        username: username,
        email: data['email'] as String? ?? '',
      );
      if (!mounted) return;
      setState(_refreshProfile);
      _showMessage('Username updated.');
    } catch (error) {
      if (mounted) _showMessage('Unable to update username: $error');
    }
  }

  Future<void> _changePassword(String email) async {
    final currentPassword = await _askForText(
      title: 'Change Password',
      label: 'Current password',
      obscureText: true,
    );
    if (currentPassword == null || currentPassword.isEmpty || !mounted) return;

    final newPassword = await _askForText(
      title: 'Change Password',
      label: 'New password (at least 6 characters)',
      obscureText: true,
    );
    if (newPassword == null || newPassword.length < 6) {
      if (mounted) {
        _showMessage('The new password needs at least 6 characters.');
      }
      return;
    }

    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        email: email,
      );
      if (mounted) _showMessage('Password changed successfully.');
    } catch (error) {
      if (mounted) _showMessage('Unable to change password: $error');
    }
  }

  Future<void> _deleteAccount(String email) async {
    final password = await _askForText(
      title: 'Delete Account',
      label: 'Enter your password to confirm',
      obscureText: true,
    );
    if (password == null || password.isEmpty || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account permanently?'),
        content: const Text('This Firebase account cannot be restored.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _userService.deleteAccount(email: email, password: password);
      CartService().resetCart();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (error) {
      if (mounted) _showMessage('Unable to delete account: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Unable to load user profile.'));
          }

          final data = snapshot.data!;
          final loginType = data['loginType'] as LoginType;
          final isFirebase = loginType == LoginType.firebase;
          final firebaseUser = _userService.currentUser;
          final username = isFirebase
              ? (data['username'] ?? firebaseUser?.displayName ?? '')
              : (data['username'] ?? '');
          final email = isFirebase
              ? (firebaseUser?.email ?? data['email'] ?? '')
              : (data['email'] ?? '');
          final fullName =
              '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
          final image = data['image'] as String? ?? '';

          return ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 24.h,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46.r,
                        backgroundImage: image.isEmpty
                            ? null
                            : NetworkImage(image),
                        child: image.isEmpty
                            ? Icon(Icons.person, size: 48.sp)
                            : null,
                      ),
                      SizedBox(height: 14.h),
                      CustomText(
                        text: fullName.isEmpty ? username : fullName,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        text: '@$username',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Chip(label: Text(isFirebase ? 'Firebase' : 'DummyJSON')),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Card(
                child: Column(
                  children: [
                    _ProfileRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: email,
                    ),
                    if (isFirebase) ...[
                      const Divider(height: 1),
                      _ProfileRow(
                        icon: Icons.cake_outlined,
                        label: 'Age',
                        value: '${data['age'] ?? ''}',
                      ),
                      const Divider(height: 1),
                      _ProfileRow(
                        icon: Icons.phone_outlined,
                        label: 'Contact',
                        value: data['contactNumber'] as String? ?? '',
                      ),
                      const Divider(height: 1),
                      _ProfileRow(
                        icon: Icons.fingerprint,
                        label: 'Firebase UID',
                        value: firebaseUser?.uid ?? '',
                      ),
                    ] else ...[
                      const Divider(height: 1),
                      _ProfileRow(
                        icon: Icons.people_outline,
                        label: 'Gender',
                        value: data['gender'] as String? ?? '',
                      ),
                      const Divider(height: 1),
                      _ProfileRow(
                        icon: Icons.badge_outlined,
                        label: 'User ID',
                        value: '#${data['id'] ?? 0}',
                      ),
                    ],
                  ],
                ),
              ),
              if (isFirebase) ...[
                SizedBox(height: 14.h),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Update username'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _updateUsername(username.toString()),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.password_outlined),
                        title: const Text('Change password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _changePassword(email.toString()),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        title: const Text(
                          'Delete account',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () => _deleteAccount(email.toString()),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber),
      title: CustomText(
        text: label,
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
      ),
      trailing: SizedBox(
        width: 190.w,
        child: CustomText(
          text: value,
          fontSize: 12.sp,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
