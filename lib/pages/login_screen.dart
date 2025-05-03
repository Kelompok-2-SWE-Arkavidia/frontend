import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/login_form_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize email and password from providers if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emailControllerProvider.notifier).state = '';
      ref.read(passwordControllerProvider.notifier).state = '';
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Masukkan email yang valid';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Kata sandi minimal 6 karakter';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    // Close keyboard before validation
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      // Set loading state using the provider
      ref.read(loginFormProvider.notifier).setLoading(true);

      try {
        final email = ref.read(emailControllerProvider);
        final password = ref.read(passwordControllerProvider);

        // Clear any existing snackbars before login attempt
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        final success = await ref
            .read(authProvider.notifier)
            .login(email: email, password: password);

        if (success && mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Login berhasil! Mengalihkan ke beranda...'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to home screen with bottom navigation
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              // Use pushNamedAndRemoveUntil to clear the navigation stack
              // and ensure we're starting fresh with the MainScreen
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false, // Remove all previous routes
              );
            }
          });
        } else if (mounted) {
          // Login failed, get error message from provider
          final authState = ref.read(authProvider);
          if (authState.errorMessage != null) {
            // Use error dialog for all authentication errors
            _showErrorDialog(authState.errorMessage!);
          }
        }
      } catch (e) {
        // Show error dialog for unexpected exceptions too
        _showErrorDialog('Terjadi kesalahan saat login. Silakan coba lagi.');
      } finally {
        // Reset loading state using the provider
        ref.read(loginFormProvider.notifier).setLoading(false);
      }
    } else {
      // Form validation failed
      _showErrorDialog('Silakan lengkapi form dengan benar');
    }
  }

  // Show error dialog for authentication errors
  void _showErrorDialog(String message) {
    // Format the error message to be more user-friendly
    String userFriendlyMessage = message;

    // Check for common API error messages and replace with user-friendly ones
    if (message.contains('Unauthorized') ||
        message.contains('401') ||
        message.contains('Failed to process request')) {
      userFriendlyMessage =
          'Email atau kata sandi salah. Silakan periksa dan coba lagi.';
    } else if (message.contains('Network') ||
        message.contains('Socket') ||
        message.contains('Connection')) {
      userFriendlyMessage =
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    } else if (message.contains('Server') || message.contains('500')) {
      userFriendlyMessage =
          'Terjadi masalah pada server. Silakan coba lagi nanti.';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: Colors.red.shade100, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Login Gagal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userFriendlyMessage,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pastikan email dan kata sandi Anda benar. Jika masalah berlanjut, silakan hubungi dukungan pelanggan kami.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Coba Lagi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen(authProvider, (previous, next) {
      if (next.state == AuthState.error && next.errorMessage != null) {
        // Show dialog for all authentication errors
        _showErrorDialog(next.errorMessage!);
      }
    });

    // Get login form state from provider
    final formState = ref.watch(loginFormProvider);
    final email = ref.watch(emailControllerProvider);
    final password = ref.watch(passwordControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Navigate back to onboarding screen
            Navigator.of(context).pushReplacementNamed('/onboarding');
          },
        ),
        title: const Text(''),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    children: [
                      TextSpan(text: 'Selamat Datang Kembali'),
                      TextSpan(text: '👋', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Yuk, masuk ke akunmu!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // Email field
                const Text(
                  'Email',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: email,
                  onChanged:
                      (value) =>
                          ref.read(emailControllerProvider.notifier).state =
                              value,
                  decoration: InputDecoration(
                    hintText: 'Email anda',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 20),

                // Password field
                const Text(
                  'Kata Sandi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: password,
                  onChanged:
                      (value) =>
                          ref.read(passwordControllerProvider.notifier).state =
                              value,
                  decoration: InputDecoration(
                    hintText: 'Kata sandi anda',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  obscureText: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),

                // Forgot password option
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Handle forgot password
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Lupa Kata Sandi?',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Login Button
                ElevatedButton(
                  onPressed: formState.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child:
                      formState.isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text('Masuk'),
                ),
                const SizedBox(height: 20),

                // Register Option
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to register screen
                          Navigator.of(
                            context,
                          ).pushReplacementNamed('/register');
                        },
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
