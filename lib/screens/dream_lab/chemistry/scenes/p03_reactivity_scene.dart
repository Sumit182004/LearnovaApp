import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/practical_model.dart';

class P03ReactivityScene extends StatefulWidget {
  final Practical practical;

  const P03ReactivityScene({
    super.key,
    required this.practical,
  });

  @override
  State<P03ReactivityScene> createState() => _P03ReactivitySceneState();
}

class _P03ReactivitySceneState extends State<P03ReactivityScene>
    with TickerProviderStateMixin {
  AnimationController? _bubbleController;
  AnimationController? _particlesController;
  AnimationController? _reactionAnimController;

  final List<String> tubeKeys = ["Tube 1", "Tube 2", "Tube 3", "Tube 4"];
  final Map<String, String> defaultSolutions = {
    "Tube 1": "ZnSO₄",
    "Tube 2": "FeSO₄",
    "Tube 3": "CuSO₄",
    "Tube 4": "Al₂(SO₄)₃",
  };

  final Map<String, Color> initialColors = {
    "Tube 1": const Color(0x3300BCD4),
    "Tube 2": const Color(0xB381C784),
    "Tube 3": const Color(0xF00288D1),
    "Tube 4": const Color(0x3380DEEA),
  };

  final Map<String, String?> addedMetal = {
    "Tube 1": null,
    "Tube 2": null,
    "Tube 3": null,
    "Tube 4": null,
  };

  final Map<String, bool> displacementOccurred = {
    "Tube 1": false,
    "Tube 2": false,
    "Tube 3": false,
    "Tube 4": false,
  };

  String activeTube = "Tube 3";
  String observation =
      "Drag or tap a metal (Zn, Fe, Cu, Al) into any salt solution.";

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _bubbleController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _particlesController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _reactionAnimController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    _initControllers();
  }

  @override
  void dispose() {
    _bubbleController?.dispose();
    _particlesController?.dispose();
    _reactionAnimController?.dispose();
    super.dispose();
  }

  int _reactivityIndex(String metal) {
    switch (metal) {
      case "Al":
        return 4;
      case "Zn":
        return 3;
      case "Fe":
        return 2;
      case "Cu":
        return 1;
      default:
        return 0;
    }
  }

  int _saltMetalIndex(String salt) {
    switch (salt) {
      case "Al₂(SO₄)₃":
        return 4;
      case "ZnSO₄":
        return 3;
      case "FeSO₄":
        return 2;
      case "CuSO₄":
        return 1;
      default:
        return 0;
    }
  }

  void _addMetalToTube(String metal, String targetTube) {
    _initControllers();
    final salt = defaultSolutions[targetTube]!;
    final metalRank = _reactivityIndex(metal);
    final saltRank = _saltMetalIndex(salt);

    setState(() {
      activeTube = targetTube;
      addedMetal[targetTube] = metal;

      if (metalRank > saltRank) {
        displacementOccurred[targetTube] = true;
        _reactionAnimController?.forward(from: 0.0);

        if (salt == "CuSO₄") {
          observation =
          "$metal is more reactive than Cu. Blue CuSO₄ fades; reddish-brown Cu coats $metal.";
        } else if (salt == "FeSO₄") {
          observation =
          "$metal displaces iron from pale green FeSO₄. Grey-black iron deposits on $metal.";
        } else if (salt == "ZnSO₄") {
          observation =
          "$metal displaces zinc from ZnSO₄ solution. Zinc deposits on $metal.";
        } else {
          observation =
          "Displacement reaction occurred: $metal displaced metal from $salt.";
        }
      } else {
        displacementOccurred[targetTube] = false;
        _reactionAnimController?.forward(from: 0.0);
        observation =
        "No reaction: $metal is less reactive than the metal in $salt solution.";
      }
    });
  }

  void _resetLab() {
    setState(() {
      for (final key in tubeKeys) {
        addedMetal[key] = null;
        displacementOccurred[key] = false;
      }
      activeTube = "Tube 3";
      observation =
      "Experiment reset. Solutions are fresh and ready for metal testing.";
    });
    _reactionAnimController?.reset();
  }

  @override
  Widget build(BuildContext context) {
    _initControllers();

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
    final saltName = defaultSolutions[tubeKey]!;
    final metal = addedMetal[tubeKey];
    final isDisplaced = displacementOccurred[tubeKey] == true;

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        _addMetalToTube(details.data, tubeKey);
      },
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;

        return GestureDetector(
          onTap: () {
            setState(() {
              activeTube = tubeKey;
              observation =
              "Selected $tubeKey ($saltName). Pick a metal to test displacement.";
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
                              if (_reactionAnimController != null)
                                AnimatedBuilder(
                                  animation: _reactionAnimController!,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      size: Size(tubeWidth, tubeHeight),
                                      painter: _ReactivityTubePainter(
                                        tubeKey: tubeKey,
                                        initialColor: initialColors[tubeKey]!,
                                        isDisplaced: isDisplaced,
                                        animProgress:
                                        _reactionAnimController!.value,
                                      ),
                                    );
                                  },
                                ),
                              if (metal != null && _reactionAnimController != null)
                                AnimatedBuilder(
                                  animation: _reactionAnimController!,
                                  builder: (context, child) {
                                    final progress =
                                        _reactionAnimController!.value;
                                    final double dropOffset =
                                        (1.0 - progress) * -16.0;

                                    Color stripColor = _metalBaseColor(metal);
                                    if (isDisplaced) {
                                      final coatedColor = saltName == "CuSO₄"
                                          ? const Color(0xFFD84315)
                                          : const Color(0xFF37474F);
                                      stripColor = Color.lerp(
                                          stripColor, coatedColor, progress)!;
                                    }

                                    return Positioned(
                                      bottom: 5 + dropOffset,
                                      child: Transform.rotate(
                                        angle: -0.16,
                                        child: Container(
                                          width: 6.5,
                                          height: tubeHeight * 0.46,
                                          decoration: BoxDecoration(
                                            color: stripColor,
                                            borderRadius:
                                            BorderRadius.circular(1.8),
                                            border: Border.all(
                                              color: Colors.white30,
                                              width: 0.8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: stripColor.withValues(
                                                    alpha: isDisplaced ? 0.6 : 0.2),
                                                blurRadius: isDisplaced ? 5 : 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              if (isDisplaced && _bubbleController != null)
                                Positioned(
                                  bottom: 4,
                                  child: SizedBox(
                                    width: tubeWidth - 4,
                                    height: tubeHeight * 0.54,
                                    child: AnimatedBuilder(
                                      animation: _bubbleController!,
                                      builder: (context, child) {
                                        return CustomPaint(
                                          painter: _ReactivityBubblePainter(
                                            progress:
                                            _bubbleController!.value,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              if (isDisplaced && _particlesController != null)
                                Positioned(
                                  bottom: 4,
                                  child: SizedBox(
                                    width: tubeWidth - 6,
                                    height: 18,
                                    child: AnimatedBuilder(
                                      animation: _particlesController!,
                                      builder: (context, child) {
                                        return CustomPaint(
                                          painter: _PrecipitateFlakesPainter(
                                            progress:
                                            _particlesController!.value,
                                            isCopper: saltName == "CuSO₄",
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
                      metal != null ? "$saltName + $metal" : saltName,
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

  Color _metalBaseColor(String metal) {
    switch (metal) {
      case "Al":
        return const Color(0xFFCFD8DC);
      case "Zn":
        return const Color(0xFF90A4AE);
      case "Fe":
        return const Color(0xFF546E7A);
      case "Cu":
        return const Color(0xFFFF7043);
      default:
        return Colors.grey;
    }
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
                  _metalChip("Zn", "Zinc metal", const Color(0xFF90A4AE)),
                  _metalChip("Fe", "Iron metal", const Color(0xFF546E7A)),
                  _metalChip("Cu", "Copper metal", const Color(0xFFFF7043)),
                  _metalChip("Al", "Aluminium metal", const Color(0xFFCFD8DC)),
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

  Widget _metalChip(String symbol, String label, Color color) {
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
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            symbol,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    return Draggable<String>(
      data: symbol,
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
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                "$symbol ($label)",
                style: const TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: chip),
      child: InkWell(
        onTap: () => _addMetalToTube(symbol, activeTube),
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

class _ReactivityTubePainter extends CustomPainter {
  final String tubeKey;
  final Color initialColor;
  final bool isDisplaced;
  final double animProgress;

  _ReactivityTubePainter({
    required this.tubeKey,
    required this.initialColor,
    required this.isDisplaced,
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

    Color finalColor = initialColor;
    if (tubeKey == "Tube 3" && isDisplaced) {
      finalColor = const Color(0x6681C784);
    } else if (tubeKey == "Tube 2" && isDisplaced) {
      finalColor = const Color(0x1F80CBC4);
    }

    final color = isDisplaced
        ? Color.lerp(initialColor, finalColor, animProgress)!
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
  bool shouldRepaint(covariant _ReactivityTubePainter oldDelegate) {
    return oldDelegate.tubeKey != tubeKey ||
        oldDelegate.initialColor != initialColor ||
        oldDelegate.isDisplaced != isDisplaced ||
        oldDelegate.animProgress != animProgress;
  }
}

class _ReactivityBubblePainter extends CustomPainter {
  final double progress;

  _ReactivityBubblePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(42);

    for (int i = 0; i < 7; i++) {
      final double waveOffset = sin((progress * 2 * pi) + i) * 3.5;
      final double x =
          (size.width * 0.2) + (rand.nextDouble() * size.width * 0.6) + waveOffset;
      final double y = size.height - (progress * size.height * 0.85) - (i * 3.5);
      final double radius = 1.2 + (rand.nextDouble() * 1.5);

      if (y < 0) continue;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..color = Colors.white.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReactivityBubblePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _PrecipitateFlakesPainter extends CustomPainter {
  final double progress;
  final bool isCopper;

  _PrecipitateFlakesPainter({
    required this.progress,
    required this.isCopper,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(99);
    final flakeColor = isCopper ? const Color(0xFFD84315) : const Color(0xFF37474F);

    for (int i = 0; i < 5; i++) {
      final double x = (size.width * 0.25) + (rand.nextDouble() * size.width * 0.5);
      final double y = (progress * size.height * 0.7) + (rand.nextDouble() * 4);

      canvas.drawCircle(
        Offset(x, y.clamp(0.0, size.height)),
        1.5,
        Paint()..color = flakeColor.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PrecipitateFlakesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}