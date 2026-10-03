import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/practical_model.dart';

class P02ReactionScene extends StatefulWidget {
  final Practical practical;

  const P02ReactionScene({
    super.key,
    required this.practical,
  });

  @override
  State<P02ReactionScene> createState() => _P02ReactionSceneState();
}

class _P02ReactionSceneState extends State<P02ReactionScene>
    with TickerProviderStateMixin {
  late AnimationController _vaporController;
  late AnimationController _burnerFlameController;
  late AnimationController _reactionAnimController;

  final List<String> tubeKeys = ["Tube 1", "Tube 2", "Tube 3", "Tube 4"];
  final Map<String, String> reactionTitles = {
    "Tube 1": "Combination",
    "Tube 2": "Decomposition",
    "Tube 3": "Displacement",
    "Tube 4": "Double Displ.",
  };

  final Map<String, String> tubePrimary = {
    "Tube 1": "CaO (Quicklime)",
    "Tube 2": "FeSO₄ Crystals",
    "Tube 3": "CuSO₄ Solution",
    "Tube 4": "BaCl₂ Solution",
  };

  final Map<String, bool> reactionTriggered = {
    "Tube 1": false,
    "Tube 2": false,
    "Tube 3": false,
    "Tube 4": false,
  };

  String activeTube = "Tube 1";
  String observation =
      "Drag a reagent or tool (Water, Heat, Iron Nail, Na₂SO₄) into a tube.";

  @override
  void initState() {
    super.initState();

    _vaporController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _burnerFlameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..repeat(reverse: true);

    _reactionAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _vaporController.dispose();
    _burnerFlameController.dispose();
    _reactionAnimController.dispose();
    super.dispose();
  }

  void _triggerReaction(String item, String targetTube) {
    setState(() {
      activeTube = targetTube;

      if (targetTube == "Tube 1") {
        if (item == "Water") {
          reactionTriggered["Tube 1"] = true;
          observation =
          "Combination: CaO + H₂O → Ca(OH)₂ (Exothermic reaction releases steam).";
          _reactionAnimController.forward(from: 0.0);
        } else {
          observation = "Tube 1 contains Quicklime. Add Water to start.";
        }
      } else if (targetTube == "Tube 2") {
        if (item == "Heat / Burner") {
          reactionTriggered["Tube 2"] = true;
          observation =
          "Decomposition: 2FeSO₄ → Fe₂O₃ (brown) + SO₂↑ + SO₃↑ under heat.";
          _reactionAnimController.forward(from: 0.0);
        } else {
          observation = "Tube 2 contains Ferrous Sulphate. Apply Heat/Burner.";
        }
      } else if (targetTube == "Tube 3") {
        if (item == "Iron Nail") {
          reactionTriggered["Tube 3"] = true;
          observation =
          "Displacement: Fe + CuSO₄ → FeSO₄ (pale green) + Cu deposit on nail.";
          _reactionAnimController.forward(from: 0.0);
        } else {
          observation = "Tube 3 contains blue CuSO₄. Add an Iron Nail.";
        }
      } else if (targetTube == "Tube 4") {
        if (item == "Na₂SO₄ Soln") {
          reactionTriggered["Tube 4"] = true;
          observation =
          "Double Displacement: Na₂SO₄ + BaCl₂ → BaSO₄↓ (White ppt) + 2NaCl.";
          _reactionAnimController.forward(from: 0.0);
        } else {
          observation = "Tube 4 contains BaCl₂. Add Na₂SO₄ solution.";
        }
      }
    });
  }

  void _resetLab() {
    setState(() {
      reactionTriggered["Tube 1"] = false;
      reactionTriggered["Tube 2"] = false;
      reactionTriggered["Tube 3"] = false;
      reactionTriggered["Tube 4"] = false;
      activeTube = "Tube 1";
      observation =
      "Experiment reset. Reagents and test tubes are freshly set up.";
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
            clipBehavior: Clip.none,
            children: [
              _buildBench(),
              Positioned(
                left: 6,
                right: 6,
                top: 4,
                bottom: 34,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: tubeKeys.map((key) {
                    return Expanded(
                      child: _buildTubeStation(key, sceneHeight),
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
      left: 10,
      right: 10,
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

  Widget _buildTubeStation(String tubeKey, double sceneHeight) {
    final isSelected = activeTube == tubeKey;
    final isTriggered = reactionTriggered[tubeKey] == true;

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        _triggerReaction(details.data, tubeKey);
      },
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () {
            setState(() {
              activeTube = tubeKey;
              observation =
              "Selected ${reactionTitles[tubeKey]} (${tubePrimary[tubeKey]}). Use a reagent/tool.";
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(
              color: hovering
                  ? const Color(0x336C5CE7)
                  : (isSelected
                  ? const Color(0x1F6C5CE7)
                  : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hovering || isSelected
                    ? Colors.cyanAccent
                    : Colors.transparent,
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
                      builder: (context, tubeConstraints) {
                        final tubeHeight =
                        min(105.0, tubeConstraints.maxHeight * 0.90);
                        final tubeWidth = min(
                            tubeConstraints.maxWidth * 0.48,
                            min(32.0, tubeHeight * 0.35));

                        return SizedBox(
                          width: tubeWidth + 24,
                          height: tubeHeight,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            clipBehavior: Clip.none,
                            children: [
                              if (tubeKey == "Tube 2" && isTriggered)
                                Positioned(
                                  bottom: -18,
                                  child: AnimatedBuilder(
                                    animation: _burnerFlameController,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        size: const Size(28, 24),
                                        painter: _FlamePainter(
                                          progress:
                                          _burnerFlameController.value,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              AnimatedBuilder(
                                animation: _reactionAnimController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    size: Size(tubeWidth, tubeHeight),
                                    painter: _ReactionTubePainter(
                                      tubeKey: tubeKey,
                                      isReacted: isTriggered,
                                      animProgress:
                                      _reactionAnimController.value,
                                    ),
                                  );
                                },
                              ),
                              if (tubeKey == "Tube 3")
                                AnimatedBuilder(
                                  animation: _reactionAnimController,
                                  builder: (context, child) {
                                    final progress = isTriggered
                                        ? _reactionAnimController.value
                                        : 0.0;
                                    final nailColor = Color.lerp(
                                      const Color(0xff78909C),
                                      const Color(0xffFF7043),
                                      progress,
                                    )!;

                                    return Positioned(
                                      bottom: 5,
                                      child: Transform.rotate(
                                        angle: -0.16,
                                        child: Container(
                                          width: 6.5,
                                          height: tubeHeight * 0.46,
                                          decoration: BoxDecoration(
                                            color: nailColor,
                                            borderRadius:
                                            BorderRadius.circular(2.0),
                                            border: Border.all(
                                              color: Colors.white30,
                                              width: 0.8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: nailColor.withValues(alpha: 0.6),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              if (isTriggered &&
                                  (tubeKey == "Tube 1" || tubeKey == "Tube 2"))
                                Positioned(
                                  top: -24,
                                  child: SizedBox(
                                    width: tubeWidth + 16,
                                    height: 38,
                                    child: AnimatedBuilder(
                                      animation: _vaporController,
                                      builder: (context, child) {
                                        return CustomPaint(
                                          painter: _VaporPainter(
                                            progress: _vaporController.value,
                                            isSulfur: tubeKey == "Tube 2",
                                          ),
                                        );
                                      },
                                    ),
                                  ),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xff6C5CE7)
                          : const Color(0xff1A173B),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? Colors.purpleAccent
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      reactionTitles[tubeKey]!,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : Colors.cyanAccent,
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
                  _materialChip("Water", Icons.water_drop, Colors.cyanAccent),
                  _materialChip("Heat / Burner", Icons.local_fire_department,
                      Colors.deepOrangeAccent),
                  _materialChip("Iron Nail", Icons.hardware, Colors.blueGrey.shade200),
                  _materialChip(
                      "Na₂SO₄ Soln", Icons.bubble_chart, Colors.tealAccent),
                ],
              ),
            ),
          ),
          VerticalDivider(
              width: 8, thickness: 1, color: Colors.white.withOpacity(0.08)),
          _buildResetButton(),
        ],
      ),
    );
  }

  Widget _materialChip(String label, IconData icon, Color iconColor) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: const Color(0xff1A173B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
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
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 6),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: chip),
      child: InkWell(
        onTap: () => _triggerReaction(label, activeTube),
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
        onTap: _resetLab,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
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

class _ReactionTubePainter extends CustomPainter {
  final String tubeKey;
  final bool isReacted;
  final double animProgress;

  _ReactionTubePainter({
    required this.tubeKey,
    required this.isReacted,
    required this.animProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final left = 2.0;
    final right = size.width - 2.0;
    final top = 2.0;
    final bottom = size.height - 2.0;
    final radius = (right - left) / 2;

    final fillTop = size.height * 0.42;
    final fillPath = Path()
      ..moveTo(left + 1.5, fillTop)
      ..lineTo(right - 1.5, fillTop)
      ..lineTo(right - 1.5, bottom - radius)
      ..quadraticBezierTo(
          right - 1.5, bottom - 1.5, size.width / 2, bottom - 1.5)
      ..quadraticBezierTo(left + 1.5, bottom - 1.5, left + 1.5, bottom - radius)
      ..close();

    Color initialColor = Colors.transparent;
    Color reactedColor = Colors.transparent;

    if (tubeKey == "Tube 1") {
      initialColor = const Color(0x66CFD8DC);
      reactedColor = const Color(0xFFECEFF1);
    } else if (tubeKey == "Tube 2") {
      initialColor = const Color(0xFF43A047);
      reactedColor = const Color(0xFF8D6E63);
    } else if (tubeKey == "Tube 3") {
      initialColor = const Color(0xFF00E5FF);
      reactedColor = const Color(0xFF81C784);
    } else if (tubeKey == "Tube 4") {
      initialColor = const Color(0x3300BCD4);
      reactedColor = const Color(0xFFFFFFFF);
    }

    final color = isReacted
        ? Color.lerp(initialColor, reactedColor, animProgress)!
        : initialColor;

    canvas.drawPath(fillPath, Paint()..color = color);

    final tubePath = Path()
      ..moveTo(left, top)
      ..lineTo(left, bottom - radius)
      ..quadraticBezierTo(left, bottom, size.width / 2, bottom)
      ..quadraticBezierTo(right, bottom, right, bottom - radius)
      ..lineTo(right, top);

    canvas.drawPath(
      tubePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.cyanAccent.withOpacity(0.6),
    );

    canvas.drawLine(
      Offset(left + 3, top + 4),
      Offset(left + 3, bottom - radius - 6),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1.0,
    );

    canvas.drawLine(
      Offset(left - 2, top),
      Offset(right + 2, top),
      Paint()
        ..color = Colors.cyanAccent.withOpacity(0.8)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ReactionTubePainter oldDelegate) {
    return oldDelegate.tubeKey != tubeKey ||
        oldDelegate.isReacted != isReacted ||
        oldDelegate.animProgress != animProgress;
  }
}

class _FlamePainter extends CustomPainter {
  final double progress;

  _FlamePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final burnerBase = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height - 2),
      width: 14,
      height: 6,
    );
    canvas.drawRect(
      burnerBase,
      Paint()..color = const Color(0xFF546E7A),
    );

    final outerFlame = Path()
      ..moveTo(size.width * 0.15, size.height - 4)
      ..quadraticBezierTo(
        size.width * 0.0,
        size.height * 0.35,
        size.width * 0.5,
        size.height * (progress * 0.2),
      )
      ..quadraticBezierTo(
        size.width * 1.0,
        size.height * 0.35,
        size.width * 0.85,
        size.height - 4,
      )
      ..close();

    canvas.drawPath(
      outerFlame,
      Paint()..color = const Color(0xFFFF3D00),
    );

    final midFlame = Path()
      ..moveTo(size.width * 0.28, size.height - 4)
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.45,
        size.width * 0.5,
        size.height * (0.15 + progress * 0.15),
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.45,
        size.width * 0.72,
        size.height - 4,
      )
      ..close();

    canvas.drawPath(
      midFlame,
      Paint()..color = const Color(0xFFFFD600),
    );

    final innerFlame = Path()
      ..moveTo(size.width * 0.38, size.height - 4)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.65,
        size.width * 0.5,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.65,
        size.height * 0.65,
        size.width * 0.62,
        size.height - 4,
      )
      ..close();

    canvas.drawPath(
      innerFlame,
      Paint()..color = const Color(0xFF00E5FF),
    );
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _VaporPainter extends CustomPainter {
  final double progress;
  final bool isSulfur;

  _VaporPainter({
    required this.progress,
    required this.isSulfur,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(42);

    for (int i = 0; i < 7; i++) {
      final double waveOffset = sin((progress * 2 * pi) + i) * 5.0;
      final double x =
          (size.width * 0.2) + (rand.nextDouble() * size.width * 0.6) + waveOffset;
      final double y =
          size.height - (progress * size.height * 0.95) - (i * 4.0);
      final double radius = 3.5 + (rand.nextDouble() * 3.5);

      if (y < 0) continue;

      final double alphaProgress = (1.0 - (y / size.height)).clamp(0.0, 1.0);
      final int alpha = (240 * (1.0 - alphaProgress)).toInt().clamp(0, 255);

      final color = isSulfur
          ? const Color(0xFFFFB300).withAlpha(alpha)
          : const Color(0xFFCFD8DC).withAlpha(alpha);

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color,
      );

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = (isSulfur ? const Color(0xFFF57F17) : const Color(0xFF90A4AE))
              .withAlpha(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VaporPainter oldDelegate) =>
      oldDelegate.progress != progress;
}