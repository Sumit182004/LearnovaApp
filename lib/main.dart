import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

import 'splash_screen.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'email_verification_page.dart';
import 'google_profile_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
      },

      onGenerateRoute: (settings) {
        switch (settings.name) {
          case "/emailVerification":
            final email = settings.arguments as String;

            return MaterialPageRoute(
              builder: (_) => EmailVerificationPage(
                email: email,
              ),
            );

          case "/googleProfile":
            final user = settings.arguments as User;

            return MaterialPageRoute(
              builder: (_) => GoogleProfilePage(
                user: user,
              ),
            );

          case "/assessment":
            return MaterialPageRoute(
              builder: (_) => const HomePage(),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const LoginPage(),
            );
        }
      },
    );
  }
}