import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class AuthHandlerService {
  static final AuthHandlerService _instance = AuthHandlerService._internal();

  // Factory constructor
  factory AuthHandlerService() {
    return _instance;
  }

  // Private constructor
  AuthHandlerService._internal();

  // Global key for navigation without context
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Store the ProviderContainer for accessing providers
  late ProviderContainer _container;

  // Initialize with ProviderContainer (call this in main.dart)
  void initialize(ProviderContainer container) {
    _container = container;
  }

  // Handle unauthorized response (401)
  Future<void> handleUnauthorized(String message) async {
    debugPrint('🚨 AuthHandlerService: Handling unauthorized response');
    debugPrint('🚨 Message: $message');

    // Get auth provider and logout
    final authNotifier = _container.read(authProvider.notifier);
    await authNotifier.logout(); // This now preserves onboarding state

    // Only proceed if we have a valid context
    if (navigatorKey.currentContext != null) {
      // Check if we're already on the login screen
      final currentRoute =
          ModalRoute.of(navigatorKey.currentContext!)?.settings.name;
      final isOnLoginScreen = currentRoute == '/login';

      debugPrint(
        '🚨 Current route: $currentRoute, isOnLoginScreen: $isOnLoginScreen',
      );

      // Only show snackbar if NOT already on login screen
      if (!isOnLoginScreen) {
        final scaffoldMessenger = ScaffoldMessenger.of(
          navigatorKey.currentContext!,
        );
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Sesi habis. Silakan login kembali.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Navigate to login screen
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false, // Clear all routes
      );

      debugPrint('✅ User logged out and redirected to login screen');
    } else {
      debugPrint(
        '⚠️ No valid context available for handling unauthorized response',
      );
    }
  }
}

// Provider for AuthHandlerService
final authHandlerServiceProvider = Provider<AuthHandlerService>((ref) {
  return AuthHandlerService();
});
