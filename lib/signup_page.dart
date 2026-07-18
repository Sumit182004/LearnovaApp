import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController =
      TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  String selectedStandard = "class10";

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final String email = emailController.text.trim();

      // Create Firebase Authentication account
      final UserCredential credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: passwordController.text.trim(),
      );

      final User user = credential.user!;

      // Save user profile in Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({
        "uid": user.uid,
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "email": email,
        "standard": selectedStandard,
        "role": "student",
        "assessmentCompleted": false,
        "photoUrl": "",
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Send Firebase email verification link
      await user.sendEmailVerification();

      if (!mounted) return;

      // Open verification page
      Navigator.pushReplacementNamed(
        context,
        "/emailVerification",
        arguments: email,
      );
    } on FirebaseAuthException catch (e) {
      String message = "Signup Failed";

      switch (e.code) {
        case "email-already-in-use":
          message = "Email already exists";
          break;

        case "weak-password":
          message = "Password is too weak";
          break;

        case "invalid-email":
          message = "Invalid Email";
          break;

        case "network-request-failed":
          message = "No Internet Connection";
          break;

        case "too-many-requests":
          message = "Too many attempts. Please try again later.";
          break;

        default:
          message = e.message ?? "Signup Failed";
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Something went wrong: $e",
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

  Future<void> signInWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser =
      await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      User user = userCredential.user!;

      DocumentSnapshot document = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      // NEW USER
      if (!document.exists) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          "/googleProfile",
          arguments: user,
        );
      }

      // EXISTING USER
      else {
        Map<String, dynamic> data =
        document.data() as Map<String, dynamic>;

        bool assessment =
            data["assessmentCompleted"] ?? false;

        if (!mounted) return;

        if (assessment) {
          Navigator.pushReplacementNamed(
            context,
            "/home",
          );
        } else {
          final String standard =
              data["standard"]?.toString() ?? "";

          if (standard.isEmpty) {
            throw Exception(
              "Student standard is not available.",
            );
          }

          Navigator.pushReplacementNamed(
            context,
            "/assessment",
            arguments: standard,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Google Sign In Failed"),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
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
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Container(
                  width: 360,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.white.withOpacity(0.15),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 25),

                      TextFormField(
                        controller: nameController,
                        decoration: inputDecoration(
                          hint: "Full Name",
                          icon: Icons.person,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Enter Full Name";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: inputDecoration(
                          hint: "Phone Number",
                          icon: Icons.phone,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Enter Phone Number";
                          }

                          if (value.length != 10) {
                            return "Enter Valid Phone Number";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: inputDecoration(
                          hint: "Email",
                          icon: Icons.email,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Enter Email";
                          }

                          if (!value.contains("@")) {
                            return "Invalid Email";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: inputDecoration(
                          hint: "Password",
                          icon: Icons.lock,
                        ).copyWith(
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword =
                                    !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Enter Password";
                          }

                          if (value.length < 6) {
                            return "Minimum 6 characters";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      DropdownButtonFormField<String>(
                        value: selectedStandard,
                        decoration: inputDecoration(
                          hint: "Select Standard",
                          icon: Icons.school,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "class10",
                            child: Text("Class 10"),
                          ),
                          DropdownMenuItem(
                            value: "class12",
                            child: Text("Class 12"),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedStandard = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff081062),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(15),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                              : const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          Padding(
                            padding:
                            EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "OR",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(child: Divider()),
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
                              signInWithGoogle();
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account?",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    )
    );
  }
}