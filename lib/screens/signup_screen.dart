import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Enhancement 2: Create a validated Firebase email/password account.
  //Ocray do this completed//
  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _userService.createAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _userService.updateUsername(
        username: _usernameController.text.trim(),
      );
      await _userService.saveFirebaseUserProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.parse(_ageController.text),
        contactNumber: _contactController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'email-already-in-use' => 'This email already has an account.',
        'invalid-email' => 'Please enter a valid email address.',
        'weak-password' => 'Use a stronger password.',
        _ => error.message ?? 'Account creation failed.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account creation failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(20.r),
            children: [
              Text(
                'Sign Up',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _firstNameController,
                      label: 'First name',
                      validator: (value) => _required(value, 'First name'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _field(
                      controller: _lastNameController,
                      label: 'Last name',
                      validator: (value) => _required(value, 'Last name'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              _field(
                controller: _ageController,
                label: 'Age',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  if (age == null || age < 1 || age > 120) {
                    return 'Enter a valid age from 1 to 120';
                  }
                  return null;
                },
              ),
              SizedBox(height: 14.h),
              _field(
                controller: _contactController,
                label: 'Contact number',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final contact = value?.trim() ?? '';
                  if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(contact)) {
                    return 'Enter 10 to 15 digits';
                  }
                  return null;
                },
              ),
              SizedBox(height: 14.h),
              _field(
                controller: _usernameController,
                label: 'Username',
                validator: (value) {
                  final username = value?.trim() ?? '';
                  if (username.length < 3) {
                    return 'Username must have at least 3 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 14.h),
              _field(
                controller: _emailController,
                label: 'Email address',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 14.h),
              TextFormField(
                controller: _passwordController,
                obscureText: _hidePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').length < 6) {
                    return 'Password must have at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.h),
              SizedBox(
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAccount,
                  child: _isLoading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text('Create Account'),
                ),
              ),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Already have an account? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
