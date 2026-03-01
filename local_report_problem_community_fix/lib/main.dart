import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/problem_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/top_issues/top_issues_screen.dart';
import 'screens/my_reports/my_reports_screen.dart';
import 'screens/report/report_issue_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'dart:ui';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'screens/profile/profile_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("LPRCF: Starting Firebase Initialization...");
  
  bool initialized = false;
  String? error;

  try {
    // Check if already initialized (can happen in certain scenarios or with certain plugins)
    if (Firebase.apps.isEmpty) {
      print("LPRCF: No existing apps found, initializing [DEFAULT]...");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      print("LPRCF: Firebase already initialized with ${Firebase.apps.length} apps.");
    }
    initialized = true;
    print("LPRCF: Firebase Initialized Successfully.");
  } catch (e) {
    error = e.toString();
    print("LPRCF: Firebase Initialization Error: $e");
    
    // Attempt fallback initialization without options if on Android/iOS
    try {
      if (Firebase.apps.isEmpty) {
         print("LPRCF: Attempting fallback initialization...");
         await Firebase.initializeApp();
         initialized = true;
         print("LPRCF: Fallback Initialization Successful.");
      }
    } catch (e2) {
      print("LPRCF: Fallback Initialization also failed: $e2");
    }
  }
  
  runApp(
    initialized 
    ? const LPRCFApp()
    : MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text("Firebase Setup Error", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(error ?? "Unknown Error", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 24),
                  const Text("Please ensure you have re-run 'flutter pub get' and performed a FULL RESTART of the app.", textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      )
  );
}

class LPRCFApp extends StatelessWidget {
  const LPRCFApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProblemProvider()),
      ],
      child: MaterialApp(
        title: 'LPRCF - Civic Reporter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (authProvider.isAuthenticated) {
      if (authProvider.userModel?.isBanned ?? false) {
        return const BannedScreen();
      }
      return const MainNavigation();
    } else {
      return const LoginScreen();
    }
  }
}

class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block_rounded, color: Colors.redAccent, size: 80),
              const SizedBox(height: 24),
              const Text(
                'ACCOUNT SUSPENDED',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              Text(
                'Your account has been banned for violating community guidelines. If you believe this is a mistake, please contact support.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.5), height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Provider.of<AuthProvider>(context, listen: false).signOut(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MapScreen(),
    const TopIssuesScreen(),
    const MyReportsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 65,
        items: const [
          Icon(Icons.map_rounded, size: 26, color: Colors.white),
          Icon(Icons.trending_up_rounded, size: 26, color: Colors.white),
          Icon(Icons.assignment_rounded, size: 26, color: Colors.white),
          Icon(Icons.person_rounded, size: 26, color: Colors.white),
        ],
        color: const Color(0xFF1E293B),
        buttonBackgroundColor: const Color(0xFF3B82F6),
        backgroundColor: const Color(0xFF0F172A),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 400),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        letIndexChange: (index) => true,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85),
        child: FloatingActionButton(
          heroTag: 'main_add_report_fab',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
            );
          },
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      ),
    );
  }
}

