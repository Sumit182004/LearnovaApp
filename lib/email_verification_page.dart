// email_verification_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState
    extends State<EmailVerificationPage> {
  bool isLoading = false;

  Future<void> resendEmail() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;

      await user?.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Verification Email Sent Again",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> checkVerification() async {
    setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.currentUser?.reload();

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        "/login",
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Email is still not verified.",
          ),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff081062),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const Icon(
                    Icons.mark_email_read,
                    size: 90,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Verify Your Email",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "We've sent a verification link to",
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.email,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Please open your email and click the verification link before logging in.",
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed:
                      isLoading ? null : checkVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xff081062),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text(
                        "I Have Verified",
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed:
                      isLoading ? null : resendEmail,
                      child: const Text(
                        "Resend Email",
                        style: TextStyle(
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextButton(
                    onPressed: () async {


                      if (!mounted) return;

                      Navigator.pushReplacementNamed(
                        context,
                        "/login",
                      );
                    },
                    child: const Text(
                      "Back To Login",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}