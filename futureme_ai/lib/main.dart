import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/simulation_provider.dart';
import 'utils/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? initError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    initError = e.toString();
    print('Firebase initialization error: $e');
  }
  runApp(FutureMeApp(initError: initError));
}

class FutureMeApp extends StatelessWidget {
  final String? initError;
  const FutureMeApp({super.key, this.initError});

  @override
  Widget build(BuildContext context) {
    if (initError != null) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                  const SizedBox(height: 24),
                  const Text('FIREBASE INITIALIZATION FAILED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  Text(
                    'Please ensure your google-services.json (Android) or GoogleService-Info.plist (iOS) is correctly placed in the project folders.\n\nError: $initError',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SimulationProvider()),
      ],
      child: MaterialApp(
        title: 'FutureMe AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon)),
      );
    }
    
    if (userProvider.userModel == null) {
      return const LoginScreen();
    } else {
      // Initialize shared data for the user
      Provider.of<SimulationProvider>(context, listen: false)
          .loadUserData(userProvider.userModel!.userId);
      return const DashboardScreen();
    }
  }
}
