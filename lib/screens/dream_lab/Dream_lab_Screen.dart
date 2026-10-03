import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chemistry/chemistry_lab.dart';
import 'physics/physics_lab.dart';

class DreamLabScreen extends StatefulWidget {
  const DreamLabScreen({super.key});

  @override
  State<DreamLabScreen> createState() => _DreamLabScreenState();
}

class _DreamLabScreenState extends State<DreamLabScreen> {
  bool isPhysics = false; // false = Chemistry, true = Physics

  @override
  void initState() {
    super.initState();

    // Always open Dream Lab in Landscape
    _setLandscape();
  }

  Future<void> _setLandscape() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restorePortrait() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // Restore portrait orientation after leaving Dream Lab
    _restorePortrait();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B0E1B),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.2,
            colors: [
              Color(0xff2A1B54),
              Color(0xff0B0E1B),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),

              Expanded(
                child: isPhysics
                    ? PhysicsLab(
                  onSwitchToChemistry: () {
                    setState(() {
                      isPhysics = false;
                    });
                  },
                )
                    : ChemistryLab(
                  onSwitchToPhysics: () {
                    setState(() {
                      isPhysics = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xff121026).withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              await _restorePortrait();

              if (mounted) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 4),

          const Icon(
            Icons.blur_on,
            color: Colors.cyanAccent,
            size: 24,
          ),

          const SizedBox(width: 8),

          const Text(
            "Dream Lab",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xff1A173B),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.purpleAccent.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                _tabOption(
                  "Chemistry",
                  !isPhysics,
                      () {
                    setState(() {
                      isPhysics = false;
                    });
                  },
                ),
                _tabOption(
                  "Physics",
                  isPhysics,
                      () {
                    setState(() {
                      isPhysics = true;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabOption(
      String title,
      bool active,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xff6C5CE7)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: active
              ? [
            BoxShadow(
              color: const Color(0xff6C5CE7)
                  .withOpacity(0.4),
              blurRadius: 10,
            ),
          ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active
                ? Colors.white
                : Colors.white60,
          ),
        ),
      ),
    );
  }
}