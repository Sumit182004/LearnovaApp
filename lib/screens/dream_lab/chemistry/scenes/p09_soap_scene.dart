import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/practical_model.dart';

class P09SoapScene extends StatefulWidget {
  final Practical practical;

  const P09SoapScene({
    super.key,
    required this.practical,
  });

  @override
  State<P09SoapScene> createState() => _P09SoapSceneState();
}

class _P09SoapSceneState extends State<P09SoapScene>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _foamGrowthController;
  late AnimationController _bubbleJitterController;

  bool soapInTubeA = false;
  bool soapInTubeB = false;
  bool isShaken = false;

  final List<Map<String, String>> recordedComparisons = [];
  String observation =
      "Drag the Soap Dropper into Tube A (Soft) and Tube B (Hard), then tap 'Shake Tubes'.";

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _foamGrowthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _bubbleJitterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _foamGrowthController.dispose();
    _bubbleJitterController.dispose();
    super.dispose();
  }

  void _addSoap(String tube) {
    setState(() {
      if (tube == "A") {
        soapInTubeA = true;
        observation = "Soap added to Tube A (Soft Water). Now add to Tube B or shake.";
      } else if (tube == "B") {
        soapInTubeB = true;
        observation = "Soap added to Tube B (Hard Water). Now tap 'Shake Tubes'.";
      }
    });
  }

  void _shakeTubes() {
    if (!soapInTubeA && !soapInTubeB) {
      setState(() {
        observation = "Drag the soap solution into at least one tube before shaking.";
      });
      return;
    }

    setState(() {
      isShaken = true;
      observation =
      "Shaking completed! Tube A formed rich lather; Tube B formed insoluble white scum with little foam.";
    });

    _shakeController.forward(from: 0.0).then((_) {
      _shakeController.reverse();
    });
    _foamGrowthController.forward(from: 0.0);
  }

  void _recordData() {
    if (!isShaken) {
      setState(() => observation = "Add soap and shake the tubes before recording.");
      return;
    }

    if (recordedComparisons.isNotEmpty) {
      setState(() => observation = "Comparative data is already recorded in the table.");
      return;
    }

    setState(() {
      recordedComparisons.add({
        "sample": "Soft Water",
        "foam": "Tall, rich lather",
        "scum": "None",
        "capacity": "High",
      });
      recordedComparisons.add({
        "sample": "Hard Water",
        "foam": "Very little lather",
        "scum": "Curdy white ppt",
        "capacity": "Poor",
      });
      observation =
      "Data recorded: Soap has significantly greater cleaning efficiency in soft water.";
    });
  }

  void _resetLab() {
    setState(() {
      soapInTubeA = false;
      soapInTubeB = false;
      isShaken = false;
      recordedComparisons.clear();
      observation =
      "Tubes cleaned and refilled. Drag soap dropper into the tubes.";
    });
    _shakeController.reset();
    _foamGrowthController.reset();
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
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
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
          // Left: Interactive Test Bench
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                _buildTubesBench(),
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

          // Right: Comparison Log Table
          Expanded(
            flex: 4,
            child: _buildComparisonLogPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildTubesBench() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Wooden Test Tube Rack Stand
            Positioned(
              bottom: h * 0.16,
              child: Container(
                width: 220,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xff1E1942),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.12),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),

            // Two Test Tubes
            Positioned(
              bottom: h * 0.18,
              child: AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final shakeOffset = sin(_shakeController.value * pi * 8) * 6.0;
                  final tiltAngle = sin(_shakeController.value * pi * 6) * 0.05;

                  return Transform.translate(
                    offset: Offset(shakeOffset, 0),
                    child: Transform.rotate(
                      angle: tiltAngle,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDropTargetTube("A", isHardWater: false),
                          const SizedBox(width: 48),
                          _buildDropTargetTube("B", isHardWater: true),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropTargetTube(String tubeId, {required bool isHardWater}) {
    final hasSoap = tubeId == "A" ? soapInTubeA : soapInTubeB;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data == "Soap",
      onAcceptWithDetails: (_) => _addSoap(tubeId),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () => _addSoap(tubeId),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 135,
                decoration: BoxDecoration(
                  color: isHovered
                      ? const Color(0x336C5CE7)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                  border: Border.all(
                    color: isHovered
                        ? Colors.cyanAccent
                        : Colors.cyanAccent.withOpacity(0.5),
                    width: isHovered ? 2.2 : 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.12),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Base Water Liquid Column
                    AnimatedBuilder(
                      animation: _foamGrowthController,
                      builder: (context, child) {
                        Color liquidColor = isHardWater
                            ? (isShaken
                            ? const Color(0x99CFD8DC)
                            : const Color(0x3300BCD4))
                            : const Color(0x3300E5FF);

                        return Container(
                          height: 52,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: liquidColor,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                          ),
                        );
                      },
                    ),

                    // Scum precipitate particles (Tube B)
                    if (isHardWater && isShaken)
                      AnimatedBuilder(
                        animation: _foamGrowthController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(40, 50),
                            painter: _ScumPainter(
                              progress: _foamGrowthController.value,
                            ),
                          );
                        },
                      ),

                    // Realistic Bubble Foam Layer for Tube A and Scum Cap for Tube B
                    if (hasSoap && isShaken)
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _foamGrowthController,
                          _bubbleJitterController,
                        ]),
                        builder: (context, child) {
                          final double maxFoamHeight = isHardWater ? 14.0 : 58.0;
                          final double currentFoamHeight =
                              maxFoamHeight * _foamGrowthController.value;

                          if (currentFoamHeight <= 0) {
                            return const SizedBox.shrink();
                          }

                          return Positioned(
                            bottom: 52,
                            child: SizedBox(
                              width: 40,
                              height: currentFoamHeight,
                              child: CustomPaint(
                                painter: _RealisticFoamPainter(
                                  isHardWater: isHardWater,
                                  growthProgress: _foamGrowthController.value,
                                  jitter: _bubbleJitterController.value,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    // Soap indicator dot before shaking
                    if (hasSoap && !isShaken)
                      Positioned(
                        bottom: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xffFFB300),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xff1A173B),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Text(
                  isHardWater ? "Tube B (Hard)" : "Tube A (Soft)",
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComparisonLogPanel() {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Cleansing Action Log",
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
                          flex: 3,
                          child: Text(
                            "Water",
                            style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "Lather",
                            style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "Scum",
                            style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Action",
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
                    child: recordedComparisons.isEmpty
                        ? const Center(
                      child: Text(
                        "Shake tubes & record observations",
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white38,
                        ),
                      ),
                    )
                        : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: recordedComparisons.length,
                      itemBuilder: (context, i) {
                        final r = recordedComparisons[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 3.0,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  r["sample"]!,
                                  style: const TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  r["foam"]!,
                                  style: const TextStyle(
                                    fontSize: 7.5,
                                    color: Colors.white60,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  r["scum"]!,
                                  style: const TextStyle(
                                    fontSize: 7.5,
                                    color: Colors.white60,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  r["capacity"]!,
                                  style: TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.bold,
                                    color: r["capacity"] == "High"
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
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
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_outlined,
            size: 13,
            color: Colors.cyanAccent,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              observation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControlBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xff121026),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Draggable Soap Solution Dropper Tool
            Draggable<String>(
              data: "Soap",
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xff1E1942),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.colorize, size: 13, color: Color(0xffFF8F00)),
                      SizedBox(width: 3),
                      Text(
                        "Soap",
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xff1A173B),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.colorize, size: 13, color: Color(0xffFF8F00)),
                    SizedBox(width: 3),
                    Text(
                      "Drag Soap",
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 5),

            // Shake Action Button
            ElevatedButton.icon(
              onPressed: _shakeTubes,
              icon: const Icon(Icons.waves, size: 12),
              label: const Text(
                "Shake",
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff6C5CE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(width: 5),

            // Record Table Button
            ElevatedButton.icon(
              onPressed: _recordData,
              icon: const Icon(Icons.bookmark_add_outlined, size: 12),
              label: const Text(
                "Record",
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1A173B),
                foregroundColor: Colors.cyanAccent,
                side: BorderSide(color: Colors.purpleAccent.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(width: 5),

            // Reset Button
            OutlinedButton(
              onPressed: _resetLab,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: const Text(
                "Reset",
                style: TextStyle(fontSize: 9, color: Colors.cyanAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RealisticFoamPainter extends CustomPainter {
  final bool isHardWater;
  final double growthProgress;
  final double jitter;

  _RealisticFoamPainter({
    required this.isHardWater,
    required this.growthProgress,
    required this.jitter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isHardWater) {
      // Thin, flat curdy scum crust
      final scumPaint = Paint()
        ..color = const Color(0xEEEDE7F6)
        ..style = PaintingStyle.fill;
      final scumRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 0, size.width - 4, size.height),
        const Radius.circular(3),
      );
      canvas.drawRRect(scumRect, scumPaint);
      return;
    }

    // Rich translucent foam body
    final foamBasePaint = Paint()
      ..color = const Color(0xDDFFFFFF)
      ..style = PaintingStyle.fill;

    final foamRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 0, size.width - 2, size.height),
      const Radius.circular(3),
    );
    canvas.drawRRect(foamRect, foamBasePaint);

    // Individual clustered lather bubbles
    final bubbleEdgePaint = Paint()
      ..color = const Color(0x8880CBC4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final bubbleFillPaint = Paint()
      ..color = const Color(0x44FFFFFF)
      ..style = PaintingStyle.fill;

    final rand = Random(12);

    for (int i = 0; i < 24; i++) {
      final bx = 3.0 + rand.nextDouble() * (size.width - 6.0);
      final by = rand.nextDouble() * size.height;
      final r = 2.0 + (rand.nextDouble() * 3.5);

      canvas.drawCircle(Offset(bx, by), r, bubbleFillPaint);
      canvas.drawCircle(Offset(bx, by), r, bubbleEdgePaint);
    }

    // Bubbly top surface meniscus
    final topMeniscusPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    for (double x = 4; x < size.width - 4; x += 5.5) {
      final floatJitter = sin(jitter * 2 * pi + x) * 0.8;
      canvas.drawCircle(Offset(x, floatJitter), 3.2, topMeniscusPaint);
      canvas.drawCircle(Offset(x, floatJitter), 3.2, bubbleEdgePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RealisticFoamPainter oldDelegate) =>
      oldDelegate.isHardWater != isHardWater ||
          oldDelegate.growthProgress != growthProgress ||
          oldDelegate.jitter != jitter;
}

class _ScumPainter extends CustomPainter {
  final double progress;
  _ScumPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(55);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 18; i++) {
      final x = rand.nextDouble() * size.width;
      final y = (progress * size.height * 0.9) + (rand.nextDouble() * 4.0);
      if (y > size.height) continue;
      canvas.drawCircle(Offset(x, y), 1.3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScumPainter oldDelegate) =>
      oldDelegate.progress != progress;
}