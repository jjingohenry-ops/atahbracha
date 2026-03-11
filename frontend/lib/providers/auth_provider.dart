import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../core/utils/app_logger.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() async {
    try {
      // Check if user is already signed in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _loadUserData(currentUser);
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize authentication';
      debugPrint('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      if (userData != null) {
        _user = userData;
      } else {
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

  // Email/Password Sign Up
  Future<bool> signUp(String email, String password, String firstName, String lastName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signUp(email, password, firstName, lastName);
      if (result != null) {
        _user = result;
        return true;
      }
      _errorMessage = 'Sign up failed';
      return false;
    } catch (e) {
      _errorMessage = e.toString();
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
        _user = result;
        return true;
      }
      _errorMessage = 'Sign in failed';
      return false;
    } catch (e) {
      _errorMessage = e.toString();
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
        _user = result;
        return true;
      }
      _errorMessage = 'Google sign in failed';
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Phone Sign In - Send Code
  Future<bool> signInWithPhone(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signInWithPhoneSendCode(phoneNumber);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
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
        _user = result;
        return true;
      }
      _errorMessage = 'Phone verification failed';
      return false;
    } catch (e) {
      _errorMessage = e.toString();
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
}
