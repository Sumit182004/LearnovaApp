import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/practical_model.dart';

class P13PrismScene extends StatefulWidget {
  final Practical practical;

  const P13PrismScene({
    super.key,
    required this.practical,
  });

  @override
  State<P13PrismScene> createState() => _P13PrismSceneState();
}

class _P13PrismSceneState extends State<P13PrismScene>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  // Prism parameters
  final double prismAngleA = 60.0; // Equilateral Glass Prism (degrees)
  final double refractiveIndexMu = 1.50; // Crown glass

  // User controllable state
  double angleOfIncidenceI = 42.0; // Typical range 30° to 65°
  bool showDispersion = false; // Toggle monochromatic laser vs white light dispersion
  bool showPins = true;
  bool showProtractor = false;

  final List<Map<String, dynamic>> recordedReadings = [];
  String observation =
      "Adjust angle of incidence (i) to observe deviation of light through the glass prism.";

  // Optics calculations
  double get angleR1 {
    final radI = angleOfIncidenceI * pi / 180.0;
    final radR1 = asin((sin(radI) / refractiveIndexMu).clamp(-1.0, 1.0));
    return radR1 * 180.0 / pi;
  }

  double get angleR2 => prismAngleA - angleR1;

  double get angleOfEmergenceE {
    final radR2 = angleR2 * pi / 180.0;
    final sinE = refractiveIndexMu * sin(radR2);
    if (sinE.abs() > 1.0) {
      return 90.0; // Total Internal Reflection limit
    }
    return asin(sinE) * 180.0 / pi;
  }

  double get angleOfDeviationD {
    return angleOfIncidenceI + angleOfEmergenceE - prismAngleA;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _recordReading() {
    final iVal = double.parse(angleOfIncidenceI.toStringAsFixed(1));
    final eVal = double.parse(angleOfEmergenceE.toStringAsFixed(1));
    final dVal = double.parse(angleOfDeviationD.toStringAsFixed(1));

    final alreadyExists =
    recordedReadings.any((r) => (r["i"] - iVal).abs() < 1.0);

    if (alreadyExists) {
      setState(() {
        observation =
        "Reading already recorded for i = $iVal°. Select a different angle.";
      });
      return;
    }

    setState(() {
      recordedReadings.add({
        "i": iVal,
        "e": eVal,
        "A": prismAngleA.toStringAsFixed(0),
        "D": dVal,
      });
      observation =
      "Recorded: ∠i = $iVal°, ∠e = $eVal°, Angle of Deviation ∠D = $dVal° (Verified: i + e = A + D).";
    });
  }

  void _resetLab() {
    setState(() {
      angleOfIncidenceI = 42.0;
      showDispersion = false;
      showPins = true;
      showProtractor = false;
      recordedReadings.clear();
      observation =
      "Prism desk reset. Adjust incidence angle and measure ray deviation.";
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
          // Left: Interactive Prism Ray Tracing Canvas
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _PrismOpticsPainter(
                          angleOfIncidence: angleOfIncidenceI,
                          angleR1: angleR1,
                          angleR2: angleR2,
                          angleOfEmergence: angleOfEmergenceE,
                          angleOfDeviation: angleOfDeviationD,
                          showDispersion: showDispersion,
                          showPins: showPins,
                          pulseValue: _pulseController.value,
                        ),
                      );
                    },
                  ),
                ),
                _buildSheetBadge(),
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

          // Right: Measured Angles & Deviation Log
          Expanded(
            flex: 4,
            child: _buildAnglesAndDataPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetBadge() {
    return Positioned(
      top: 6,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xff1A173B).withOpacity(0.85),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
        ),
        child: Row(
          children: [
            const Icon(Icons.change_history, size: 13, color: Colors.cyanAccent),
            const SizedBox(width: 4),
            Text(
              "Equilateral Prism • A = 60° (μ = $refractiveIndexMu)",
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnglesAndDataPanel() {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Prism Angles & Deviation Log",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),

          // Real-time Angle Badges
          Row(
            children: [
              _angleCard("∠i", "${angleOfIncidenceI.toStringAsFixed(1)}°", const Color(0xffFF5252)),
              const SizedBox(width: 3),
              _angleCard("∠e", "${angleOfEmergenceE.toStringAsFixed(1)}°", Colors.greenAccent),
              const SizedBox(width: 3),
              _angleCard("∠A", "60.0°", Colors.cyanAccent),
              const SizedBox(width: 3),
              _angleCard("∠D (Dev)", "${angleOfDeviationD.toStringAsFixed(1)}°", Colors.purpleAccent),
            ],
          ),
          const SizedBox(height: 4),

          // Observation Table
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
                        Expanded(flex: 2, child: Center(child: Text("No.", style: TextStyle(fontSize: 7.2, fontWeight: FontWeight.bold, color: Colors.cyanAccent)))),
                        Expanded(flex: 2, child: Center(child: Text("∠i", style: TextStyle(fontSize: 7.2, fontWeight: FontWeight.bold, color: Colors.cyanAccent)))),
                        Expanded(flex: 2, child: Center(child: Text("∠e", style: TextStyle(fontSize: 7.2, fontWeight: FontWeight.bold, color: Colors.cyanAccent)))),
                        Expanded(flex: 2, child: Center(child: Text("∠A", style: TextStyle(fontSize: 7.2, fontWeight: FontWeight.bold, color: Colors.cyanAccent)))),
                        Expanded(flex: 2, child: Center(child: Text("∠D", style: TextStyle(fontSize: 7.2, fontWeight: FontWeight.bold, color: Colors.cyanAccent)))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: recordedReadings.isEmpty
                        ? const Center(
                      child: Text(
                        "Change ∠i and record readings",
                        style: TextStyle(fontSize: 8, color: Colors.white38),
                      ),
                    )
                        : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: recordedReadings.length,
                      itemBuilder: (context, i) {
                        final r = recordedReadings[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Center(child: Text("${i + 1}", style: const TextStyle(fontSize: 7.2, color: Colors.white70)))),
                              Expanded(flex: 2, child: Center(child: Text("${r['i']}°", style: const TextStyle(fontSize: 7.2, color: Colors.white60)))),
                              Expanded(flex: 2, child: Center(child: Text("${r['e']}°", style: const TextStyle(fontSize: 7.2, color: Colors.white60)))),
                              Expanded(flex: 2, child: Center(child: Text("${r['A']}°", style: const TextStyle(fontSize: 7.2, color: Colors.white38)))),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(
                                    "${r['D']}°",
                                    style: const TextStyle(
                                      fontSize: 7.2,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purpleAccent,
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

  Widget _angleCard(String title, String val, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xff1A173B),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: accent.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 6.8, fontWeight: FontWeight.bold, color: accent),
            ),
            const SizedBox(height: 1),
            Text(
              val,
              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
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
            // Incidence Angle Slider
            SizedBox(
              width: 160,
              child: Row(
                children: [
                  const Text(
                    "∠i:",
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                      ),
                      child: Slider(
                        value: angleOfIncidenceI,
                        min: 30.0,
                        max: 65.0,
                        activeColor: const Color(0xff6C5CE7),
                        inactiveColor: Colors.white12,
                        onChanged: (val) {
                          setState(() {
                            angleOfIncidenceI = val;
                            observation =
                            "∠i = ${val.toStringAsFixed(1)}°. Angle of Deviation ∠D is ${angleOfDeviationD.toStringAsFixed(1)}°.";
                          });
                        },
                      ),
                    ),
                  ),
                  Text(
                    "${angleOfIncidenceI.toStringAsFixed(1)}°",
                    style: const TextStyle(
                      fontSize: 8.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // Toggle White Light Dispersion Button
            OutlinedButton.icon(
              onPressed: () => setState(() => showDispersion = !showDispersion),
              icon: Icon(
                Icons.auto_awesome,
                size: 13,
                color: showDispersion ? Colors.cyanAccent : Colors.white38,
              ),
              label: Text(
                showDispersion ? "VIBGYOR" : "Laser",
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: showDispersion ? Colors.cyanAccent : Colors.white60,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                side: BorderSide(
                  color: showDispersion ? Colors.cyanAccent : Colors.white24,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
            ),
            const SizedBox(width: 5),

            // Toggle Optical Pins
            OutlinedButton(
              onPressed: () => setState(() => showPins = !showPins),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                side: BorderSide(
                  color: showPins ? Colors.purpleAccent : Colors.white24,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
              child: Text(
                showPins ? "Pins ON" : "Pins OFF",
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: showPins ? Colors.purpleAccent : Colors.white38,
                ),
              ),
            ),
            const SizedBox(width: 5),

            // Record Angles
            ElevatedButton.icon(
              onPressed: _recordReading,
              icon: const Icon(Icons.bookmark_add_outlined, size: 12),
              label: const Text(
                "Record",
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff6C5CE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 5),

            // Reset
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Painter for Equilateral Prism Ray Tracing ---

class _PrismOpticsPainter extends CustomPainter {
  final double angleOfIncidence;
  final double angleR1;
  final double angleR2;
  final double angleOfEmergence;
  final double angleOfDeviation;
  final bool showDispersion;
  final bool showPins;
  final double pulseValue;

  _PrismOpticsPainter({
    required this.angleOfIncidence,
    required this.angleR1,
    required this.angleR2,
    required this.angleOfEmergence,
    required this.angleOfDeviation,
    required this.showDispersion,
    required this.showPins,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- 1. Equilateral Triangle Prism Geometry ---
    final apexA = Offset(w * 0.48, h * 0.20);
    final baseB = Offset(w * 0.28, h * 0.78);
    final baseC = Offset(w * 0.68, h * 0.78);

    final prismPath = Path()
      ..moveTo(apexA.dx, apexA.dy)
      ..lineTo(baseC.dx, baseC.dy)
      ..lineTo(baseB.dx, baseB.dy)
      ..close();

    // Prism Drop Shadow
    canvas.drawPath(
      prismPath.shift(const Offset(3, 5)),
      Paint()
        ..color = Colors.purple.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Glass Shading Fill
    final prismShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xff1E1942).withOpacity(0.7),
        const Color(0x3300E5FF),
        const Color(0xff121026).withOpacity(0.8),
      ],
    ).createShader(Rect.fromPoints(baseB, Offset(baseC.dx, apexA.dy)));

    canvas.drawPath(prismPath, Paint()..shader = prismShader);

    // Beveled Prism Glass Border
    canvas.drawPath(
      prismPath,
      Paint()
        ..color = Colors.cyanAccent.withOpacity(0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Vertices Labels A, B, C
    _drawText(canvas, "A (60°)", Offset(apexA.dx - 12, apexA.dy - 14), color: Colors.cyanAccent);
    _drawText(canvas, "B", Offset(baseB.dx - 14, baseB.dy - 4), color: Colors.white54);
    _drawText(canvas, "C", Offset(baseC.dx + 6, baseC.dy - 4), color: Colors.white54);

    // --- 2. Surface AB Incident Point (O) ---
    final pointO = Offset(
      apexA.dx + (baseB.dx - apexA.dx) * 0.52,
      apexA.dy + (baseB.dy - apexA.dy) * 0.52,
    );

    final faceABAngle = atan2(baseB.dy - apexA.dy, baseB.dx - apexA.dx);
    final normalABAngle = faceABAngle - (pi / 2);

    final radI = angleOfIncidence * pi / 180.0;
    final incidentRayAngle = normalABAngle + radI;

    final rayLen = h * 0.32;
    final laserGunPos = Offset(
      pointO.dx - (rayLen * cos(incidentRayAngle)),
      pointO.dy - (rayLen * sin(incidentRayAngle)),
    );

    // 2a. Draw Incident Normal N1 - N1'
    final normal1Len = 32.0;
    canvas.drawLine(
      Offset(pointO.dx - normal1Len * cos(normalABAngle), pointO.dy - normal1Len * sin(normalABAngle)),
      Offset(pointO.dx + normal1Len * cos(normalABAngle), pointO.dy + normal1Len * sin(normalABAngle)),
      Paint()..color = Colors.white30..strokeWidth = 0.9,
    );
    _drawText(canvas, "N₁", Offset(pointO.dx - normal1Len * cos(normalABAngle) - 12, pointO.dy - normal1Len * sin(normalABAngle) - 6), color: Colors.white38);

    // 2b. Draw Incident Ray
    _drawLaserBeam(canvas, laserGunPos, pointO, isWhiteLight: showDispersion);

    // --- 3. Refracted Ray inside Glass ---
    final pointOPrime = Offset(
      apexA.dx + (baseC.dx - apexA.dx) * 0.54,
      apexA.dy + (baseC.dy - apexA.dy) * 0.54,
    );

    if (!showDispersion) {
      _drawLaserBeam(canvas, pointO, pointOPrime, isDenseMedium: true);
    } else {
      _drawSpectrumFan(canvas, pointO, pointOPrime);
    }

    // --- 4. Surface AC Emergent Ray ---
    final faceACAngle = atan2(baseC.dy - apexA.dy, baseC.dx - apexA.dx);
    final normalACAngle = faceACAngle + (pi / 2);

    final radE = angleOfEmergence * pi / 180.0;
    final emergentRayAngle = normalACAngle + radE - 0.22;

    final emergentLen = h * 0.30;
    final endEmergent = Offset(
      pointOPrime.dx + (emergentLen * cos(emergentRayAngle)),
      pointOPrime.dy + (emergentLen * sin(emergentRayAngle)),
    );

    // Emergent Normal N2 - N2'
    canvas.drawLine(
      Offset(pointOPrime.dx - normal1Len * cos(normalACAngle), pointOPrime.dy - normal1Len * sin(normalACAngle)),
      Offset(pointOPrime.dx + normal1Len * cos(normalACAngle), pointOPrime.dy + normal1Len * sin(normalACAngle)),
      Paint()..color = Colors.white30..strokeWidth = 0.9,
    );
    _drawText(canvas, "N₂", Offset(pointOPrime.dx + normal1Len * cos(normalACAngle) + 4, pointOPrime.dy - normal1Len * sin(normalACAngle) - 6), color: Colors.white38);

    if (!showDispersion) {
      _drawLaserBeam(canvas, pointOPrime, endEmergent);
    } else {
      _drawSpectrumEmergence(canvas, pointOPrime, emergentLen, emergentRayAngle);
    }

    // --- 5. Virtual Extensions & Angle of Deviation ∠D ---
    final forwardIncidentEnd = Offset(
      pointO.dx + (rayLen * 1.35 * cos(incidentRayAngle)),
      pointO.dy + (rayLen * 1.35 * sin(incidentRayAngle)),
    );
    _drawDashedLine(canvas, pointO, forwardIncidentEnd, Paint()..color = Colors.white24..strokeWidth = 1.0);

    final backwardEmergentEnd = Offset(
      pointOPrime.dx - (emergentLen * 1.15 * cos(emergentRayAngle)),
      pointOPrime.dy - (emergentLen * 1.15 * sin(emergentRayAngle)),
    );
    _drawDashedLine(canvas, pointOPrime, backwardEmergentEnd, Paint()..color = Colors.purpleAccent.withOpacity(0.8)..strokeWidth = 1.0);

    final intersectionG = Offset(w * 0.54, h * 0.44);
    _drawText(canvas, "∠D", Offset(intersectionG.dx + 4, intersectionG.dy - 14), color: Colors.purpleAccent);

    _drawOpticalSpot(canvas, pointO);
    _drawOpticalSpot(canvas, pointOPrime);

    // --- 6. Optical Alignment Pins ---
    if (showPins) {
      final p1 = Offset(laserGunPos.dx + (pointO.dx - laserGunPos.dx) * 0.28, laserGunPos.dy + (pointO.dy - laserGunPos.dy) * 0.28);
      final p2 = Offset(laserGunPos.dx + (pointO.dx - laserGunPos.dx) * 0.72, laserGunPos.dy + (pointO.dy - laserGunPos.dy) * 0.72);
      final p3 = Offset(pointOPrime.dx + (endEmergent.dx - pointOPrime.dx) * 0.32, pointOPrime.dy + (endEmergent.dy - pointOPrime.dy) * 0.32);
      final p4 = Offset(pointOPrime.dx + (endEmergent.dx - pointOPrime.dx) * 0.76, pointOPrime.dy + (endEmergent.dy - pointOPrime.dy) * 0.76);

      _drawPin(canvas, p1, "P₁");
      _drawPin(canvas, p2, "P₂");
      _drawPin(canvas, p3, "P₃");
      _drawPin(canvas, p4, "P₄");
    }
  }

  void _drawLaserBeam(Canvas canvas, Offset p1, Offset p2, {bool isDenseMedium = false, bool isWhiteLight = false}) {
    if (isWhiteLight) {
      canvas.drawLine(p1, p2, Paint()..color = const Color(0x66FFFFFF)..strokeWidth = 6.0..strokeCap = StrokeCap.round);
      canvas.drawLine(p1, p2, Paint()..color = Colors.white..strokeWidth = 2.0..strokeCap = StrokeCap.round);
      return;
    }

    final glowColor = isDenseMedium ? const Color(0xffD50000) : const Color(0xffFF1744);

    canvas.drawLine(
      p1,
      p2,
      Paint()
        ..color = glowColor.withValues(alpha: isDenseMedium ? 0.30 : 0.45)
        ..strokeWidth = isDenseMedium ? 5.0 : 6.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawLine(
      p1,
      p2,
      Paint()
        ..color = glowColor
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawLine(
      p1,
      p2,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawSpectrumFan(Canvas canvas, Offset p1, Offset p2) {
    final colors = [
      Colors.redAccent,
      Colors.orangeAccent,
      Colors.yellowAccent,
      Colors.greenAccent,
      Colors.cyanAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
    ];

    for (int i = 0; i < colors.length; i++) {
      final yOffset = (i - 3) * 1.8;
      canvas.drawLine(
        p1,
        Offset(p2.dx, p2.dy + yOffset),
        Paint()..color = colors[i].withValues(alpha: 0.85)..strokeWidth = 1.4,
      );
    }
  }

  void _drawSpectrumEmergence(Canvas canvas, Offset origin, double len, double baseAngle) {
    final colors = [
      Colors.redAccent,
      Colors.orangeAccent,
      Colors.yellowAccent,
      Colors.greenAccent,
      Colors.cyanAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
    ];

    for (int i = 0; i < colors.length; i++) {
      final spreadAngle = baseAngle + (i * 0.035);
      final end = Offset(origin.dx + len * cos(spreadAngle), origin.dy + len * sin(spreadAngle));
      canvas.drawLine(origin, end, Paint()..color = colors[i]..strokeWidth = 1.6);
    }
    _drawText(canvas, "VIBGYOR Screen", Offset(origin.dx + len * cos(baseAngle) - 10, origin.dy + len * sin(baseAngle) + 16), color: Colors.cyanAccent);
  }

  void _drawOpticalSpot(Canvas canvas, Offset pos) {
    canvas.drawCircle(pos, 4.5 + (pulseValue * 1.5), Paint()..color = const Color(0x44FF1744));
    canvas.drawCircle(pos, 2.2, Paint()..color = const Color(0xffFF1744));
    canvas.drawCircle(pos, 1.0, Paint()..color = Colors.white);
  }

  void _drawPin(Canvas canvas, Offset pos, String label) {
    canvas.drawCircle(pos, 3.2, Paint()..color = const Color(0xffFF5252));
    canvas.drawCircle(pos, 1.2, Paint()..color = Colors.white);
    _drawText(canvas, label, Offset(pos.dx + 4, pos.dy - 6), color: const Color(0xffFF5252));
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = sqrt(dx * dx + dy * dy);
    final count = (dist / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < count; i++) {
      final startFrac = (i * (dashWidth + dashSpace)) / dist;
      final endFrac = ((i * (dashWidth + dashSpace)) + dashWidth) / dist;
      canvas.drawLine(
        Offset(p1.dx + dx * startFrac, p1.dy + dy * startFrac),
        Offset(p1.dx + dx * endFrac, p1.dy + dy * endFrac),
        paint,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, {Color? color}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 7.5,
          fontWeight: FontWeight.bold,
          color: color ?? Colors.white70,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _PrismOpticsPainter oldDelegate) =>
      oldDelegate.angleOfIncidence != angleOfIncidence ||
          oldDelegate.showDispersion != showDispersion ||
          oldDelegate.showPins != showPins ||
          oldDelegate.pulseValue != pulseValue;
}