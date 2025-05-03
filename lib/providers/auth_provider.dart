import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

// API service provider - a Provider that creates and provides an instance of ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Auth state enum to track authentication status
enum AuthState { initial, loading, success, error, pendingVerification }

// Auth state class to hold auth state and related data
class AuthStateData {
  final AuthState state;
  final String? errorMessage;
  final User? user;
  final Map<String, dynamic>? userData;
  final String? token;
  final bool isEmailVerified;
  final String? email;

  AuthStateData({
    required this.state,
    this.errorMessage,
    this.user,
    this.userData,
    this.token,
    this.isEmailVerified = false,
    this.email,
  });

  // Create a copy of AuthStateData with some fields modified
  AuthStateData copyWith({
    AuthState? state,
    String? errorMessage,
    User? user,
    Map<String, dynamic>? userData,
    String? token,
    bool? isEmailVerified,
    String? email,
  }) {
    return AuthStateData(
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
      userData: userData ?? this.userData,
      token: token ?? this.token,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      email: email ?? this.email,
    );
  }

  // Check if user is authenticated
  bool get isAuthenticated => token != null && token!.isNotEmpty;
}

// Auth state notifier - manages the auth state
class AuthNotifier extends StateNotifier<AuthStateData> {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthNotifier(this._apiService, this._storageService)
    : super(AuthStateData(state: AuthState.initial)) {
    // Check if user is already logged in when initialized
    _checkExistingAuth();
  }

  // Private method to check if user already has a token
  Future<void> _checkExistingAuth() async {
    debugPrint('🔍 Checking for existing authentication...');

    try {
      final token = await _storageService.getToken();
      final userData = await _storageService.getUserData();

      if (token != null &&
          token.isNotEmpty &&
          userData != null &&
          userData.isNotEmpty) {
        debugPrint(
          '✅ Found existing token: ${token.substring(0, min(15, token.length))}...',
        );
        debugPrint('👤 Found existing user data: $userData');

        // Restore authentication state
        state = AuthStateData(
          state: AuthState.success,
          token: token,
          userData: userData,
          isEmailVerified: true, // Assume verified since we had a stored token
        );

        debugPrint('🔐 User session restored - user is authenticated');
      } else {
        debugPrint(
          '❌ No valid authentication found - user is new or logged out',
        );

        // Ensure a clean state for new installs or logged out users
        state = AuthStateData(
          state: AuthState.initial,
          token: null,
          userData: null,
          errorMessage: null,
          isEmailVerified: false,
        );

        // Make sure storage is clean for first-time installs, but don't reset onboarding state
        if (token == null || userData == null) {
          await _resetOnlyAuthData();
          debugPrint(
            '🧹 Cleaned auth data for first-time install while preserving onboarding state',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking authentication: $e');
      // Handle error during initialization
      state = AuthStateData(
        state: AuthState.initial,
        token: null,
        userData: null,
      );

      // Clear auth data only, preserving onboarding state
      await _resetOnlyAuthData();
    }
  }

  // Register a new user
  Future<bool> register({
    required String name,
    required String email,
    required String username,
    required String password,
    required String contact,
    required String location,
  }) async {
    // Update state to loading
    state = state.copyWith(state: AuthState.loading, errorMessage: null);

    try {
      // Create a new user
      final user = User(
        name: name,
        email: email,
        username: username,
        password: password,
        contact: contact,
        location: location,
      );

      // Call API to register user
      final result = await _apiService.registerUser(user);

      if (result['success']) {
        // Extract token and user data
        final userData = result['data'];
        final token = userData['token'];

        // Check if email verification is required (based on API response)
        final bool requiresVerification =
            userData['requiresEmailVerification'] ?? true;

        if (requiresVerification) {
          // Set state to pending verification
          state = state.copyWith(
            state: AuthState.pendingVerification,
            email: email,
            userData: userData,
            token: token,
            isEmailVerified: false,
          );

          debugPrint('🔐 User registered but email verification is required');
          return true;
        } else {
          // Registration successful and no verification required
          state = state.copyWith(
            state: AuthState.success,
            userData: userData,
            token: token,
            isEmailVerified: true,
          );

          // Persist authentication data
          await _persistAuthData(token, userData);

          debugPrint('🔐 User registered and authenticated');
          return true;
        }
      } else {
        // Registration failed
        state = state.copyWith(
          state: AuthState.error,
          errorMessage: result['message'],
        );
        return false;
      }
    } catch (e) {
      // Handle error
      state = state.copyWith(
        state: AuthState.error,
        errorMessage: 'Terjadi kesalahan saat mendaftar. Silakan coba lagi.',
      );
      return false;
    }
  }

  // Login user
  Future<bool> login({required String email, required String password}) async {
    // Update state to loading
    state = state.copyWith(state: AuthState.loading, errorMessage: null);
    debugPrint('🔄 Memulai proses login untuk email: $email');

    try {
      // Call API to login user
      final result = await _apiService.loginUser(
        email: email,
        password: password,
      );

      if (result['success']) {
        // Extract token from response data
        final tokenData = result['data'] as Map<String, dynamic>;
        final token = tokenData['token'] as String;

        // Create user data with role
        final userData = {'token': token, 'role': tokenData['role']};

        debugPrint(
          '✅ Login berhasil! Token diterima: ${token.substring(0, 15)}...',
        );
        debugPrint('👤 User role: ${tokenData['role']}');

        // Login successful
        state = state.copyWith(
          state: AuthState.success,
          userData: userData,
          token: token,
        );

        // Persist authentication data
        await _persistAuthData(token, userData);

        return true;
      } else {
        // Login failed
        debugPrint('❌ Login gagal: ${result['message']}');
        state = state.copyWith(
          state: AuthState.error,
          errorMessage: result['message'],
        );
        return false;
      }
    } catch (e) {
      // Handle error
      debugPrint('❌ Error saat login: $e');
      state = state.copyWith(
        state: AuthState.error,
        errorMessage: 'Terjadi kesalahan saat login. Silakan coba lagi.',
      );
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    debugPrint('🔄 Memulai proses logout');

    // Update state
    state = state.copyWith(
      state: AuthState.initial,
      userData: null,
      token: null,
      errorMessage: null,
    );

    // Clear stored auth data but preserve onboarding state
    await _resetOnlyAuthData();
    debugPrint(
      '✅ Logout berhasil. Token dan data pengguna dihapus tanpa mempengaruhi status onboarding',
    );
  }

  // Helper method to persist authentication data
  Future<void> _persistAuthData(
    String token,
    Map<String, dynamic> userData,
  ) async {
    debugPrint('💾 Menyimpan data autentikasi secara permanen');
    await _storageService.saveToken(token);
    await _storageService.saveUserData(userData);
    debugPrint('💾 Token dan data pengguna berhasil disimpan');
  }

  // Helper method to clear all authentication data
  Future<void> _clearAuthData() async {
    debugPrint('🧹 Menghapus semua data autentikasi');
    await _storageService.clearAuthData();
  }

  // Helper method to reset only auth data without affecting onboarding
  Future<void> _resetOnlyAuthData() async {
    debugPrint('🧹 Mereset data autentikasi tanpa menghapus status onboarding');
    await _storageService.resetOnlyAuthData();
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return state.isAuthenticated;
  }

  // Resend verification email
  Future<bool> resendVerificationEmail() async {
    if (state.email == null) {
      debugPrint('❌ No email available to resend verification');
      return false;
    }

    try {
      final result = await _apiService.resendVerificationEmail(state.email!);
      return result['success'];
    } catch (e) {
      debugPrint('❌ Error resending verification email: $e');
      return false;
    }
  }

  // Check email verification status
  Future<bool> checkEmailVerificationStatus() async {
    if (state.email == null) {
      debugPrint('❌ No email available to check verification status');
      return false;
    }

    try {
      final result = await _apiService.checkEmailVerificationStatus(
        state.email!,
      );

      if (result['success'] && result['isVerified'] == true) {
        // Email is verified, update state
        state = state.copyWith(state: AuthState.success, isEmailVerified: true);

        // If we have token and user data, persist it now
        if (state.token != null && state.userData != null) {
          await _persistAuthData(state.token!, state.userData!);
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking verification status: $e');
      return false;
    }
  }

  // Complete the verification process (called after user confirms they've verified)
  Future<bool> completeVerification() async {
    if (state.token == null || state.userData == null) {
      debugPrint('❌ No auth data available to complete verification');
      return false;
    }

    // Persist authentication data now that email is verified
    await _persistAuthData(state.token!, state.userData!);

    // Update state
    state = state.copyWith(state: AuthState.success, isEmailVerified: true);

    debugPrint('✅ Email verification completed, user is authenticated');
    return true;
  }

  // Verify email with token from deep link
  Future<bool> verifyEmailWithToken(String token) async {
    try {
      debugPrint('🔄 Verifying email with token: ${token.substring(0, 15)}...');

      // Call API to verify email with token
      final result = await _apiService.verifyEmailWithToken(token);

      if (result['success'] && result['isVerified'] == true) {
        final email = result['email'] as String;

        // Update state with verified email status
        state = state.copyWith(
          state: AuthState.success,
          isEmailVerified: true,
          email: email,
        );

        // If we have token and user data, persist it
        if (state.token != null && state.userData != null) {
          await _persistAuthData(state.token!, state.userData!);
        }

        debugPrint('✅ Email verified successfully with token');
        return true;
      }

      debugPrint('❌ Failed to verify email with token: ${result['message']}');
      return false;
    } catch (e) {
      debugPrint('❌ Error verifying email with token: $e');
      return false;
    }
  }
}

// Auth state provider - provides the current auth state
final authProvider = StateNotifierProvider<AuthNotifier, AuthStateData>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthNotifier(apiService, storageService);
});

// Convenience provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  final isAuth = authState.isAuthenticated;
  debugPrint(
    '🔒 isAuthenticatedProvider check: $isAuth (Token exists: ${authState.token != null})',
  );
  return isAuth;
});
