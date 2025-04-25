import 'package:flutter_riverpod/flutter_riverpod.dart';

// Form state class
class LoginFormState {
  final bool isLoading;
  final String? formError;

  LoginFormState({this.isLoading = false, this.formError});

  // Create a copy of LoginFormState with some fields modified
  LoginFormState copyWith({bool? isLoading, String? formError}) {
    return LoginFormState(
      isLoading: isLoading ?? this.isLoading,
      formError: formError,
    );
  }
}

// Form state notifier
class LoginFormNotifier extends StateNotifier<LoginFormState> {
  LoginFormNotifier() : super(LoginFormState());

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
    state = LoginFormState();
  }
}

// Form state provider
final loginFormProvider =
    StateNotifierProvider<LoginFormNotifier, LoginFormState>(
      (ref) => LoginFormNotifier(),
    );

// Text field controllers providers
final emailControllerProvider = StateProvider<String>((ref) => '');
final passwordControllerProvider = StateProvider<String>((ref) => '');
