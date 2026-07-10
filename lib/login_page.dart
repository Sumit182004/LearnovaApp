// login_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_in_button/sign_in_button.dart';

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
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.blue,
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      UserCredential credential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await credential.user!.reload();

      User user = FirebaseAuth.instance.currentUser!;

      if (!user.emailVerified) {
        Navigator.pushReplacementNamed(
          context,
          "/emailVerification",
          arguments: user.email,
        );

        setState(() => isLoading = false);
        return;
      }

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      Map<String, dynamic> data =
      doc.data() as Map<String, dynamic>;

      bool assessment =
          data["assessmentCompleted"] ?? false;

      if (!mounted) return;

      if (assessment) {
        Navigator.pushReplacementNamed(
          context,
          "/home",
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          "/assessment",
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Login Failed"),
        ),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> googleLogin() async {
    setState(() => isLoading = true);

    try {
      final GoogleSignInAccount? googleUser =
      await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final auth = await googleUser.authentication;

      final credential =
      GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      UserCredential userCredential =
      await FirebaseAuth.instance
          .signInWithCredential(credential);

      User user = userCredential.user!;

      DocumentSnapshot document =
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!document.exists) {
        Navigator.pushReplacementNamed(
          context,
          "/googleProfile",
          arguments: user,
        );
        return;
      }

      Map<String, dynamic> data =
      document.data() as Map<String, dynamic>;

      bool assessment =
          data["assessmentCompleted"] ?? false;

      if (assessment) {
        Navigator.pushReplacementNamed(
          context,
          "/home",
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          "/assessment",
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }

    setState(() => isLoading = false);
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
            colors: [
              Color(0xff8BEAFB),
              Color(0xff081062),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                  width: 360,
                  padding:
                  const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                    borderRadius:
                    BorderRadius.circular(
                        25),
                  ),
                  child: Column(
                    children: [

                      const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 30),

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
                        width:
                        double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed:
                          isLoading
                              ? null
                              : loginUser,
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(
                                0xff081062),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                            color: Colors
                                .white,
                          )
                              : const Text(
                            "Login",
                            style:
                            TextStyle(
                              color: Colors
                                  .white,
                              fontSize: 18,
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
                        height: 55,
                        child: SignInButton(
                          Buttons.google,
                          text: "Continue with Google",
                          onPressed: () {
                            if (!isLoading) {
                              googleLogin();
                            }
                          },
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