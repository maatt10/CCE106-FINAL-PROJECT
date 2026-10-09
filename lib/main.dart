import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';
import 'widgets/splash_screen.dart';

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.instance.init();
}

void main() {
  runApp(const SubTrackApp());
}

class SubTrackApp extends StatefulWidget {
  const SubTrackApp({super.key});

  @override
  State<SubTrackApp> createState() => _SubTrackAppState();
}

class _SubTrackAppState extends State<SubTrackApp> {
  late final Future<void> _init;

  // ThemeService is created only after Firebase is ready.
  ThemeService? _themeService;

  @override
  void initState() {
    super.initState();
    _init = _bootstrapThenPrepare();
  }

  Future<void> _bootstrapThenPrepare() async {
    await _bootstrap();
    if (!mounted) return;
    setState(() {
      _themeService = ThemeService();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SubTrack',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.light,
            home: const SplashScreen(),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 56,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to start SubTrack',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Firebase is ready — safe to use ThemeService.
        return _ThemedApp(themeService: _themeService!);
      },
    );
  }
}

class _ThemedApp extends StatelessWidget {
  final ThemeService themeService;

  const _ThemedApp({required this.themeService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Logged out → force light mode.
        if (!authSnapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SubTrack',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.light,
            home: const AuthGate(),
          );
        }

        // Logged in → listen to the user's dark mode preference.
        return StreamBuilder<bool>(
          stream: themeService.darkModeStream(),
          builder: (context, themeSnapshot) {
            final isDark = themeSnapshot.data ?? false;

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'SubTrack',
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              home: const AuthGate(),
            );
          },
        );
      },
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
          return const SplashScreen();
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}