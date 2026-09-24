import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

enum LoginType { dummyJson, firebase, none }

final ValueNotifier<UserService> userService = ValueNotifier(UserService());

// Enhancement 1: Manage Firebase accounts and the saved local session.
//Ocray do this completed//
class UserService {
  Map<String, dynamic> data = {};

  final firebase_auth.FirebaseAuth firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  firebase_auth.User? get currentUser => firebaseAuth.currentUser;

  Stream<firebase_auth.User?> get authStateChanges =>
      firebaseAuth.authStateChanges();

  Future<firebase_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _saveLoginType(LoginType.firebase);
    return credential;
  }

  Future<firebase_auth.UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _saveLoginType(LoginType.firebase);
    return credential;
  }

  Future<void> signOut() => firebaseAuth.signOut();

  Future<void> updateUsername({required String username}) async {
    await currentUser?.updateDisplayName(username);
    await currentUser?.reload();
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in.',
      );
    }

    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
    await user.delete();
    await _clearSavedSession();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in.',
      );
    }

    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> saveFirebaseUserProfile({
    required String firstName,
    required String lastName,
    required int age,
    required String contactNumber,
    required String username,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firebaseUid', currentUser?.uid ?? '');
    await prefs.setString('firstName', firstName);
    await prefs.setString('lastName', lastName);
    await prefs.setInt('age', age);
    await prefs.setString('contactNumber', contactNumber);
    await prefs.setString('username', username);
    await prefs.setString('email', email);
  }

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body) as Map<String, dynamic>;
      await saveUserData(data);
      await _saveLoginType(LoginType.dummyJson);
      return data;
    }

    throw Exception(response.body);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);

    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token']?.toString() ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'age': prefs.getInt('age') ?? 0,
      'contactNumber': prefs.getString('contactNumber') ?? '',
      'firebaseUid': prefs.getString('firebaseUid') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
    };
  }

  Future<LoginType> getLoginType() async {
    if (currentUser != null) return LoginType.firebase;

    final prefs = await SharedPreferences.getInstance();
    final savedType = prefs.getString('loginType');
    if (savedType == LoginType.firebase.name) return LoginType.firebase;
    if (savedType == LoginType.dummyJson.name) return LoginType.dummyJson;
    return LoginType.none;
  }

  Future<void> _saveLoginType(LoginType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', type.name);
  }

  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  Future<bool> isLoggedIn() async {
    if (currentUser != null) return true;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  // Enhancement 1: Logout clears Firebase and local tokens.
  //Ocray do this completed//
  Future<void> logout() async {
    try {
      await signOut();
      await _clearSavedSession();
    } catch (error) {
      throw Exception('Failed to log out: $error');
    }
  }

  Future<void> _clearSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('token');
    await prefs.remove('loginType');
  }
}
