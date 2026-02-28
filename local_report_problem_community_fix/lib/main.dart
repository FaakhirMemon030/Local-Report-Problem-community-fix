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
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
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
      return const MainNavigation();
    } else {
      return const LoginScreen();
    }
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
    const ProfilePlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up_outlined), activeIcon: Icon(Icons.trending_up), label: 'Top'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'My Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
          );
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.userModel?.role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            Text(authProvider.userModel?.name ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(authProvider.userModel?.email ?? '', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            if (isAdmin)
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 32),
                 child: ElevatedButton.icon(
                   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                   icon: const Icon(Icons.admin_panel_settings),
                   label: const Text('Admin Panel'),
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                 ),
               ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: () => authProvider.signOut(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
