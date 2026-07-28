import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  bool _initialized = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    initializeVideo();
  }

  Future<void> initializeVideo() async {
    _controller = VideoPlayerController.asset(
      "assets/updated_animation.mp4",
    );

    await _controller.initialize();

    if (!mounted) return;

    // Remove native splash only when the video is ready
    FlutterNativeSplash.remove();

    setState(() {
      _initialized = true;
    });

    _controller.play();

    Future.delayed(_controller.value.duration, () {
      if (!mounted) return;
      navigateNext();
    });
  }

  Future<void> navigateNext() async {
    if (_navigated) return;

    _navigated = true;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacementNamed(context, "/login");
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        Navigator.pushReplacementNamed(context, "/login");
        return;
      }

      final data = doc.data()!;

      final role = data["role"] ?? "student";

      if (role == "admin") {
        Navigator.pushReplacementNamed(context, "/admin");
        return;
      }

      final assessmentCompleted =
          data["assessmentCompleted"] ?? false;

      if (!assessmentCompleted) {
        final standard = data["standard"] ?? "Class 10";

        Navigator.pushReplacementNamed(
          context,
          "/assessment",
          arguments: standard,
        );
      } else {
        Navigator.pushReplacementNamed(context, "/home");
      }
    } catch (e) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060E14),
      body: !_initialized
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00E5CC),
        ),
      )
          : SizedBox.expand(
        child: VideoPlayer(_controller),
      ),
    );
  }
}