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
  bool isResending = false;

  Future<void> checkVerification() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Reload user to get the latest verification status
      await FirebaseAuth.instance.currentUser?.reload();

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Your session has expired. Please login again.",
            ),
          ),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          "/login",
              (route) => false,
        );

        return;
      }

      if (user.emailVerified) {
        // Verification successful
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Email verified successfully. Please login.",
            ),
          ),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          "/login",
              (route) => false,
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Email is still not verified. Please click the verification link sent to your email.",
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                "Unable to check email verification.",
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

  Future<void> resendVerificationEmail() async {
    setState(() {
      isResending = true;
    });

    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Your session has expired. Please login again.",
            ),
          ),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          "/login",
              (route) => false,
        );

        return;
      }

      await user.sendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Verification email sent again.",
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message =
          e.message ?? "Unable to resend verification email.";

      if (e.code == "too-many-requests") {
        message =
        "Too many requests. Please wait before trying again.";
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isResending = false;
        });
      }
    }
  }

  Future<void> backToLogin() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/login",
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff081062),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                    "Please open your email and click the verification link. Then return here and press the button below.",
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
                      onPressed: isResending
                          ? null
                          : resendVerificationEmail,
                      child: isResending
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        "Resend Email",
                        style: TextStyle(
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextButton(
                    onPressed: backToLogin,
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