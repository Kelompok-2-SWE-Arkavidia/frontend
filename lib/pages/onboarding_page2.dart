import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';

class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Join us text
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'join us',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              // Logo
              Row(
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(text: 'f'),
                        TextSpan(
                          text: 'o',
                          style: TextStyle(color: Colors.green),
                        ),
                        TextSpan(
                          text: 'o',
                          style: TextStyle(color: Colors.green),
                        ),
                        TextSpan(text: 'dia'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              // Main Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Main heading with green text
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(text: 'Satu Langkah Kecil,\n'),
                        TextSpan(text: 'Kurangi Sampah'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Subheading
                  const Text(
                    'Ramah Lingkungan',
                    style: TextStyle(fontSize: 14, color: Colors.green),
                  ),
                ],
              ),
              const Spacer(),
              // Bottom buttons
              ElevatedButton(
                onPressed: () {
                  // Navigate to next page using PageController
                  final PageControllerState? pageController =
                      context.findAncestorStateOfType<PageControllerState>();
                  if (pageController != null) {
                    pageController.nextPage();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Selanjutnya'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  // Go to login screen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.grey, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Masuk',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
