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
    final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          elevation: 0,
          backgroundColor: const Color(0xFF0F172A),
          selectedItemColor: const Color(0xFF3B82F6),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map_rounded), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.trending_up_outlined), activeIcon: Icon(Icons.trending_up_rounded), label: 'Trends'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment_rounded), label: 'Reports'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
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

class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.userModel?.role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background subtle glows
          Positioned(
            top: 100,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Avatar Section
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF1E293B),
                        child: Text(
                          (authProvider.userModel?.name ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF60A5FA)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    authProvider.userModel?.name ?? 'User',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authProvider.userModel?.email ?? '',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  
                  // Info Cards
                  _buildProfileCard(
                    icon: Icons.location_city_rounded,
                    title: 'City',
                    value: authProvider.userModel?.city ?? 'Not specified',
                  ),
                  const SizedBox(height: 16),
                  
                  if (isAdmin) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                        icon: const Icon(Icons.admin_panel_settings_rounded),
                        label: const Text('ADMIN PANEL'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: const Color(0xFF60A5FA),
                          side: BorderSide(color: const Color(0xFF60A5FA).withOpacity(0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () async {
                        await authProvider.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthWrapper()),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      label: const Text('LOGOUT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.redAccent.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF60A5FA), size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
