import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../core/utils/user_error_message.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  StreamSubscription<User?>? _authStateSubscription;
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get requiresEmailVerification {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return false;

    final usesPasswordProvider = firebaseUser.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    return usesPasswordProvider && !firebaseUser.emailVerified;
  }

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() async {
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (firebaseUser) async {
        _isLoading = true;
        notifyListeners();

        try {
          if (firebaseUser == null) {
            _user = null;
            _errorMessage = null;
          } else {
            await _loadUserData(firebaseUser);
          }
        } catch (e) {
          _errorMessage = 'Failed to initialize authentication';
          debugPrint('Auth initialization error: $e');
          _user = null;
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      },
      onError: (Object error) {
        _errorMessage = 'Authentication listener error';
        _user = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> checkAuthStatus() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Check if user is already signed in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _loadUserData(currentUser);
      } else {
        _user = null;
      }
    } catch (e) {
      _errorMessage = 'Failed to check authentication status';
      debugPrint('Auth status check error: $e');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserData(User firebaseUser) async {
    try {
      // Try to get user data from API
      final userData = await _apiService.authenticateWithFirebase(firebaseUser);
      if (userData != null && userData.id == firebaseUser.uid) {
        _user = userData;
      } else {
        if (userData != null && userData.id != firebaseUser.uid) {
          debugPrint(
            'Auth identity mismatch detected. Firebase UID=${firebaseUser.uid}, API UID=${userData.id}',
          );
        }

        // Create user object from Firebase user
        _user = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          firstName: firebaseUser.displayName?.split(' ').first ?? '',
          lastName: firebaseUser.displayName?.split(' ').skip(1).join(' ') ?? '',
          role: 'FARMER',
        );
      }
    } catch (e) {
      // Fallback to Firebase user data
      _user = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        firstName: firebaseUser.displayName?.split(' ').first ?? '',
        lastName: firebaseUser.displayName?.split(' ').skip(1).join(' ') ?? '',
        role: 'FARMER',
      );
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // Email/Password Sign Up
  Future<bool> signUp(String email, String password, String firstName, String lastName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signUp(email, password, firstName, lastName);
      if (result != null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await _loadUserData(currentUser);
        } else {
          _user = result;
        }
        return true;
      }
      _errorMessage = 'Sign up failed';
      return false;
    } catch (e) {
      _errorMessage = UserErrorMessage.fromException(e, fallback: 'Sign up failed. Please try again.');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Email/Password Sign In
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signIn(email, password);
      if (result != null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await _loadUserData(currentUser);
        } else {
          _user = result;
        }
        return true;
      }
      _errorMessage = 'Sign in failed';
      return false;
    } catch (e) {
      _errorMessage = UserErrorMessage.fromException(e, fallback: 'Sign in failed. Please try again.');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await _loadUserData(currentUser);
        } else {
          _user = result;
        }
        return true;
      }

      if (kIsWeb) {
        // Redirect-based Google sign-in continues after a full-page round trip.
        _errorMessage = null;
        return true;
      }

      _errorMessage = 'Google sign in failed';
      return false;
    } catch (e) {
      if (e.toString().contains('REDIRECT_IN_PROGRESS')) {
        _errorMessage = null;
        return true;
      }
      _errorMessage = UserErrorMessage.fromException(e, fallback: 'Google sign in failed. Please try again.');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Phone Sign In - Send Code
  Future<bool> signInWithPhone(String phoneNumber) async {
    final verificationId = await requestPhoneVerificationCode(phoneNumber);
    return verificationId != null && verificationId.isNotEmpty;
  }

  // Phone Sign In - request verification ID for OTP flow
  Future<String?> requestPhoneVerificationCode(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final verificationId = await _authService.signInWithPhoneSendCode(phoneNumber);
      return verificationId;
    } catch (e) {
      _errorMessage = UserErrorMessage.fromException(e, fallback: 'Unable to send verification code. Please try again.');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Phone Sign In - Verify Code
  Future<bool> verifyPhoneCode(String verificationId, String smsCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.verifyPhoneCode(verificationId, smsCode);
      if (result != null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await _loadUserData(currentUser);
        } else {
          _user = result;
        }
        return true;
      }
      _errorMessage = 'Phone verification failed';
      return false;
    } catch (e) {
      _errorMessage = UserErrorMessage.fromException(e, fallback: 'Phone verification failed. Please try again.');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithPhonePassword(String phoneNumber, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signInWithPhonePassword(phoneNumber, password);
      if (result != null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await _loadUserData(currentUser);
        } else {
          _user = result;
        }
        return true;
      }
      _errorMessage = 'Phone sign in failed';
      return false;
    } catch (e) {
      _errorMessage = UserErrorMessage.fromException(
        e,
        fallback: 'Phone sign in failed. Please try again.',
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> completePhoneSignUp({
    required String phoneNumber,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.completePhoneSignUp(
        phoneNumber: phoneNumber,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      if (result != null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await _loadUserData(currentUser);
        } else {
          _user = result;
        }
        return true;
      }

      _errorMessage = 'Phone sign up failed';
      return false;
    } catch (e) {
      _errorMessage = UserErrorMessage.fromException(
        e,
        fallback: 'Phone sign up failed. Please try again.',
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign Out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Sign out failed';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> sendEmailVerification() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        _errorMessage = 'No authenticated user found';
        notifyListeners();
        return false;
      }

      await firebaseUser.sendEmailVerification();
      return true;
    } catch (e) {
      _errorMessage = UserErrorMessage.fromException(e, fallback: 'Unable to send verification email. Please try again.');
      notifyListeners();
      return false;
    }
  }

  Future<bool> reloadAndCheckVerification() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;

      await firebaseUser.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser == null) return false;

      await _loadUserData(refreshedUser);
      notifyListeners();
      return !requiresEmailVerification;
    } catch (e) {
      _errorMessage = UserErrorMessage.fromException(e, fallback: 'Unable to verify your email status right now. Please try again.');
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = UserErrorMessage.fromException(
        e,
        fallback: 'Unable to send password reset email. Please try again.',
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmPasswordReset(String code, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.confirmPasswordReset(code, newPassword);
      return true;
    } catch (e) {
      _errorMessage = UserErrorMessage.fromException(
        e,
        fallback: 'Unable to reset password. Please try again.',
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
