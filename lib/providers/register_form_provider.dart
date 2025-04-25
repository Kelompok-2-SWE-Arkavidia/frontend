import 'package:flutter_riverpod/flutter_riverpod.dart';

// Form state class
class RegisterFormState {
  final bool isPasswordVisible;
  final bool isLoading;
  final String? formError;

  RegisterFormState({
    this.isPasswordVisible = false,
    this.isLoading = false,
    this.formError,
  });

  // Create a copy of RegisterFormState with some fields modified
  RegisterFormState copyWith({
    bool? isPasswordVisible,
    bool? isLoading,
    String? formError,
  }) {
    return RegisterFormState(
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isLoading: isLoading ?? this.isLoading,
      formError: formError,
    );
  }
}

// Form state notifier
class RegisterFormNotifier extends StateNotifier<RegisterFormState> {
  RegisterFormNotifier() : super(RegisterFormState());

  // Toggle password visibility
  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  // Set loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  // Set form error
  void setFormError(String? error) {
    state = state.copyWith(formError: error);
  }

  // Reset form state
  void resetForm() {
    state = RegisterFormState();
  }
}

// Form state provider
final registerFormProvider =
    StateNotifierProvider<RegisterFormNotifier, RegisterFormState>(
      (ref) => RegisterFormNotifier(),
    );

// Text field controllers providers
final nameControllerProvider = StateProvider<String>((ref) => '');
final usernameControllerProvider = StateProvider<String>((ref) => '');
final emailControllerProvider = StateProvider<String>((ref) => '');
final passwordControllerProvider = StateProvider<String>((ref) => '');
final contactControllerProvider = StateProvider<String>((ref) => '');
final locationControllerProvider = StateProvider<String>((ref) => '');
