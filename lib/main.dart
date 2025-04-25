import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bottom_navigation.dart';
import 'pages/home_screen.dart';
import 'pages/stock_page.dart';
import 'pages/recipes_page.dart';
import 'pages/donate_page.dart';
import 'pages/barter_page.dart';
import 'pages/onboarding_screen.dart';
import 'pages/register_screen.dart';
import 'pages/login_screen.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service (which initializes notification service internally)
  await BackgroundService.instance.initialize();

  // Request notification permissions
  await NotificationService.instance.requestPermissions();

  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id', null);

  runApp(
    // Wrap the app with ProviderScope to enable Riverpod
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  // Track splash screen state
  bool _showingSplash = true;

  @override
  void initState() {
    super.initState();
    // Show splash for a minimum time then check authentication
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Show splash screen for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _showingSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state to react to changes
    final authState = ref.watch(authProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    // Determine initial route based on auth status
    final String initialRoute =
        _showingSplash
            ? '/'
            : isAuthenticated
            ? '/home'
            : '/onboarding';

    debugPrint(
      '🚀 App initializing with route: $initialRoute (Authenticated: $isAuthenticated)',
    );

    return MaterialApp(
      title: 'Foodia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Indonesian
        Locale('en', 'US'), // English
      ],
      // Use home instead of initialRoute with a conditional to handle splash screen
      home:
          _showingSplash
              ? _buildSplashScreen()
              : isAuthenticated
              ? const MainScreen()
              : const OnboardingScreen(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainScreen(),
        '/recipes': (context) => const RecipesPage(),
        '/donate': (context) => const DonatePage(),
        '/barter': (context) => const BarterPage(),
      },
    );
  }

  // Simple splash screen widget
  Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Foodia',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ],
        ),
      ),
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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          StockScreen(),
          RecipesPage(),
          DonatePage(),
          BarterPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
