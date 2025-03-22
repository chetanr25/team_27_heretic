import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:med_info/screens/access_denied.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'screens/challenge_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final bool isLoggedIn = await AuthService().isLoggedIn();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Med Info',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // If user is logged in, show scanner screen, otherwise show signup screen
      home: isLoggedIn ? const MainScreen() : const SignupScreen(),
      // home: const AccessDeniedScreen(
      //   message: 'Access Denied',
      //   details: {
      //     'message': 'You do not have permission to access this page.',
      //     'role': 'patient',
      //     'userId': '100',
      //   },
      // ),
      routes: {
        '/scanner': (context) => const QRScannerScreen(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/access-denied':
            (context) => const AccessDeniedScreen(
              message: 'Access Denied',
              details: {
                'message': 'You do not have permission to access this page.',
              },
            ),
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
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const QRScannerScreen(),
    const ChallengeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events),
            label: 'Challenge',
          ),
        ],
      ),
    );
  }
}
