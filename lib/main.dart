import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

import 'splash_screen.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'screens/home/home_page.dart';
import 'email_verification_page.dart';
import 'google_profile_page.dart';
import 'admin_dashboard.dart';
import 'assessment_page.dart';
import 'profile_page.dart';
import 'screens/ai_assistant/ai_assistant_screen.dart';
Future main() async {
  WidgetsBinding widgetsBinding =
  WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(
    widgetsBinding: widgetsBinding,
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(const LearnovaApp());
}

class LearnovaApp extends StatelessWidget {
  const LearnovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Learnova",

      theme: ThemeData(
        useMaterial3: true,
      ),

      home: const SplashScreen(),

      routes: {
        "/login": (context) => const LoginPage(),
        "/signup": (context) => const SignupPage(),
        "/home": (context) => const HomePage(),
        "/admin": (context) => const AdminDashboard(),
        "/assistant": (context) => const AiAssistantScreen(),
        "/profile": (context) => const ProfilePage(),
      },

      onGenerateRoute: (settings) {
        switch (settings.name) {
          case "/emailVerification":
            final String email =
            settings.arguments as String;

            return MaterialPageRoute(
              builder: (_) =>
                  EmailVerificationPage(
                    email: email,
                  ),
            );

          case "/googleProfile":
            final User user =
            settings.arguments as User;

            return MaterialPageRoute(
              builder: (_) =>
                  GoogleProfilePage(
                    user: user,
                  ),
            );

          case "/assessment":
            final String standard =
            settings.arguments as String;

            return MaterialPageRoute(
              builder: (_) =>
                  AssessmentPage(
                    standard: standard,
                  ),
            );

          default:
            return MaterialPageRoute(
              builder: (_) =>
              const LoginPage(),
            );
        }
      },
    );
  }
}