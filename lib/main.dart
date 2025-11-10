import 'package:flutter/material.dart';
import 'package:fretfly/login_page.dart';
import 'package:fretfly/signup_page.dart';
import 'package:fretfly/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fretfly/ui/app_theme.dart';
import 'package:fretfly/services/theme_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp(
            title: 'Fretfly',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeService.themeMode,
            home: const AuthGate(),
            routes: {
              SignUpPage.routeName: (context) => const SignUpPage(),
              HomePage.routeName: (context) => const HomePage(),
            },
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) return const LoginPage();
        return const HomePage();
      },
    );
  }
}
