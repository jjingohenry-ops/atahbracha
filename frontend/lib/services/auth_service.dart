import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email/Password Sign Up
  Future<UserModel?> signUp(String email, String password, String firstName, String lastName) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName('$firstName $lastName');

      return UserModel(
        id: userCredential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: 'FARMER',
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Email/Password Sign In
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return UserModel(
        id: userCredential.user!.uid,
        email: email,
        firstName: userCredential.user!.displayName?.split(' ').first ?? '',
        lastName: userCredential.user!.displayName?.split(' ').skip(1).join(' ') ?? '',
        role: 'FARMER',
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Google Sign In
  Future<UserModel?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // Prefer popup on desktop web, but fall back to redirect for mobile browsers.
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');

        try {
          userCredential = await _auth.signInWithPopup(provider);
        } on FirebaseAuthException catch (e) {
          final shouldFallbackToRedirect =
              e.code == 'popup-blocked' ||
              e.code == 'popup-closed-by-user' ||
              e.code == 'operation-not-supported-in-this-environment';

          if (shouldFallbackToRedirect) {
            await _auth.signInWithRedirect(provider);
            throw 'REDIRECT_IN_PROGRESS';
          }

          rethrow;
        }
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final names = userCredential.user!.displayName?.split(' ') ?? ['', ''];
      return UserModel(
        id: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        firstName: names.isNotEmpty ? names.first : '',
        lastName: names.length > 1 ? names.skip(1).join(' ') : '',
        role: 'FARMER',
      );
    } catch (e) {
      if (e.toString().contains('REDIRECT_IN_PROGRESS')) {
        rethrow;
      }
      throw _handleAuthError(e);
    }
  }

  // Phone Sign In - Send verification code
  Future<String> signInWithPhoneSendCode(String phoneNumber) async {
    final completer = Completer<String>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-signin on Android
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(_handleAuthError(e));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
      );

      return await completer.future;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Phone Sign In - Verify code
  Future<UserModel?> verifyPhoneCode(String verificationId, String smsCode) async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      return UserModel(
        id: userCredential.user!.uid,
        email: '',
        firstName: 'Phone',
        lastName: 'User',
        role: 'FARMER',
        phone: userCredential.user!.phoneNumber ?? '',
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    Object? lastError;

    // Google sign-out may fail for non-Google sessions; do not let it block Firebase sign-out.
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      lastError = e;
      debugPrint('Google sign-out warning: $e');
    }

    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Sign out failed: ${e.toString()}';
    }

    // If Firebase sign-out succeeded, ignore secondary provider warnings.
    if (lastError != null) {
      debugPrint('Sign-out completed with non-blocking warning: $lastError');
    }
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Update Profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      throw 'Profile update failed: ${e.toString()}';
    }
  }

  // Change Password
  Future<void> changePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Handle Firebase Auth Errors
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        case 'too-many-requests':
          return 'Too many requests. Try again later.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        default:
          return 'Authentication error: ${error.message}';
      }
    }
    return 'An unexpected error occurred: ${error.toString()}';
  }
}
