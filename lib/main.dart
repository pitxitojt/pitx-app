import 'package:flutter/material.dart';
import 'package:pitx/screens/Base.dart';
import 'package:pitx/screens/Welcome.dart';
import 'package:pitx/auth/Login.dart';
import 'package:pitx/auth/SetPin.dart';
import 'package:pitx/auth/Signup.dart';
import 'package:pitx/auth/ProfileCompletion.dart';
import 'package:pitx/themes/red.dart';
import 'package:pitx/themes/default.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Utility class to manage authentication state
class AuthManager {
  static bool _isLoggedIn = false;
  static DateTime? _appPausedTime;
  // static DateTime? _lastActivityTime;
  static final List<Function(bool)> _listeners = [];

  static bool get isLoggedIn => _isLoggedIn;

  static bool get requiresReauth {
    if (_appPausedTime == null) return false;

    final now = DateTime.now();

    // Only check app background time, not inactivity while app is active
    if (_appPausedTime != null) {
      final timeDifference = now.difference(_appPausedTime!);
      if (timeDifference.inMinutes >= 1) {
        return true;
      }
    }

    return false;
  }

  static void setLoggedIn(bool value) {
    if (_isLoggedIn != value) {
      _isLoggedIn = value;
      // Notify listeners
      for (var listener in _listeners) {
        listener(_isLoggedIn);
      }
    }
  }

  static void addListener(Function(bool) listener) {
    _listeners.add(listener);
  }

  static void removeListener(Function(bool) listener) {
    _listeners.remove(listener);
  }

  // Method to handle logout
  static Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      setLoggedIn(false);
    } catch (e) {
      print("Error during logout: $e");
      // Even if there's an error, set logged out state
      setLoggedIn(false);
    }
  }

  // Method to handle app going to background
  static void handleAppPaused() {
    if (_isLoggedIn) {
      _appPausedTime = DateTime.now();
    }
  }

  // Method to handle app coming back from background
  static bool handleAppResumed() {
    bool needsReauth = requiresReauth;

    // Reset the pause time since app is now active
    _appPausedTime = null;

    // Return true if re-authentication was required
    return needsReauth;
  }

  // Method to update last activity time
  // static void updateActivity() {
  //   if (_isLoggedIn) {
  //     _lastActivityTime = DateTime.now();
  //   }
  // }

  // Method to reset re-authentication requirement
  static void clearReauthRequirement() {
    _appPausedTime = null;
    // Reset any re-auth requirements - user is actively using the app
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await dotenv.load();
  // hide anonKey in public repo
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  final prefs = await SharedPreferences.getInstance();
  final isDark = await prefs.getBool('dark_mode_enabled') ?? false;

  runApp(MyApp(isAlternateThemeEnabled: isDark));
}

final supabase = Supabase.instance.client;
final ValueNotifier<bool> isAlternateThemeEnabledNotifier = ValueNotifier<bool>(
  false,
);

class MyApp extends StatelessWidget {
  final bool isAlternateThemeEnabled;
  MyApp({super.key, required this.isAlternateThemeEnabled}) {
    isAlternateThemeEnabledNotifier.value = isAlternateThemeEnabled;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isAlternateThemeEnabledNotifier,
      builder: (_, isAlternateTheme, _) {
        return MaterialApp(
          title: 'PITX',
          theme: isAlternateTheme ? redTheme : defaultTheme,
          initialRoute: '/',
          routes: {
            '/': (context) => const Initialization(title: 'PITX'),
            '/welcome': (context) => const Welcome(),
            '/login': (context) => const Login(),
            '/signup': (context) => const Signup(),
            '/profile-completion': (context) => const ProfileCompletion(),
            '/set-pin': (context) => const SetPin(),
            '/home': (context) => const Base(),
            // '/phone-verification': (context) => const PhoneVerification(),
          },
        );
      },
    );
  }
}

class Initialization extends StatefulWidget {
  const Initialization({super.key, required this.title});
  final String title;

  @override
  State<Initialization> createState() => _InitializationState();
}

class _InitializationState extends State<Initialization> {
  bool _localIsLoggedIn = false;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
    _setupAuthListener();
    // Add listener for login state changes
    AuthManager.addListener(_handleLoginStateChange);
  }

  void _setupAuthListener() {
    // Listen to auth state changes from Supabase
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;

      if (session != null) {
        // User is logged in
        AuthManager.setLoggedIn(true);
      } else {
        // User is logged out
        AuthManager.setLoggedIn(false);
      }
    });
  }

  Future<void> _checkExistingSession() async {
    try {
      // Check if there's an existing session
      final session = supabase.auth.currentSession;
      final user = supabase.auth.currentUser;

      if (session != null && user != null) {
        // User is already logged in
        AuthManager.setLoggedIn(true);
        setState(() {
          _localIsLoggedIn = true;
        });
      } else {
        AuthManager.setLoggedIn(false);
        setState(() {
          _localIsLoggedIn = false;
        });
      }
    } catch (e) {
      print("Error checking session: $e");
      AuthManager.setLoggedIn(false);
      setState(() {
        _localIsLoggedIn = false;
      });
    } finally {
      setState(() {
        _isCheckingSession = false;
      });
    }
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    AuthManager.removeListener(_handleLoginStateChange);
    super.dispose();
  }

  void _handleLoginStateChange(bool isLoggedIn) {
    setState(() {
      _localIsLoggedIn = isLoggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking session
    if (_isCheckingSession) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                SizedBox(height: 24),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_localIsLoggedIn) {
      return Welcome();
    }

    return Login();
  }
}
