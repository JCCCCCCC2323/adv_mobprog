import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';
import '../utils/firebase_profile_cache.dart';

enum LoginType { dummyJson, firebase, none }

final ValueNotifier<UserService> userService = ValueNotifier(UserService());

// Enhancement 1: Manage Firebase accounts and the saved local session.
//Ocray do this completed//
class UserService {
  Map<String, dynamic> data = {};

  firebase_auth.FirebaseAuth get firebaseAuth =>
      firebase_auth.FirebaseAuth.instance;

  firebase_auth.User? get currentUser =>
      Firebase.apps.isEmpty ? null : firebaseAuth.currentUser;

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

  Future<void> signOut() async {
    if (Firebase.apps.isNotEmpty) await firebaseAuth.signOut();
  }

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
    final uid = currentUser?.uid;
    if (uid == null) throw StateError('Sign in before saving a profile.');

    // Keep this local copy under the Firebase UID, not shared across emails.
    await FirebaseProfileCache(prefs).save(uid, {
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'contactNumber': contactNumber,
      'username': username,
      'email': email,
    });

    await FirebaseFirestore.instance.collection('Users').doc(uid).set({
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'contactNumber': contactNumber,
      'username': username,
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    final firebaseUser = currentUser;
    if (firebaseUser != null) {
      return _getFirebaseUserData(firebaseUser);
    }

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

  Future<Map<String, dynamic>> _getFirebaseUserData(
    firebase_auth.User firebaseUser,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = firebaseUser.uid;
    final profile = FirebaseProfileCache(prefs).load(uid);

    // Read the old shared fields only when they belong to this exact UID.
    if (profile.isEmpty && prefs.getString('firebaseUid') == uid) {
      profile.addAll({
        'firstName': prefs.getString('firstName') ?? '',
        'lastName': prefs.getString('lastName') ?? '',
        'age': prefs.getInt('age') ?? 0,
        'contactNumber': prefs.getString('contactNumber') ?? '',
        'username': prefs.getString('username') ?? '',
      });
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .get();
      if (snapshot.exists) profile.addAll(snapshot.data() ?? {});
    } on FirebaseException catch (error) {
      debugPrint('Could not load Firebase profile: ${error.code}');
    }

    final email = firebaseUser.email?.trim() ?? '';
    final savedUsername = (profile['username'] ?? '').toString().trim();
    final displayName = firebaseUser.displayName?.trim() ?? '';
    final age = profile['age'];
    return {
      'id': 0,
      'firebaseUid': uid,
      'username': savedUsername.isNotEmpty
          ? savedUsername
          : displayName.isNotEmpty
          ? displayName
          : email.split('@').first,
      'email': email,
      'firstName': (profile['firstName'] ?? '').toString(),
      'lastName': (profile['lastName'] ?? '').toString(),
      'gender': (profile['gender'] ?? '').toString(),
      'age': age is int ? age : int.tryParse('$age') ?? 0,
      'contactNumber': (profile['contactNumber'] ?? '').toString(),
      'image': (profile['image'] ?? firebaseUser.photoURL ?? '').toString(),
      'accessToken': '',
      'refreshToken': '',
      'token': '',
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
