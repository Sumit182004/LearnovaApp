import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _videoInitialized = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(
      "assets/splash_animation.mp4",
    )
      ..initialize().then((_) {
        if (!mounted) return;

        setState(() {
          _videoInitialized = true;
        });

        _controller.play();
      });

    _controller.addListener(() {
      if (_controller.value.isInitialized &&
          !_controller.value.isPlaying &&
          _controller.value.position >= _controller.value.duration) {
        _navigateNext();
      }
    });
  }

  void _navigateNext() {
    if (_navigated) return;

    _navigated = true;

    User? user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user != null) {
      Navigator.pushReplacementNamed(
        context,
        "/home",
      );
    } else {
      Navigator.pushReplacementNamed(
        context,
        "/login",
      );
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
      body: Center(
        child: _videoInitialized
            ? SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        )
            : const CircularProgressIndicator(
          color: Color(0xFF00E5CC),
        ),
      ),
    );
  }
}