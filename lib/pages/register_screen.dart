import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/register_form_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Focus nodes untuk setiap field
  late FocusNode _nameFocusNode;
  late FocusNode _usernameFocusNode;
  late FocusNode _emailFocusNode;
  late FocusNode _passwordFocusNode;
  late FocusNode _contactFocusNode;
  late FocusNode _locationFocusNode;

  // GlobalKey untuk form
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Inisialisasi focus nodes
    _nameFocusNode = FocusNode();
    _usernameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _contactFocusNode = FocusNode();
    _locationFocusNode = FocusNode();

    // Tambahkan listener untuk mencegah keyboard tertutup
    _addFocusListeners();
  }

  void _addFocusListeners() {
    _nameFocusNode.addListener(() => _onFocusChange(_nameFocusNode));
    _usernameFocusNode.addListener(() => _onFocusChange(_usernameFocusNode));
    _emailFocusNode.addListener(() => _onFocusChange(_emailFocusNode));
    _passwordFocusNode.addListener(() => _onFocusChange(_passwordFocusNode));
    _contactFocusNode.addListener(() => _onFocusChange(_contactFocusNode));
    _locationFocusNode.addListener(() => _onFocusChange(_locationFocusNode));
  }

  void _onFocusChange(FocusNode focusNode) {
    if (focusNode.hasFocus) {
      // Pastikan keyboard tetap terbuka
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(focusNode);
      });
    }
  }

  @override
  void dispose() {
    // Pastikan untuk melepaskan focus nodes
    _nameFocusNode.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _contactFocusNode.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  // Show error dialog with improved UI
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text(
                  'Registrasi Gagal',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: TextStyle(fontSize: 14)),
                SizedBox(height: 16),
                Text(
                  'Silakan coba lagi atau hubungi dukungan jika masalah berlanjut.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Mengerti',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }

  // Show error snackbar for less critical errors
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(message, style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Tutup',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Handle registration
  Future<void> _register(BuildContext context, WidgetRef ref) async {
    // Tutup keyboard sebelum validasi
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      // Set loading state
      ref.read(registerFormProvider.notifier).setLoading(true);

      try {
        final name = ref.read(nameControllerProvider);
        final username = ref.read(usernameControllerProvider);
        final email = ref.read(emailControllerProvider);
        final password = ref.read(passwordControllerProvider);
        final contact = ref.read(contactControllerProvider);
        final location = ref.read(locationControllerProvider);

        final success = await ref
            .read(authProvider.notifier)
            .register(
              email: email,
              username: username,
              name: name,
              password: password,
              contact: contact,
              location: location,
            );

        if (success) {
          // Registration successful - navigate to home screen
          if (context.mounted) {
            // Show success snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Registrasi berhasil! Mengalihkan ke beranda...'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // Delay navigation slightly to show the success message
            Future.delayed(Duration(milliseconds: 1500), () {
              if (context.mounted) {
                // Use named route navigation and clear all previous routes
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home',
                  (route) => false, // Remove all previous routes
                );
              }
            });
          }
        } else {
          // Get error message from provider
          final authState = ref.read(authProvider);
          if (context.mounted && authState.errorMessage != null) {
            // For server errors or network issues, show dialog
            _showErrorDialog(context, authState.errorMessage!);
          }
        }
      } catch (e) {
        if (context.mounted) {
          // For unexpected errors, show snackbar
          _showErrorSnackbar(
            context,
            'Terjadi kesalahan saat mendaftar. Silakan coba lagi.',
          );
        }
      } finally {
        // Reset loading state
        ref.read(registerFormProvider.notifier).setLoading(false);
      }
    } else {
      // Form validation failed
      if (context.mounted) {
        _showErrorSnackbar(context, 'Harap lengkapi semua kolom dengan benar');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes
    ref.listen(authProvider, (previous, next) {
      if (next.state == AuthState.error && next.errorMessage != null) {
        // Set error in form state
        ref.read(registerFormProvider.notifier).setFormError(next.errorMessage);

        // Determine if it's a critical error that needs a dialog
        final errorMessage = next.errorMessage!;
        if (errorMessage.contains('already exists') ||
            errorMessage.contains('invalid') ||
            errorMessage.contains('terdaftar')) {
          // Server validation errors - show dialog
          _showErrorDialog(context, errorMessage);
        } else if (!errorMessage.contains('complete') &&
            !errorMessage.contains('lengkapi')) {
          // Other errors but not form validation - show snackbar
          _showErrorSnackbar(context, errorMessage);
        }
      } else if (next.state == AuthState.success) {
        // Registration successful
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Registrasi berhasil!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    // Get form state
    final formState = ref.watch(registerFormProvider);

    return GestureDetector(
      // Cegah keyboard tertutup saat tap di luar field
      onTap: () {
        // Nonaktifkan fokus tanpa menutup keyboard secara paksa
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed:
                () => Navigator.of(context).pushReplacementNamed('/onboarding'),
          ),
          title: const Text(
            'daftar akun',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Daftar',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Buat akunmu dan mulai ubah kebiasaan!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // Name Field
                  const Text(
                    'Nama',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    focusNode: _nameFocusNode,
                    initialValue: ref.watch(nameControllerProvider),
                    onChanged:
                        (value) =>
                            ref.read(nameControllerProvider.notifier).state =
                                value,
                    decoration: InputDecoration(
                      hintText: 'Nama lengkap anda',
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
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_usernameFocusNode);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Username Field
                  const Text(
                    'Username',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    focusNode: _usernameFocusNode,
                    initialValue: ref.watch(usernameControllerProvider),
                    onChanged:
                        (value) =>
                            ref
                                .read(usernameControllerProvider.notifier)
                                .state = value,
                    decoration: InputDecoration(
                      hintText: 'Username anda',
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
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_emailFocusNode);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  const Text(
                    'Email',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    focusNode: _emailFocusNode,
                    initialValue: ref.watch(emailControllerProvider),
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
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  const Text(
                    'Kata Sandi',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    focusNode: _passwordFocusNode,
                    initialValue: ref.watch(passwordControllerProvider),
                    onChanged:
                        (value) =>
                            ref
                                .read(passwordControllerProvider.notifier)
                                .state = value,
                    obscureText: !formState.isPasswordVisible,
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          formState.isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey,
                        ),
                        onPressed:
                            () =>
                                ref
                                    .read(registerFormProvider.notifier)
                                    .togglePasswordVisibility(),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_contactFocusNode);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kata sandi tidak boleh kosong';
                      }
                      if (value.length < 6) {
                        return 'Kata sandi minimal 6 karakter';
                      }
                      // Check for at least one uppercase letter and one number
                      if (!RegExp(
                        r'^(?=.*?[A-Z])(?=.*?[0-9])',
                      ).hasMatch(value)) {
                        return 'Kata sandi harus memiliki minimal 1 huruf kapital dan 1 angka';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Contact Field
                  const Text(
                    'Nomor Telepon',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    focusNode: _contactFocusNode,
                    initialValue: ref.watch(contactControllerProvider),
                    onChanged:
                        (value) =>
                            ref.read(contactControllerProvider.notifier).state =
                                value,
                    decoration: InputDecoration(
                      hintText: 'Nomor telepon anda (e.g. +628123456789)',
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
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_locationFocusNode);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nomor telepon tidak boleh kosong';
                      }
                      if (!value.startsWith('+')) {
                        return 'Nomor telepon harus dimulai dengan kode negara (e.g. +62)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Location Field
                  const Text(
                    'Lokasi',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    focusNode: _locationFocusNode,
                    initialValue: ref.watch(locationControllerProvider),
                    onChanged:
                        (value) =>
                            ref
                                .read(locationControllerProvider.notifier)
                                .state = value,
                    decoration: InputDecoration(
                      hintText: 'Lokasi anda (e.g. Jakarta, Indonesia)',
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
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      // Terakhir, tutup keyboard dan jalankan registrasi
                      FocusScope.of(context).unfocus();
                      _register(context, ref);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lokasi tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Register Button
                  ElevatedButton(
                    onPressed:
                        formState.isLoading
                            ? null
                            : () {
                              // Tutup keyboard sebelum registrasi
                              FocusScope.of(context).unfocus();
                              _register(context, ref);
                            },
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
                            : const Text('Daftar'),
                  ),
                  const SizedBox(height: 20),

                  // Login Option
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to login screen
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Terms and conditions
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        children: [
                          const TextSpan(
                            text:
                                'Dengan mengklik Daftar, Anda setuju dengan ketentuan kami\n',
                          ),
                          TextSpan(
                            text: 'Syarat',
                            style: TextStyle(color: Colors.green),
                          ),
                          const TextSpan(text: ' dan '),
                          TextSpan(
                            text: 'Kebijakan Data',
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
