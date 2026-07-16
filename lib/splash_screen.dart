import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      "assets/splash_animations.mp4",
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

  void navigateNext() {
    if (_navigated) return;

    _navigated = true;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacementNamed(context, "/login");
    } else {
      Navigator.pushReplacementNamed(context, "/home");
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