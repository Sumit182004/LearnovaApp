import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/practical_model.dart';

class P01PHScene extends StatefulWidget {
  final Practical practical;

  const P01PHScene({
    super.key,
    required this.practical,
  });

  @override
  State<P01PHScene> createState() => _P01PHSceneState();
}

class _P01PHSceneState extends State<P01PHScene>
    with TickerProviderStateMixin {
  late AnimationController _bubbleController;
  late AnimationController _indicatorDipController;
  late AnimationController _liquidColorAnimController;

  final List<String> tubeKeys = ["Tube 1", "Tube 2", "Tube 3"];
  final Map<String, String> defaultLabels = {
    "Tube 1": "HCl (Acid)",
    "Tube 2": "NaOH (Base)",
    "Tube 3": "Water (Neutral)",
  };

  final Map<String, String> tubeSamples = {
    "Tube 1": "HCl",
    "Tube 2": "NaOH",
    "Tube 3": "Water",
  };

  final Map<String, Color> tubeCurrentLiquidColors = {
    "Tube 1": const Color(0x33FF5252),
    "Tube 2": const Color(0x33448AFF),
    "Tube 3": const Color(0x2200BCD4),
  };

  final Map<String, Color> tubePreviousLiquidColors = {
    "Tube 1": const Color(0x33FF5252),
    "Tube 2": const Color(0x33448AFF),
    "Tube 3": const Color(0x2200BCD4),
  };

  final Map<String, Color> tubeTargetLiquidColors = {
    "Tube 1": const Color(0x33FF5252),
    "Tube 2": const Color(0x33448AFF),
    "Tube 3": const Color(0x2200BCD4),
  };

  final Map<String, Color> tubeResultColors = {
    "Tube 1": Colors.transparent,
    "Tube 2": Colors.transparent,
    "Tube 3": Colors.transparent,
  };

  final Map<String, bool> tubeBubbles = {
    "Tube 1": false,
    "Tube 2": false,
    "Tube 3": false,
  };

  final Map<String, bool> tubeZinc = {
    "Tube 1": false,
    "Tube 2": false,
    "Tube 3": false,
  };

  final Map<String, bool> tubeCarbonate = {
    "Tube 1": false,
    "Tube 2": false,
    "Tube 3": false,
  };

  String activeTube = "Tube 1";
  String observation = "Drop or tap any reagent/tool onto a test tube.";

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _indicatorDipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _liquidColorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _indicatorDipController.dispose();
    _liquidColorAnimController.dispose();
    super.dispose();
  }

  void _triggerLiquidColorChange(String tube, Color newColor) {
    tubePreviousLiquidColors[tube] = tubeCurrentLiquidColors[tube]!;
    tubeTargetLiquidColors[tube] = newColor;
    _liquidColorAnimController.forward(from: 0.0).then((_) {
      tubeCurrentLiquidColors[tube] = newColor;
    });
  }

  void _handleAction(String item, String targetTube) {
    setState(() {
      activeTube = targetTube;

      // Sample replacement
      if (item == "HCl" || item == "NaOH" || item == "Water") {
        tubeSamples[targetTube] = item;
        tubeResultColors[targetTube] = Colors.transparent;
        tubeBubbles[targetTube] = false;
        tubeZinc[targetTube] = false;
        tubeCarbonate[targetTube] = false;

        Color baseColor = const Color(0x2200BCD4);
        if (item == "HCl") baseColor = const Color(0x33FF5252);
        if (item == "NaOH") baseColor = const Color(0x33448AFF);

        _triggerLiquidColorChange(targetTube, baseColor);
        observation = "Filled $targetTube with fresh $item.";
        return;
      }

      final sample = tubeSamples[targetTube] ?? "";

      // Indicator & Reaction Tools
      if (item == "pH Paper") {
        Color stripC = Colors.green;
        Color solC = const Color(0x5566BB6A);

        if (sample == "HCl") {
          stripC = Colors.orange;
          solC = const Color(0x66FF7043);
          observation = "pH Paper turned Orange-Red in $targetTube ($sample, pH ~ 1-2).";
        } else if (sample == "NaOH") {
          stripC = Colors.purple;
          solC = const Color(0x667E57C2);
          observation = "pH Paper turned Purple in $targetTube ($sample, pH ~ 13-14).";
        } else {
          observation = "pH Paper turned Green in $targetTube ($sample, pH ~ 7).";
        }

        tubeResultColors[targetTube] = stripC;
        _triggerLiquidColorChange(targetTube, solC);
        _indicatorDipController.forward(from: 0.0);
      } else if (item == "Litmus") {
        Color stripC = Colors.purple.shade300;
        Color solC = const Color(0x44AB47BC);

        if (sample == "HCl") {
          stripC = Colors.red;
          solC = const Color(0x66EF5350);
          observation = "Litmus turned Red in $targetTube ($sample - Acid).";
        } else if (sample == "NaOH") {
          stripC = Colors.blue;
          solC = const Color(0x6642A5F5);
          observation = "Litmus turned Blue in $targetTube ($sample - Base).";
        } else {
          observation = "No characteristic litmus color change in $targetTube (Water).";
        }

        tubeResultColors[targetTube] = stripC;
        _triggerLiquidColorChange(targetTube, solC);
        _indicatorDipController.forward(from: 0.0);
      } else if (item == "Zinc") {
        tubeZinc[targetTube] = true;
        if (sample == "HCl") {
          tubeBubbles[targetTube] = true;
          observation = "Zinc + HCl in $targetTube: Hydrogen gas effervescence produced!";
        } else {
          tubeBubbles[targetTube] = false;
          observation = "Zinc added to $targetTube ($sample): No visible reaction.";
        }
      } else if (item == "Sodium Carbonate") {
        tubeCarbonate[targetTube] = true;
        if (sample == "HCl") {
          tubeBubbles[targetTube] = true;
          observation = "Na₂CO₃ + HCl in $targetTube: Vigorous CO₂ bubbles evolved!";
        } else {
          tubeBubbles[targetTube] = false;
          observation = "Na₂CO₃ added to $targetTube ($sample): No visible reaction.";
        }
      }
    });
  }

  void _resetExperiment() {
    setState(() {
      tubeSamples["Tube 1"] = "HCl";
      tubeSamples["Tube 2"] = "NaOH";
      tubeSamples["Tube 3"] = "Water";

      tubePreviousLiquidColors["Tube 1"] = const Color(0x33FF5252);
      tubePreviousLiquidColors["Tube 2"] = const Color(0x33448AFF);
      tubePreviousLiquidColors["Tube 3"] = const Color(0x2200BCD4);

      tubeTargetLiquidColors["Tube 1"] = const Color(0x33FF5252);
      tubeTargetLiquidColors["Tube 2"] = const Color(0x33448AFF);
      tubeTargetLiquidColors["Tube 3"] = const Color(0x2200BCD4);

      tubeCurrentLiquidColors["Tube 1"] = const Color(0x33FF5252);
      tubeCurrentLiquidColors["Tube 2"] = const Color(0x33448AFF);
      tubeCurrentLiquidColors["Tube 3"] = const Color(0x2200BCD4);

      for (final tube in tubeKeys) {
        tubeResultColors[tube] = Colors.transparent;
        tubeBubbles[tube] = false;
        tubeZinc[tube] = false;
        tubeCarbonate[tube] = false;
      }

      activeTube = "Tube 1";
      observation = "Experiment reset. Test tubes freshly prepared.";
    });
    _indicatorDipController.reset();
    _liquidColorAnimController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff0B0E1B),
      padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 4),
      child: Column(
        children: [
          _buildCompactTitle(),
          const SizedBox(height: 3),
          Expanded(
            child: _buildPracticalScene(),
          ),
          const SizedBox(height: 3),
          _buildMaterialsTray(),
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
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(0.3),
        ),
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

  Widget _buildPracticalScene() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sceneHeight = constraints.maxHeight;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xff121026).withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: Stack(
            children: [
              _buildBench(),
              Positioned(
                left: 8,
                right: 8,
                top: 4,
                bottom: 34,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: tubeKeys.map((key) {
                    return Expanded(
                      child: _buildTubeTarget(key, sceneHeight),
                    );
                  }).toList(),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 4,
                child: _buildObservationBar(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBench() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 38,
      child: Container(
        height: 16,
        decoration: BoxDecoration(
          color: const Color(0xff1E1942),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.12),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTubeTarget(String tubeKey, double sceneHeight) {
    final sample = tubeSamples[tubeKey] ?? "";
    final isSelected = activeTube == tubeKey;

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        _handleAction(details.data, tubeKey);
      },
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () {
            setState(() {
              activeTube = tubeKey;
              observation = "Selected ${defaultLabels[tubeKey]}. Tap or drag any tool.";
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(
              color: hovering
                  ? const Color(0x336C5CE7)
                  : (isSelected ? const Color(0x1F6C5CE7) : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hovering || isSelected ? Colors.cyanAccent : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, tubeAreaConstraints) {
                        final tubeHeight = min(100.0, tubeAreaConstraints.maxHeight * 0.92);
                        final tubeWidth = min(tubeAreaConstraints.maxWidth * 0.55, min(34.0, tubeHeight * 0.36));

                        return SizedBox(
                          width: tubeWidth + 10,
                          height: tubeHeight,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            clipBehavior: Clip.none,
                            children: [
                              // Smooth Liquid Animated Paint
                              AnimatedBuilder(
                                animation: _liquidColorAnimController,
                                builder: (context, child) {
                                  final displayColor = Color.lerp(
                                    tubePreviousLiquidColors[tubeKey],
                                    tubeTargetLiquidColors[tubeKey],
                                    _liquidColorAnimController.value,
                                  ) ?? tubeCurrentLiquidColors[tubeKey]!;

                                  return CustomPaint(
                                    size: Size(tubeWidth, tubeHeight),
                                    painter: _TestTubePainter(
                                      liquidColor: displayColor,
                                    ),
                                  );
                                },
                              ),

                              // Zinc Pellet
                              if (tubeZinc[tubeKey] == true)
                                Positioned(
                                  bottom: 4,
                                  child: Container(
                                    width: 10,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),

                              // Sodium Carbonate Particles
                              if (tubeCarbonate[tubeKey] == true)
                                Positioned(
                                  bottom: 5,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      3,
                                          (index) => Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 0.8),
                                        width: 3.0,
                                        height: 3.0,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Effervescence Bubbles Animation
                              if (tubeBubbles[tubeKey] == true)
                                Positioned(
                                  bottom: 4,
                                  child: SizedBox(
                                    width: tubeWidth - 4,
                                    height: tubeHeight * 0.52,
                                    child: AnimatedBuilder(
                                      animation: _bubbleController,
                                      builder: (context, child) {
                                        return CustomPaint(
                                          painter: _BubblePainter(
                                            progress: _bubbleController.value,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                              // Animated Dipping Paper Strip
                              if (tubeResultColors[tubeKey] != Colors.transparent)
                                AnimatedBuilder(
                                  animation: _indicatorDipController,
                                  builder: (context, child) {
                                    final dipProgress = _indicatorDipController.value;
                                    final double stripTop = -12.0 + (dipProgress * 15.0);

                                    return Positioned(
                                      top: stripTop,
                                      right: -1,
                                      child: Transform.rotate(
                                        angle: -0.15,
                                        child: Container(
                                          width: 5.5,
                                          height: tubeHeight * 0.58,
                                          decoration: BoxDecoration(
                                            color: tubeResultColors[tubeKey],
                                            borderRadius: BorderRadius.circular(2),
                                            border: Border.all(color: Colors.white30, width: 0.5),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black38,
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xff6C5CE7) : const Color(0xff1A173B),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? Colors.purpleAccent : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      sample,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.cyanAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  tubeKey,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsTray() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xff121026),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.science_outlined,
              size: 17,
              color: Colors.cyanAccent,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _materialChip("HCl", Icons.science, Colors.redAccent),
                  _materialChip("NaOH", Icons.science, Colors.blueAccent),
                  _materialChip("Water", Icons.water_drop, Colors.lightBlueAccent),
                  VerticalDivider(width: 10, thickness: 1, color: Colors.white.withOpacity(0.08)),
                  _materialChip("pH Paper", Icons.description, Colors.orangeAccent),
                  _materialChip("Litmus", Icons.colorize, Colors.purpleAccent),
                  _materialChip("Zinc", Icons.grain, Colors.grey.shade400),
                  _materialChip("Sodium Carbonate", Icons.bubble_chart, Colors.tealAccent),
                ],
              ),
            ),
          ),
          VerticalDivider(width: 8, thickness: 1, color: Colors.white.withOpacity(0.08)),
          _buildResetButton(),
        ],
      ),
    );
  }

  Widget _materialChip(String label, IconData icon, Color iconColor) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0xff1A173B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    return Draggable<String>(
      data: label,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xff1E1942),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: iconColor),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: chip),
      child: InkWell(
        onTap: () => _handleAction(label, activeTube),
        borderRadius: BorderRadius.circular(6),
        child: chip,
      ),
    );
  }

  Widget _buildResetButton() {
    return Material(
      color: const Color(0xff1A173B),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: _resetExperiment,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                size: 14,
                color: Colors.cyanAccent,
              ),
              SizedBox(width: 3),
              Text(
                "Reset",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.cyanAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestTubePainter extends CustomPainter {
  final Color liquidColor;

  _TestTubePainter({required this.liquidColor});

  @override
  void paint(Canvas canvas, Size size) {
    final left = 2.0;
    final right = size.width - 2.0;
    final top = 2.0;
    final bottom = size.height - 2.0;
    final radius = (right - left) / 2;

    // Liquid fill
    final liquidTop = size.height * 0.44;
    final liquidPath = Path()
      ..moveTo(left + 1.5, liquidTop)
      ..lineTo(right - 1.5, liquidTop)
      ..lineTo(right - 1.5, bottom - radius)
      ..quadraticBezierTo(right - 1.5, bottom - 1.5, size.width / 2, bottom - 1.5)
      ..quadraticBezierTo(left + 1.5, bottom - 1.5, left + 1.5, bottom - radius)
      ..close();

    canvas.drawPath(liquidPath, Paint()..color = liquidColor);

    // Glass body outline
    final tubePath = Path()
      ..moveTo(left, top)
      ..lineTo(left, bottom - radius)
      ..quadraticBezierTo(left, bottom, size.width / 2, bottom)
      ..quadraticBezierTo(right, bottom, right, bottom - radius)
      ..lineTo(right, top);

    final tubePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = Colors.cyanAccent.withOpacity(0.6);

    canvas.drawPath(tubePath, tubePaint);

    // Rim
    canvas.drawLine(
      Offset(left - 2, top),
      Offset(right + 2, top),
      Paint()
        ..color = Colors.cyanAccent.withOpacity(0.8)
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _TestTubePainter oldDelegate) {
    return oldDelegate.liquidColor != liquidColor;
  }
}

class _BubblePainter extends CustomPainter {
  final double progress;

  _BubblePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(20);

    for (int i = 0; i < 8; i++) {
      final x = size.width * 0.2 + random.nextDouble() * size.width * 0.6;
      final startY = size.height * 0.85 + random.nextDouble() * size.height * 0.10;
      final y = startY - progress * size.height * 0.75;
      final radius = 1.2 + random.nextDouble() * 1.6;

      if (y < 0) continue;

      canvas.drawCircle(
        Offset(x + sin(progress * pi * 2 + i) * 2, y),
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withAlpha(220),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}