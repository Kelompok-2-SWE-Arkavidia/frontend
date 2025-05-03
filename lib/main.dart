import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_navigation.dart';
import 'pages/home_screen.dart';
import 'pages/stock_screen.dart';
import 'pages/recipes_page.dart';
import 'pages/recipes_screen.dart';
import 'pages/donate_page.dart';
import 'pages/donate_screen.dart';
import 'pages/barter_page.dart';
import 'pages/onboarding_screen.dart';
import 'pages/register_screen.dart';
import 'pages/login_screen.dart';
import 'pages/email_verification_screen.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'providers/auth_provider.dart';
import 'providers/app_state_provider.dart';
import 'services/auth_handler_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service (which initializes notification service internally)
  await BackgroundService.instance.initialize();

  // Request notification permissions
  await NotificationService.instance.requestPermissions();

  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id', null);

  // For first-time app install, ensure onboarding is shown
  final prefs = await SharedPreferences.getInstance();
  final bool keyExists = prefs.containsKey('has_shown_onboarding');
  if (!keyExists) {
    debugPrint(
      '🆕 First app install detected: Ensuring onboarding will be shown',
    );
    await prefs.setBool('has_shown_onboarding', false);
  }

  // Create a ProviderContainer to allow initialization before runApp
  final container = ProviderContainer();

  // Initialize AuthHandlerService
  container.read(authHandlerServiceProvider).initialize(container);

  runApp(
    // Use the existing ProviderContainer
    ProviderScope(parent: container, child: const MyApp()),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp>
    with SingleTickerProviderStateMixin {
  // Whether app initialization is complete
  bool _initialized = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Inisialisasi animasi pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animasi berulang
    _pulseController.repeat(reverse: true);

    // Initialize app and check authentication
    _initializeApp();

    // Setup a manual deep link handler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // We can add deep link handling here when we have a solution that works
      debugPrint('🔗 Deep link handling would be setup here');
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Allow some time for native splash to be displayed and services to initialize
    await Future.delayed(const Duration(seconds: 1));

    // IMPORTANT: First check if this is a first-time install
    final prefs = await SharedPreferences.getInstance();
    final bool keyExists = prefs.containsKey('has_shown_onboarding');

    if (!keyExists) {
      debugPrint('🔴 First app launch detected - Forcing onboarding');
      // Explicitly set onboarding to false for first-time installs
      await prefs.setBool('has_shown_onboarding', false);

      // Explicitly update the app state notifier
      final appStateNotifier = ref.read(appStateProvider.notifier);
      if (appStateNotifier is AppStateNotifier) {
        await appStateNotifier.forceResetOnboardingStatus();
      }
    }

    // Now that onboarding is set, continue loading other states
    // Ensure onboarding status is properly loaded first
    final appStateNotifier =
        ref.read(appStateProvider.notifier) as AppStateNotifier;
    await appStateNotifier.refreshOnboardingStatus();

    // Then check authentication status
    final authNotifier = ref.read(authProvider.notifier);
    if (authNotifier is AuthNotifier) {
      // Force a check of existing auth data
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Debug values
    final hasShownOnboarding = ref.read(hasShownOnboardingProvider);
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    debugPrint('🔄 App initialization complete:');
    debugPrint('   - hasShownOnboarding: $hasShownOnboarding');
    debugPrint('   - isAuthenticated: $isAuthenticated');

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state to react to changes
    final authState = ref.watch(authProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    // Watch onboarding state to determine initial route
    final hasShownOnboarding = ref.watch(hasShownOnboardingProvider);

    // Get auth handler service for its navigatorKey
    final authHandlerService = ref.watch(authHandlerServiceProvider);

    // Debug initial state
    debugPrint(
      '📱 Initial app state: hasShownOnboarding=$hasShownOnboarding, isAuthenticated=$isAuthenticated',
    );

    // If not initialized, show a loading indicator with animation
    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo dengan animasi pulse
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/images/foodia-logo.png',
                      width: 180,
                      height: 180,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Animasi loading dengan warna tema aplikasi
                  const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                      strokeWidth: 4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Teks loading dengan animasi fade
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.6, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeIn,
                    builder: (context, value, child) {
                      return Opacity(opacity: value, child: child);
                    },
                    child: const Text(
                      'Memuat Aplikasi...',
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Teks tambahan
                  const Text(
                    'Siap mengelola makanan Anda dengan cerdas',
                    style: TextStyle(
                      color: AppTheme.textLightColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // IMPORTANT: Determine initial route based on app state - ALWAYS check onboarding first
    String initialRoute;
    Widget? initialHome;

    // Force check hasShownOnboarding again from provider to ensure latest value
    final forcedOnboardingCheck = ref.read(hasShownOnboardingProvider);
    debugPrint(
      '🔍 Forced onboarding check before navigation: $forcedOnboardingCheck',
    );

    // First priority: check if user needs to see onboarding
    if (!forcedOnboardingCheck) {
      // If user has never seen onboarding, show it first - HIGHEST PRIORITY
      initialRoute = '/onboarding';
      initialHome = const OnboardingScreen();
      debugPrint('🎬 SHOWING ONBOARDING: User has not completed onboarding');
    }
    // Second priority: check if user is authenticated
    else if (isAuthenticated) {
      // If user has seen onboarding and is authenticated
      initialRoute = '/home';
      initialHome = const MainScreen();
      debugPrint(
        '🎬 SHOWING MAIN: User completed onboarding and is authenticated',
      );
    }
    // Last option: show login
    else {
      // If user has seen onboarding but is not authenticated
      initialRoute = '/login';
      initialHome = const LoginScreen();
      debugPrint(
        '🎬 SHOWING LOGIN: User completed onboarding but is not authenticated',
      );
    }

    debugPrint(
      '🚀 App initializing with route: $initialRoute (Authenticated: $isAuthenticated, HasShownOnboarding: $forcedOnboardingCheck)',
    );

    // Return the MaterialApp directly instead of wrapping it in TestButtonWrapper
    return MaterialApp(
      title: 'Foodia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Use the global navigator key from AuthHandlerService
      navigatorKey: authHandlerService.navigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Indonesian
        Locale('en', 'US'), // English
      ],
      // Use home with the determined initial screen
      home: initialHome,
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainScreen(),
        '/recipes': (context) => const RecipesScreen(),
        '/donate': (context) => const DonateScreen(),
        '/barter': (context) => const BarterPage(),
        '/email-verification': (context) => const EmailVerificationScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Screen options for navigation
  final List<Widget> _screens = const [
    HomeScreen(), // 0
    StockScreen(), // 1
    RecipesScreen(), // 2
    DonateScreen(), // 3
    BarterPage(), // 4
  ];

  @override
  void initState() {
    super.initState();
    // We need to use a post-frame callback to access route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null &&
          args is Map<String, dynamic> &&
          args.containsKey('tabIndex')) {
        setState(() {
          _currentIndex = args['tabIndex'];
        });
        debugPrint('🧭 Setting active tab to index: ${args['tabIndex']}');
      }
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Adjusted to handle the new navigation layout
    Widget currentScreen = _screens[_currentIndex];

    return Scaffold(
      body: currentScreen,
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
      // Important for transparent notch
      extendBody: true,
      // Don't add a floating action button here - let each screen handle its own FAB
    );
  }
}

// Add a placeholder ProfileScreen class
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        elevation: 0.5,
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://picsum.photos/200'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pengguna Foodia',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'pengguna@example.com',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildProfileMenuButton(
              icon: Icons.settings,
              title: 'Pengaturan',
              onTap: () {},
            ),
            _buildProfileMenuButton(
              icon: Icons.history,
              title: 'Riwayat Aktivitas',
              onTap: () {},
            ),
            _buildProfileMenuButton(
              icon: Icons.help_outline,
              title: 'Bantuan',
              onTap: () {},
            ),
            _buildProfileMenuButton(
              icon: Icons.logout,
              title: 'Keluar',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF22C55E)),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
