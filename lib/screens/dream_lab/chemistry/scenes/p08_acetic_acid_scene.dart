import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/practical_model.dart';

class P08AceticAcidScene extends StatefulWidget {
  final Practical practical;

  const P08AceticAcidScene({
    super.key,
    required this.practical,
  });

  @override
  State<P08AceticAcidScene> createState() => _P08AceticAcidSceneState();
}

class _P08AceticAcidSceneState extends State<P08AceticAcidScene>
    with TickerProviderStateMixin {
  late AnimationController _effervescenceController;
  late AnimationController _aromaWaveController;
  late AnimationController _reactionAnimController;

  final List<String> testModes = [
    "Odor Test",
    "Solubility in Water",
    "Litmus Paper Test",
    "Reaction with NaHCO₃",
  ];

  String activeTest = "Odor Test";
  bool isReacted = false;
  final List<Map<String, String>> recordedResults = [];
  String observation =
      "Select a test and tap 'Perform Test' to inspect ethanoic acid properties.";

  @override
  void initState() {
    super.initState();
    _effervescenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat();

    _aromaWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _reactionAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _effervescenceController.dispose();
    _aromaWaveController.dispose();
    _reactionAnimController.dispose();
    super.dispose();
  }

  void _triggerTest() {
    setState(() {
      isReacted = true;
      if (activeTest == "Odor Test") {
        observation =
        "Wafting vapors: Characteristic sharp, pungent vinegar-like smell confirmed.";
      } else if (activeTest == "Solubility in Water") {
        observation =
        "Water added: Ethanoic acid dissolves completely, forming a clear homogeneous solution.";
      } else if (activeTest == "Litmus Paper Test") {
        observation =
        "Blue litmus dipped: Submerged portion turns distinctly red (Acidic pH).";
      } else {
        observation =
        "Brisk effervescence! NaHCO₃ powder decomposes with vigorous CO₂ bubble evolution.";
      }
    });
    _reactionAnimController.forward(from: 0.0);
  }

  void _recordObservation() {
    if (!isReacted) {
      setState(
              () => observation = "Perform the test first before recording data.");
      return;
    }

    if (recordedResults.any((r) => r["test"] == activeTest)) {
      setState(
              () => observation = "Observation for $activeTest already recorded.");
      return;
    }

    String resultText;
    if (activeTest == "Odor Test") {
      resultText = "Pungent vinegar odor";
    } else if (activeTest == "Solubility in Water") {
      resultText = "Miscible in all proportions";
    } else if (activeTest == "Litmus Paper Test") {
      resultText = "Blue litmus turns red";
    } else {
      resultText = "Brisk effervescence (CO₂↑)";
    }

    setState(() {
      recordedResults.add({"test": activeTest, "result": resultText});
      observation =
      "Recorded $activeTest! Select another property from the tray.";
    });
  }

  void _selectTest(String test) {
    setState(() {
      activeTest = test;
      isReacted = false;
      observation = "Selected $test. Tap 'Perform Test'.";
    });
    _reactionAnimController.reset();
  }

  void _resetLab() {
    setState(() {
      activeTest = "Odor Test";
      isReacted = false;
      recordedResults.clear();
      observation =
      "Bench reset. Select a property to test ethanoic acid.";
    });
    _reactionAnimController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff0B0E1B),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        children: [
          _buildCompactTitle(),
          const SizedBox(height: 3),
          Expanded(child: _buildWorkspace()),
          const SizedBox(height: 3),
          _buildBottomControlBar(),
        ],
      ),
    );
  }

  Widget _buildCompactTitle() {
    return Container(
      height: 28,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xff1A173B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
      ),
      child: Text(
        widget.practical.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }

  Widget _buildWorkspace() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff121026).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                _buildDynamicReactionStation(),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 4,
                  child: _buildObservationBar(),
                ),
              ],
            ),
          ),
          VerticalDivider(width: 1, color: Colors.white.withOpacity(0.08)),
          Expanded(
            flex: 4,
            child: _buildObservationLogPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicReactionStation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Bench Base Stand
            Positioned(
              bottom: h * 0.2,
              child: Container(
                width: 120,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xff1E1942),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.12),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),

            // Main Test Tube & Chemical Assembly
            Positioned(
              bottom: h * 0.28,
              child: SizedBox(
                width: 60,
                height: 100,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // Test Tube Body
                    Container(
                      width: 34,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(17)),
                        border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.6), width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.12),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // 1. Dynamic Fluid Column
                          AnimatedBuilder(
                            animation: _reactionAnimController,
                            builder: (context, child) {
                              double liquidHeight = 48.0;
                              Color liquidColor = const Color(0x3300BCD4);

                              if (activeTest == "Solubility in Water" &&
                                  isReacted) {
                                // Water addition increases volume
                                liquidHeight = 48.0 +
                                    (_reactionAnimController.value * 28.0);
                                liquidColor = const Color(0x4400B0FF);
                              } else if (activeTest == "Reaction with NaHCO₃" &&
                                  isReacted) {
                                // Milky effervescing tint
                                liquidColor = Color.lerp(
                                  const Color(0x3300BCD4),
                                  const Color(0x99ECEFF1),
                                  _reactionAnimController.value,
                                )!;
                              }

                              return Container(
                                height: liquidHeight,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: liquidColor,
                                  borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(15)),
                                ),
                              );
                            },
                          ),

                          // 2. Dissolution Swirling Waves (Solubility test)
                          if (activeTest == "Solubility in Water" && isReacted)
                            AnimatedBuilder(
                              animation: _reactionAnimController,
                              builder: (context, child) {
                                return CustomPaint(
                                  size: const Size(34, 70),
                                  painter: _MixingSwirlPainter(
                                    progress: _reactionAnimController.value,
                                  ),
                                );
                              },
                            ),

                          // 3. Falling NaHCO3 Salt Crystals inside liquid
                          if (activeTest == "Reaction with NaHCO₃" && isReacted)
                            AnimatedBuilder(
                              animation: _reactionAnimController,
                              builder: (context, child) {
                                return CustomPaint(
                                  size: const Size(34, 50),
                                  painter: _SaltPowderPainter(
                                    progress: _reactionAnimController.value,
                                  ),
                                );
                              },
                            ),

                          // 4. Vigorous CO2 Effervescence Fizz Bubbles
                          if (activeTest == "Reaction with NaHCO₃" && isReacted)
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _effervescenceController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: _CO2BubblesPainter(
                                        progress:
                                        _effervescenceController.value),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 5. Dipping Litmus Strip Animation
                    if (activeTest == "Litmus Paper Test")
                      AnimatedBuilder(
                        animation: _reactionAnimController,
                        builder: (context, child) {
                          final double dropDistance = isReacted
                              ? (_reactionAnimController.value * 28.0)
                              : 0.0;
                          final Color tipColor = isReacted
                              ? Color.lerp(
                            const Color(0xff1976D2), // Blue litmus
                            const Color(0xffD32F2F), // Turns Red in acid
                            _reactionAnimController.value,
                          )!
                              : const Color(0xff1976D2);

                          return Positioned(
                            bottom: 16 - dropDistance,
                            child: Container(
                              width: 8,
                              height: 65,
                              decoration: BoxDecoration(
                                color: const Color(0xff1976D2),
                                borderRadius: BorderRadius.circular(1.5),
                                border: Border.all(
                                    color: Colors.white30, width: 0.5),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: tipColor,
                                      borderRadius: const BorderRadius.vertical(
                                          bottom: Radius.circular(1.5)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // 6. Odor Test Aroma Waves & Wafting Hand
                    if (activeTest == "Odor Test" && isReacted)
                      Positioned(
                        top: -45,
                        child: SizedBox(
                          width: 80,
                          height: 50,
                          child: AnimatedBuilder(
                            animation: _aromaWaveController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _AromaVaporPainter(
                                  progress: _aromaWaveController.value,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // 7. Frothing Gas Plume above mouth for NaHCO3
                    if (activeTest == "Reaction with NaHCO₃" && isReacted)
                      Positioned(
                        top: -18,
                        child: SizedBox(
                          width: 32,
                          height: 22,
                          child: AnimatedBuilder(
                            animation: _effervescenceController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _FrothPlumePainter(
                                  progress: _effervescenceController.value,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Odor Wafting Gesture Graphic
            if (activeTest == "Odor Test" && isReacted)
              Positioned(
                right: w * 0.22,
                top: h * 0.22,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xff1E1942),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orangeAccent.withOpacity(0.2),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.air, size: 14, color: Colors.orangeAccent),
                      SizedBox(width: 4),
                      Text(
                        "Wafting Smell: Pungent Vinegar",
                        style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.orangeAccent),
                      ),
                    ],
                  ),
                ),
              ),

            // Water Dropper Graphic during solubility test
            if (activeTest == "Solubility in Water")
              Positioned(
                top: h * 0.12,
                child: Column(
                  children: [
                    Container(
                      width: 8,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xff78909C),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      width: 14,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xff37474F),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (isReacted)
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                  ],
                ),
              ),

            // Spatula adding NaHCO3 powder
            if (activeTest == "Reaction with NaHCO₃")
              Positioned(
                top: h * 0.16,
                right: w * 0.32,
                child: Transform.rotate(
                  angle: -0.35,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 38,
                        height: 4,
                        color: const Color(0xff9E9E9E),
                      ),
                      Container(
                        width: 14,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(4)),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 2)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Active Test Badge
            Positioned(
              bottom: h * 0.14,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xff1A173B),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                ),
                child: Text(
                  activeTest,
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildObservationLogPanel() {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ethanoic Acid Test Log",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xff1A173B).withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Container(
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    color: const Color(0xff1E1942),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 5,
                          child: Text(
                            "Test",
                            style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Text(
                            "Observation",
                            style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: recordedResults.isEmpty
                        ? const Center(
                      child: Text(
                        "Perform tests & record",
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white38,
                        ),
                      ),
                    )
                        : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: recordedResults.length,
                      itemBuilder: (context, i) {
                        final r = recordedResults[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2.5,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Text(
                                  r["test"]!,
                                  style: const TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: Text(
                                  r["result"]!,
                                  style: const TextStyle(
                                    fontSize: 7.5,
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservationBar() {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xff1A173B),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined,
              size: 13, color: Colors.cyanAccent),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              observation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 9.5,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControlBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xff121026),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: testModes.map((t) {
                  final isSelected = activeTest == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ChoiceChip(
                      label: Text(t,
                          style: TextStyle(
                              fontSize: 8.5,
                              color:
                              isSelected ? Colors.white : Colors.white60)),
                      selected: isSelected,
                      selectedColor: const Color(0xff6C5CE7),
                      backgroundColor: const Color(0xff1A173B),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.purpleAccent
                            : Colors.white.withOpacity(0.08),
                      ),
                      onSelected: (_) => _selectTest(t),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: _triggerTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff6C5CE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text("Perform Test",
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: _recordObservation,
            icon: const Icon(Icons.bookmark_add_outlined, size: 13),
            label: const Text("Record",
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1A173B),
              foregroundColor: Colors.cyanAccent,
              side: BorderSide(color: Colors.cyanAccent.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 4),
          OutlinedButton(
            onPressed: _resetLab,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              side: BorderSide(color: Colors.white.withOpacity(0.12)),
            ),
            child: const Text("Reset",
                style: TextStyle(fontSize: 9.5, color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

// --- Custom Chemical Painters ---

class _CO2BubblesPainter extends CustomPainter {
  final double progress;
  _CO2BubblesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(42);
    for (int i = 0; i < 14; i++) {
      final double wave = sin((progress * 2 * pi) + i) * 3.0;
      final x =
          (size.width * 0.2) + (rand.nextDouble() * size.width * 0.6) + wave;
      final y = size.height - (progress * size.height * 0.95) - (i * 4.0);

      if (y < 0) continue;

      final double r = 1.2 + rand.nextDouble() * 2.0;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CO2BubblesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _AromaVaporPainter extends CustomPainter {
  final double progress;
  _AromaVaporPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(19);
    for (int i = 0; i < 5; i++) {
      final double sway = sin((progress * 2 * pi) + (i * 1.2)) * 8.0;
      final double x = (size.width * 0.5) + sway + (i * 5.0);
      final double y = size.height - (progress * size.height * 0.9) - (i * 6.0);

      if (y < 0) continue;

      final alpha = ((1.0 - (progress * 0.8)) * 220).toInt().clamp(0, 255);
      canvas.drawCircle(
        Offset(x, y),
        3.0 + (rand.nextDouble() * 3.0),
        Paint()..color = const Color(0xFFFFB74D).withAlpha(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AromaVaporPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _MixingSwirlPainter extends CustomPainter {
  final double progress;
  _MixingSwirlPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity((1.0 - progress) * 0.7)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.4);
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * (0.4 + progress * 0.3),
      size.width * 0.3,
      size.height * 0.8,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MixingSwirlPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SaltPowderPainter extends CustomPainter {
  final double progress;
  _SaltPowderPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(77);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.95);

    for (int i = 0; i < 10; i++) {
      final x = size.width * 0.25 + rand.nextDouble() * size.width * 0.5;
      final y = (progress * size.height * 0.85) + (rand.nextDouble() * 5.0);
      if (y > size.height) continue;
      canvas.drawCircle(Offset(x, y), 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SaltPowderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _FrothPlumePainter extends CustomPainter {
  final double progress;
  _FrothPlumePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final x = (size.width * 0.25) + (i * 7.0);
      final y = size.height * 0.5 + sin((progress * 2 * pi) + i) * 3.0;
      canvas.drawCircle(Offset(x, y), 3.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FrothPlumePainter oldDelegate) =>
      oldDelegate.progress != progress;
}