// login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_in_button/sign_in_button.dart';
import './widgets/animated_orb.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: Colors.white70,
      ),
      hintStyle: const TextStyle(
        color: Colors.white54,
        fontSize: 15,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: Colors.white24,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: Colors.white24,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: Color(0xFF7B61FF),
          width: 2,
        ),
      ),
    );
  }

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final UserCredential credential =
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final User user = credential.user!;

      // Check email verification
      if (!user.emailVerified) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          "/emailVerification",
          arguments: user.email ?? "",
        );

        return;
      }

      // Get user profile from Firestore
      final DocumentSnapshot document =
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!document.exists) {
        throw Exception(
          "User profile not found.",
        );
      }

      final Map<String, dynamic> data =
      document.data()
      as Map<String, dynamic>;

      final String role =
          data["role"]
              ?.toString()
              .toLowerCase() ??
              "student";

      // ======================================================
      // ADMIN
      // ======================================================

      if (role == "admin") {
        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          "/admin",
              (route) => false,
        );

        return;
      }

      // ======================================================
      // STUDENT
      // ======================================================

      final bool assessmentCompleted =
          data["assessmentCompleted"] ?? false;

      final String standard =
          data["standard"]?.toString() ?? "";

      if (standard.isEmpty) {
        throw Exception(
          "Student standard is not available.",
        );
      }

      if (!mounted) return;

      if (assessmentCompleted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/home",
              (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/assessment",
              (route) => false,
          arguments: standard,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message =
          e.message ?? "Login Failed";

      if (e.code == "invalid-credential") {
        message =
        "Invalid email or password";
      } else if (
      e.code ==
          "network-request-failed"
      ) {
        message =
        "No Internet Connection";
      } else if (
      e.code ==
          "user-disabled"
      ) {
        message =
        "This account has been disabled";
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Login failed: $e",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> googleLogin() async {
    setState(() => isLoading = true);

    try {
      final GoogleSignInAccount? googleUser =
      await GoogleSignIn().signIn();

      if (googleUser == null) {
        return;
      }

      final auth =
      await googleUser.authentication;

      final credential =
      GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance
          .signInWithCredential(
        credential,
      );

      final User user =
      userCredential.user!;

      final DocumentSnapshot document =
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      // New Google user must complete profile first
      if (!document.exists) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          "/googleProfile",
          arguments: user,
        );

        return;
      }

      final Map<String, dynamic> data =
      document.data()
      as Map<String, dynamic>;

      final String role =
          data["role"]
              ?.toString()
              .toLowerCase() ??
              "student";

      // ======================================================
      // ADMIN
      // ======================================================

      if (role == "admin") {
        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          "/admin",
              (route) => false,
        );

        return;
      }

      // ======================================================
      // STUDENT
      // ======================================================

      final bool assessmentCompleted =
          data["assessmentCompleted"] ?? false;

      final String standard =
          data["standard"]?.toString() ?? "";

      if (standard.isEmpty) {
        throw Exception(
          "Student standard is not available.",
        );
      }

      if (!mounted) return;

      if (assessmentCompleted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/home",
              (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/assessment",
              (route) => false,
          arguments: standard,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> forgotPassword() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter Email First"),
        ),
      );
      return;
    }

    await FirebaseAuth.instance
        .sendPasswordResetEmail(
      email: emailController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Password Reset Email Sent"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF090414),
              Color(0xFF24104A),
              Color(0xFF3A1C71),
              Color(0xFF090414),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Container(
                         width: 420,
                         padding: const EdgeInsets.symmetric(
                           horizontal: 30,
                           vertical: 24,
                         ),
                         decoration: BoxDecoration(
                           color: Colors.white.withOpacity(0.05),
                           borderRadius: BorderRadius.circular(32),
                           border: Border.all(
                             color: Colors.white.withOpacity(0.10),
                             width: 1,
                           ),
                         ),
                         child: Column(
                    children: [

                       Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Explore Your Universe",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),

                          SizedBox(height: 12),

                          Text(
                            "Discover concepts through AI, stories, and simulations.",
                            style: TextStyle(
                              fontSize: 17,
                             color: Colors.white.withOpacity(0.82),
                              height: 1.5,
                            ),
                          ),

                          SizedBox(height: 12),
                        ],
                      ),

                      Center(
                        child: const Center(
                                 child: AnimatedOrb(),
                               ),
                      ),

                      const SizedBox(height: 18),

                      TextFormField(
                        controller:
                        emailController,
                        decoration:
                        inputDecoration(
                          hint: "Email",
                          icon: Icons.email,
                        ),
                        validator: (v) {
                          if (v == null ||
                              v.isEmpty) {
                            return "Enter Email";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller:
                        passwordController,
                        obscureText:
                        obscurePassword,
                        decoration:
                        inputDecoration(
                          hint: "Password",
                          icon: Icons.lock,
                        ).copyWith(
                          suffixIcon:
                          IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword =
                                !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons
                                  .visibility_off
                                  : Icons
                                  .visibility,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null ||
                              v.isEmpty) {
                            return "Enter Password";
                          }
                          return null;
                        },
                      ),

                      Align(
                        alignment:
                        Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                          forgotPassword,
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color:
                              Colors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : loginUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF4C1D95),
                                  Color(0xFF6D28D9),
                                  Color(0xFF8B5CF6),
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x804C1D95),
                                  blurRadius: 24,
                                  spreadRadius: 1,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Continue →",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Row(
                        children: [
                          Expanded(
                              child: Divider()),
                          Padding(
                            padding:
                            EdgeInsets.symmetric(
                                horizontal:
                                10),
                            child: Text(
                              "OR",
                              style: TextStyle(
                                color: Colors
                                    .white,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: OutlinedButton(
                          onPressed: isLoading ? null : googleLogin,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.05),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.18),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/Google_Logo.png",
                                height: 22,
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                "Continue with Google",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(
                                color: Colors
                                    .white),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                "/signup",
                              );
                            },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors
                                    .white,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}