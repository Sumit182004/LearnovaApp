import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize the video from your assets
    _controller = VideoPlayerController.asset('assets/splash_animation.mp4')
      ..initialize().then((_) {
        // Once initialized, play the video and update the state to show it
        setState(() {
          _isVideoPlaying = true;
        });
        _controller.play();
      });

    // Listen to the video's progress
    _controller.addListener(() {
      // Check if the video has reached the end
      if (_controller.value.isInitialized &&
          _controller.value.position == _controller.value.duration) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    // Prevent multiple navigations
    _controller.removeListener(() {}); 
    
    // Navigate to the main app screen with a smooth fade transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use the dark space color for the background while loading
      backgroundColor: const Color(0xFF060E14), 
      body: Center(
        child: _isVideoPlaying
            ? SizedBox.expand(
                // FittedBox ensures the video scales to cover the entire screen
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            // Optional: A subtle loading indicator before the first frame renders
            : const CircularProgressIndicator(
                color: Color(0xFF00E5CC), // Teal color from your logo
              ), 
      ),
    );
  }
}

// ------------------------------------------------------------------
// Dummy Home Screen so the code runs perfectly out of the box
// ------------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060E14),
      appBar: AppBar(
        title: const Text('Learnova', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Welcome to your Universe of Knowledge',
          style: TextStyle(color: Color(0xFF00E5CC), fontSize: 16),
        ),
      ),
    );
  }
}