import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/practical_model.dart';

class P10FocalLengthScene extends StatefulWidget {
  final Practical practical;

  const P10FocalLengthScene({
    super.key,
    required this.practical,
  });

  @override
  State<P10FocalLengthScene> createState() => _P10FocalLengthSceneState();
}

class _P10FocalLengthSceneState extends State<P10FocalLengthScene> {
  bool isMirrorMode = true; // true = Concave Mirror, false = Convex Lens

  // True physical focal length of the optical element
  final double trueFocalLength = 15.0; // 15.0 cm

  // Current screen position along the optical bench (cm)
  double screenPosition = 22.0;

  final List<Map<String, dynamic>> recordedReadings = [];
  String observation =
      "Move the screen slider to obtain a sharp, inverted image of the distant object.";

  // Blur amount is zero when screenPosition == trueFocalLength
  double get focusError => (screenPosition - trueFocalLength).abs();
  bool get isSharpFocus => focusError < 0.5;

  void _switchOpticsMode(bool mirror) {
    if (isMirrorMode == mirror) return;
    setState(() {
      isMirrorMode = mirror;
      screenPosition = 22.0;
      observation = mirror
          ? "Concave Mirror selected. Move the screen in front to capture reflected rays."
          : "Convex Lens selected. Move the screen behind the lens to capture refracted rays.";
    });
  }

  void _recordMeasurement() {
    if (!isSharpFocus) {
      setState(() {
        observation =
        "The image is still blurred (error: ${focusError.toStringAsFixed(1)} cm). Adjust to sharpest focus first!";
      });
      return;
    }

    final mode = isMirrorMode ? "Concave Mirror" : "Convex Lens";
    setState(() {
      recordedReadings.add({
        "Mode": mode,
        "ScreenPos": double.parse(screenPosition.toStringAsFixed(1)),
        "FocalLength": double.parse(screenPosition.toStringAsFixed(1)),
      });
      observation =
      "Sharp image confirmed for $mode! Measured approximate focal length f ≈ ${screenPosition.toStringAsFixed(1)} cm.";
    });
  }

  void _resetLab() {
    setState(() {
      isMirrorMode = true;
      screenPosition = 22.0;
      recordedReadings.clear();
      observation =
      "Bench reset. Slide screen to find the principal focus position.";
    });
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
            child: _buildWorkspace(),
          ),
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
          // Left: Optical Bench Simulation
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RayOpticsPainter(
                      isMirror: isMirrorMode,
                      screenDistance: screenPosition,
                      focalLength: trueFocalLength,
                    ),
                  ),
                ),
                _buildBenchComponents(),
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

          // Right: Screen Image Preview & Observation Data
          Expanded(
            flex: 4,
            child: _buildScreenPreviewAndLogPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchComponents() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final opticX = w * 0.46;
        final double screenX = isMirrorMode
            ? opticX - (screenPosition * (w * 0.015))
            : opticX + (screenPosition * (w * 0.015));

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: w * 0.03,
              top: h * 0.24,
              child: _distantObjectBanner(),
            ),
            Positioned(
              left: w * 0.08,
              right: w * 0.08,
              bottom: h * 0.22,
              child: _metreScaleBar(),
            ),
            Positioned(
              left: opticX - 22,
              bottom: h * 0.22,
              child: _opticalElementStand(),
            ),
            Positioned(
              left: screenX.clamp(w * 0.12, w * 0.88) - 18,
              bottom: h * 0.22,
              child: _movableScreenStand(),
            ),
          ],
        );
      },
    );
  }

  Widget _distantObjectBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xff1A173B),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.park, size: 20, color: Colors.greenAccent),
          Text(
            "Distant Tree\n(at infinity)",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _metreScaleBar() {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xff1E1942),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          12,
              (i) => Text(
            "${i * 5}",
            style: const TextStyle(fontSize: 6.5, color: Colors.white60),
          ),
        ),
      ),
    );
  }

  Widget _opticalElementStand() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 56,
          decoration: BoxDecoration(
            color: isMirrorMode ? const Color(0xff1E1942) : const Color(0x3300BCD4),
            borderRadius: BorderRadius.circular(isMirrorMode ? 4 : 20),
            border: Border.all(
              color: isMirrorMode ? Colors.purpleAccent : Colors.cyanAccent,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isMirrorMode ? Colors.purpleAccent : Colors.cyanAccent)
                    .withOpacity(0.2),
                blurRadius: 6,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            isMirrorMode ? "Concave\nMirror" : "Convex\nLens",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
              color: isMirrorMode ? Colors.white : Colors.cyanAccent,
            ),
          ),
        ),
        Container(
          width: 12,
          height: 18,
          color: const Color(0xff2A1B54),
        ),
        Container(
          width: 32,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xff1A173B),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _movableScreenStand() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xff1A173B),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: isSharpFocus ? Colors.greenAccent : Colors.white24,
              width: isSharpFocus ? 2.0 : 1.2,
            ),
            boxShadow: [
              if (isSharpFocus)
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.35),
                  blurRadius: 8,
                ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Screen",
                style: TextStyle(
                    fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                "${screenPosition.toStringAsFixed(1)} cm",
                style: TextStyle(
                  fontSize: 7.0,
                  fontWeight: FontWeight.bold,
                  color: isSharpFocus ? Colors.greenAccent : Colors.white60,
                ),
              ),
            ],
          ),
        ),
        Container(width: 8, height: 22, color: const Color(0xff2A1B54)),
        Container(
          width: 26,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xff1A173B),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenPreviewAndLogPanel() {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Screen Image Preview",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 72,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xff1A173B).withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSharpFocus ? Colors.greenAccent : Colors.white.withOpacity(0.08),
                width: isSharpFocus ? 1.5 : 1.0,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: pi,
                  child: Opacity(
                    opacity: (1.0 - (focusError * 0.08)).clamp(0.25, 1.0),
                    child: ImageFiltered(
                      imageFilter: ColorFilter.mode(
                        Colors.black.withOpacity((focusError * 0.04).clamp(0.0, 0.4)),
                        BlendMode.darken,
                      ),
                      child: Icon(
                        Icons.park,
                        size: isSharpFocus ? 36 : (36 + focusError * 2.0).clamp(36.0, 56.0),
                        color: isSharpFocus
                            ? Colors.greenAccent
                            : Colors.green.shade200.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSharpFocus ? const Color(0xff1E1942) : const Color(0xff2A1B54),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      isSharpFocus
                          ? "Sharp Inverted Image (In Focus!)"
                          : "Blurry Image (Adjust Slider)",
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        color: isSharpFocus ? Colors.greenAccent : Colors.orangeAccent,
                      ),
                    ),
                  ),
                ),
              ],
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
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    color: const Color(0xff1E1942),
                    child: Row(
                      children: const [
                        Expanded(
                            flex: 2,
                            child: Center(
                                child: Text("No.",
                                    style: TextStyle(
                                        fontSize: 7.2,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.cyanAccent)))),
                        Expanded(
                            flex: 4,
                            child: Center(
                                child: Text("Device",
                                    style: TextStyle(
                                        fontSize: 7.2,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.cyanAccent)))),
                        Expanded(
                            flex: 3,
                            child: Center(
                                child: Text("v (cm)",
                                    style: TextStyle(
                                        fontSize: 7.2,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.cyanAccent)))),
                        Expanded(
                            flex: 3,
                            child: Center(
                                child: Text("f (cm)",
                                    style: TextStyle(
                                        fontSize: 7.2,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.cyanAccent)))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: recordedReadings.isEmpty
                        ? const Center(
                      child: Text(
                        "Obtain focus & record readings",
                        style: TextStyle(fontSize: 8, color: Colors.white38),
                      ),
                    )
                        : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: recordedReadings.length,
                      itemBuilder: (context, i) {
                        final r = recordedReadings[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 2.0, horizontal: 2),
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 2,
                                  child: Center(
                                      child: Text("${i + 1}",
                                          style: const TextStyle(
                                              fontSize: 7.2,
                                              color: Colors.white70)))),
                              Expanded(
                                  flex: 4,
                                  child: Center(
                                      child: Text("${r['Mode']}",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 7.2,
                                              color: Colors.white60)))),
                              Expanded(
                                  flex: 3,
                                  child: Center(
                                      child: Text("${r['ScreenPos']}",
                                          style: const TextStyle(
                                              fontSize: 7.2,
                                              color: Colors.white60)))),
                              Expanded(
                                flex: 3,
                                child: Center(
                                  child: Text(
                                    "${r['FocalLength']}",
                                    style: const TextStyle(
                                      fontSize: 7.2,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.greenAccent,
                                    ),
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
          const Icon(Icons.visibility_outlined, size: 13, color: Colors.cyanAccent),
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
            Container(
              decoration: BoxDecoration(
                color: const Color(0xff1A173B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _modeButton(
                      "Concave Mirror", isMirrorMode, () => _switchOpticsMode(true)),
                  _modeButton(
                      "Convex Lens", !isMirrorMode, () => _switchOpticsMode(false)),
                ],
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 140,
              child: Row(
                children: [
                  const Text(
                    "Pos:",
                    style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                        overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 8),
                      ),
                      child: Slider(
                        value: screenPosition,
                        min: 5.0,
                        max: 30.0,
                        activeColor: isSharpFocus
                            ? Colors.greenAccent
                            : const Color(0xff6C5CE7),
                        inactiveColor: Colors.white12,
                        onChanged: (val) {
                          setState(() {
                            screenPosition = val;
                          });
                        },
                      ),
                    ),
                  ),
                  Text(
                    "${screenPosition.toStringAsFixed(1)}",
                    style: TextStyle(
                      fontSize: 8.0,
                      fontWeight: FontWeight.bold,
                      color: isSharpFocus ? Colors.greenAccent : Colors.cyanAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton.icon(
              onPressed: _recordMeasurement,
              icon: const Icon(Icons.bookmark_add_outlined, size: 12),
              label: const Text(
                "Record f",
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSharpFocus
                    ? const Color(0xff2E7D32)
                    : const Color(0xff6C5CE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 5),
            OutlinedButton.icon(
              onPressed: _resetLab,
              icon: const Icon(Icons.refresh, size: 12),
              label: const Text(
                "Reset",
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withOpacity(0.15)),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff6C5CE7) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }
}

class _RayOpticsPainter extends CustomPainter {
  final bool isMirror;
  final double screenDistance;
  final double focalLength;

  _RayOpticsPainter({
    required this.isMirror,
    required this.screenDistance,
    required this.focalLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final incidentPaint = Paint()
      ..color = Colors.amberAccent.withOpacity(0.8)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final focusedRayPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.85)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final opticX = w * 0.46;
    final opticCenterY = h * 0.50;

    canvas.drawLine(
      Offset(w * 0.05, opticCenterY),
      Offset(w * 0.95, opticCenterY),
      Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..strokeWidth = 0.8,
    );

    final y1 = opticCenterY - 18;
    final y2 = opticCenterY + 18;

    canvas.drawLine(Offset(w * 0.08, y1), Offset(opticX, y1), incidentPaint);
    canvas.drawLine(Offset(w * 0.08, y2), Offset(opticX, y2), incidentPaint);

    final focusX = isMirror
        ? opticX - (focalLength * (w * 0.015))
        : opticX + (focalLength * (w * 0.015));

    canvas.drawLine(
        Offset(opticX, y1), Offset(focusX, opticCenterY), focusedRayPaint);
    canvas.drawLine(
        Offset(opticX, y2), Offset(focusX, opticCenterY), focusedRayPaint);

    canvas.drawCircle(
        Offset(focusX, opticCenterY), 2.5, Paint()..color = Colors.cyanAccent);
  }

  @override
  bool shouldRepaint(covariant _RayOpticsPainter oldDelegate) =>
      oldDelegate.isMirror != isMirror ||
          oldDelegate.screenDistance != screenDistance ||
          oldDelegate.focalLength != focalLength;
}