import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/practical_model.dart';

class P11GlassSlabScene extends StatefulWidget {
  final Practical practical;

  const P11GlassSlabScene({
    super.key,
    required this.practical,
  });

  @override
  State<P11GlassSlabScene> createState() => _P11GlassSlabSceneState();
}

class _P11GlassSlabSceneState extends State<P11GlassSlabScene> {
  // Incident angle i in degrees (20° to 65°)
  double angleI = 35.0;

  // Refractive index of glass slab
  final double refractiveIndexGlass = 1.52;

  // Glass slab dimensions on canvas
  final double slabWidth = 140.0;
  final double slabHeight = 70.0;

  final List<Map<String, dynamic>> recordedReadings = [];
  String observation =
      "Adjust the incident angle slider to observe refraction and lateral displacement (d).";

  // Snell's law: sin(r) = sin(i) / n
  double get angleRRad {
    final iRad = angleI * pi / 180.0;
    final sinR = sin(iRad) / refractiveIndexGlass;
    return asin(sinR.clamp(-1.0, 1.0));
  }

  double get angleRDeg => angleRRad * 180.0 / pi;

  // Emergent angle equals incident angle for parallel-sided slab
  double get angleEDeg => angleI;

  // Lateral shift: d = t * sin(i - r) / cos(r)
  double get lateralDisplacementMm {
    final iRad = angleI * pi / 180.0;
    final rRad = angleRRad;
    const thicknessMm = 35.0;
    return (thicknessMm * sin(iRad - rRad)) / cos(rRad);
  }

  void _recordReading() {
    final roundedI = double.parse(angleI.toStringAsFixed(1));
    final alreadyExists =
    recordedReadings.any((r) => (r["i"] - roundedI).abs() < 0.2);

    if (alreadyExists) {
      setState(() {
        observation =
        "Observation for ∠i = ${angleI.toStringAsFixed(0)}° is already recorded.";
      });
      return;
    }

    setState(() {
      recordedReadings.add({
        "i": roundedI,
        "r": double.parse(angleRDeg.toStringAsFixed(1)),
        "e": double.parse(angleEDeg.toStringAsFixed(1)),
        "d": double.parse(lateralDisplacementMm.toStringAsFixed(1)),
      });
      recordedReadings.sort((a, b) => a["i"].compareTo(b["i"]));
      observation =
      "Recorded: ∠i = ${angleI.toStringAsFixed(0)}°, ∠r = ${angleRDeg.toStringAsFixed(1)}°, ∠e = ${angleEDeg.toStringAsFixed(0)}° (∠i ≈ ∠e confirmed).";
    });
  }

  void _resetLab() {
    setState(() {
      angleI = 35.0;
      recordedReadings.clear();
      observation =
      "Bench reset. Adjust incident ray angle to observe refraction through slab.";
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
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GlassSlabOpticsPainter(
                      angleIDeg: angleI,
                      refractiveIndex: refractiveIndexGlass,
                      slabW: slabWidth,
                      slabH: slabHeight,
                    ),
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
          ),
          VerticalDivider(width: 1, color: Colors.white.withOpacity(0.08)),
          Expanded(
            flex: 4,
            child: _buildAnglesAndDataPanel(),
          ),
        ],
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
            "Refraction & Lateral Shift",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: _angleCard(
                  "∠i (Incident)",
                  "${angleI.toStringAsFixed(1)}°",
                  Colors.amberAccent,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _angleCard(
                  "∠r (Refracted)",
                  "${angleRDeg.toStringAsFixed(1)}°",
                  Colors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: _angleCard(
                  "∠e (Emergent)",
                  "${angleEDeg.toStringAsFixed(1)}°",
                  Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _angleCard(
                  "Shift (d)",
                  "${lateralDisplacementMm.toStringAsFixed(1)} mm",
                  Colors.purpleAccent,
                ),
              ),
            ],
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
                            child: Text(
                              "∠i",
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyanAccent,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              "∠r",
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyanAccent,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              "∠e",
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyanAccent,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Text(
                              "Shift (d)",
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyanAccent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: recordedReadings.isEmpty
                        ? const Center(
                      child: Text(
                        "Vary ∠i and record observations",
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white38,
                        ),
                      ),
                    )
                        : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: recordedReadings.length,
                      itemBuilder: (context, i) {
                        final r = recordedReadings[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2.0,
                            horizontal: 2,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(
                                    "${r['i']}°",
                                    style: const TextStyle(
                                      fontSize: 7.5,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(
                                    "${r['r']}°",
                                    style: const TextStyle(
                                      fontSize: 7.5,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(
                                    "${r['e']}°",
                                    style: const TextStyle(
                                      fontSize: 7.5,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Center(
                                  child: Text(
                                    "${r['d']} mm",
                                    style: const TextStyle(
                                      fontSize: 7.5,
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

  Widget _angleCard(String label, String val, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xff1A173B).withOpacity(0.7),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 7.0,
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            val,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 170,
              child: Row(
                children: [
                  const Text(
                    "∠i:",
                    style: TextStyle(
                      fontSize: 9.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2.0,
                        thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 4),
                        overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 8),
                      ),
                      child: Slider(
                        value: angleI,
                        min: 20.0,
                        max: 65.0,
                        activeColor: const Color(0xff6C5CE7),
                        inactiveColor: Colors.white12,
                        onChanged: (val) {
                          setState(() {
                            angleI = val;
                          });
                        },
                      ),
                    ),
                  ),
                  Text(
                    "${angleI.toStringAsFixed(0)}°",
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _recordReading,
              icon: const Icon(Icons.bookmark_add_outlined, size: 12),
              label: const Text(
                "Record Angle",
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff6C5CE7),
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 6),
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
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassSlabOpticsPainter extends CustomPainter {
  final double angleIDeg;
  final double refractiveIndex;
  final double slabW;
  final double slabH;

  _GlassSlabOpticsPainter({
    required this.angleIDeg,
    required this.refractiveIndex,
    required this.slabW,
    required this.slabH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.48;
    final cy = size.height * 0.48;

    final slabRect =
    Rect.fromCenter(center: Offset(cx, cy), width: slabW, height: slabH);

    final slabFillPaint = Paint()
      ..color = const Color(0x2200E5FF)
      ..style = PaintingStyle.fill;
    final slabBorderPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawRRect(
      RRect.fromRectAndRadius(slabRect, const Radius.circular(3)),
      slabFillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(slabRect, const Radius.circular(3)),
      slabBorderPaint,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: "Glass Slab (n ≈ $refractiveIndex)",
        style: TextStyle(
          fontSize: 7.5,
          color: Colors.white.withOpacity(0.55),
          fontWeight: FontWeight.w600,
        ),
      )
      ..layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - 5));

    final pEntry = Offset(cx - 16, slabRect.top);
    const normalLength = 32.0;

    final normalPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(pEntry.dx, pEntry.dy - normalLength),
      Offset(pEntry.dx, pEntry.dy + normalLength),
      normalPaint,
    );

    final iRad = angleIDeg * pi / 180.0;
    const rayLength = 55.0;
    final pSource = Offset(
      pEntry.dx - (rayLength * sin(iRad)),
      pEntry.dy - (rayLength * cos(iRad)),
    );

    final incidentPaint = Paint()
      ..color = Colors.amberAccent
      ..strokeWidth = 1.6;
    canvas.drawLine(pSource, pEntry, incidentPaint);

    final sinR = sin(iRad) / refractiveIndex;
    final rRad = asin(sinR.clamp(-1.0, 1.0));

    final deltaXInside = slabH * tan(rRad);
    final pExit = Offset(pEntry.dx + deltaXInside, slabRect.bottom);

    final refractedPaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 1.6;
    canvas.drawLine(pEntry, pExit, refractedPaint);

    canvas.drawLine(
      Offset(pExit.dx, pExit.dy - normalLength),
      Offset(pExit.dx, pExit.dy + normalLength),
      normalPaint,
    );

    final pEmergentEnd = Offset(
      pExit.dx + (rayLength * sin(iRad)),
      pExit.dy + (rayLength * cos(iRad)),
    );

    final emergentPaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 1.6;
    canvas.drawLine(pExit, pEmergentEnd, emergentPaint);

    final pUndeviatedEnd = Offset(
      pEntry.dx + ((rayLength + slabH + 20) * sin(iRad)),
      pEntry.dy + ((rayLength + slabH + 20) * cos(iRad)),
    );

    final dottedPaint = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    _drawDottedLine(canvas, pEntry, pUndeviatedEnd, dottedPaint);

    _drawOpticalPin(canvas, Offset.lerp(pSource, pEntry, 0.35)!, "P₁");
    _drawOpticalPin(canvas, Offset.lerp(pSource, pEntry, 0.75)!, "P₂");
    _drawOpticalPin(canvas, Offset.lerp(pExit, pEmergentEnd, 0.35)!, "P₃");
    _drawOpticalPin(canvas, Offset.lerp(pExit, pEmergentEnd, 0.75)!, "P₄");
  }

  void _drawOpticalPin(Canvas canvas, Offset pos, String label) {
    canvas.drawCircle(pos, 2.5, Paint()..color = const Color(0xffFF1744));
    canvas.drawCircle(
      pos,
      2.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
  }

  void _drawDottedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 3.0;
    const dashSpace = 2.5;
    final totalDistance = (p2 - p1).distance;
    final dx = (p2.dx - p1.dx) / totalDistance;
    final dy = (p2.dy - p1.dy) / totalDistance;

    double currentDistance = 0.0;
    while (currentDistance < totalDistance) {
      final start = Offset(
        p1.dx + (dx * currentDistance),
        p1.dy + (dy * currentDistance),
      );
      final endDistance =
      (currentDistance + dashWidth).clamp(0.0, totalDistance);
      final end = Offset(
        p1.dx + (dx * endDistance),
        p1.dy + (dy * endDistance),
      );
      canvas.drawLine(start, end, paint);
      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _GlassSlabOpticsPainter oldDelegate) =>
      oldDelegate.angleIDeg != angleIDeg ||
          oldDelegate.refractiveIndex != refractiveIndex ||
          oldDelegate.slabW != slabW ||
          oldDelegate.slabH != slabH;
}