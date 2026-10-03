import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/practical_model.dart';

class P05EquivalentResistanceScene extends StatefulWidget {
  final Practical practical;

  const P05EquivalentResistanceScene({
    super.key,
    required this.practical,
  });

  @override
  State<P05EquivalentResistanceScene> createState() =>
      _P05EquivalentResistanceSceneState();
}

class _P05EquivalentResistanceSceneState
    extends State<P05EquivalentResistanceScene> with TickerProviderStateMixin {
  late AnimationController _electronFlowController;
  late AnimationController _needleAnimController;

  // Circuit Component Values
  final double batteryVoltage = 6.0; // 6 Volts
  final double r1 = 5.0; // Resistor 1 = 5 Ohms
  final double r2 = 10.0; // Resistor 2 = 10 Ohms

  bool isParallel = false; // false = Series, true = Parallel
  bool isKeyClosed = false;

  double currentI = 0.0;
  double voltageV = 0.0;
  double previousI = 0.0;
  double previousV = 0.0;

  final List<Map<String, dynamic>> recordedReadings = [];
  String observation =
      "Select connection mode (Series or Parallel) and close the key.";

  @override
  void initState() {
    super.initState();

    _electronFlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _needleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _calculateCircuit();
  }

  @override
  void dispose() {
    _electronFlowController.dispose();
    _needleAnimController.dispose();
    super.dispose();
  }

  double get theoreticalEquivalentR {
    if (isParallel) {
      // 1/Rp = 1/R1 + 1/R2 -> Rp = (R1 * R2) / (R1 + R2)
      return (r1 * r2) / (r1 + r2); // 50 / 15 = 3.33 Ohms
    } else {
      // Rs = R1 + R2
      return r1 + r2; // 5 + 10 = 15.0 Ohms
    }
  }

  void _calculateCircuit() {
    previousI = currentI;
    previousV = voltageV;

    if (!isKeyClosed) {
      currentI = 0.0;
      voltageV = 0.0;
    } else {
      final req = theoreticalEquivalentR;
      currentI = batteryVoltage / req; // Total circuit current
      voltageV = batteryVoltage; // Across equivalent combination

      final speedMs = (1800 - (currentI * 700)).clamp(350, 2000).toInt();
      _electronFlowController.duration = Duration(milliseconds: speedMs);
      if (!_electronFlowController.isAnimating) {
        _electronFlowController.repeat();
      }
    }

    _needleAnimController.forward(from: 0.0);
  }

  void _toggleKey() {
    setState(() {
      isKeyClosed = !isKeyClosed;
      _calculateCircuit();
      if (isKeyClosed) {
        final mode = isParallel ? "Parallel" : "Series";
        observation =
        "$mode circuit active. Total Current I = ${currentI.toStringAsFixed(2)} A, Total Voltage V = ${voltageV.toStringAsFixed(2)} V.";
      } else {
        observation = "Circuit opened. Current flow stopped.";
      }
    });
  }

  void _switchTopology(bool parallel) {
    if (isParallel == parallel) return;
    setState(() {
      isParallel = parallel;
      _calculateCircuit();
      final mode = isParallel ? "Parallel (1/Rp = 1/R₁ + 1/R₂)" : "Series (Rs = R₁ + R₂)";
      observation = "Switched to $mode arrangement. Reconnect key to test.";
    });
  }

  void _recordReading() {
    if (!isKeyClosed) {
      setState(() {
        observation = "Close the plug key first before taking measurements.";
      });
      return;
    }

    final mode = isParallel ? "Parallel" : "Series";
    final expR = voltageV / currentI;

    final alreadyExists = recordedReadings.any((r) => r["Mode"] == mode);
    if (alreadyExists) {
      setState(() {
        observation = "Reading for $mode combination is already recorded in the table.";
      });
      return;
    }

    setState(() {
      recordedReadings.add({
        "Mode": mode,
        "V": double.parse(voltageV.toStringAsFixed(2)),
        "I": double.parse(currentI.toStringAsFixed(2)),
        "Req": double.parse(expR.toStringAsFixed(2)),
        "Theo": double.parse(theoreticalEquivalentR.toStringAsFixed(2)),
      });
      observation =
      "Recorded $mode: V = ${voltageV.toStringAsFixed(2)} V, I = ${currentI.toStringAsFixed(2)} A -> Req = ${expR.toStringAsFixed(2)} Ω (Theo: ${theoreticalEquivalentR.toStringAsFixed(2)} Ω).";
    });
  }

  void _resetLab() {
    setState(() {
      isKeyClosed = false;
      isParallel = false;
      recordedReadings.clear();
      _calculateCircuit();
      observation =
      "Experiment reset. Select combination and record equivalent resistance.";
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
          // Left: Interactive Circuit with Dynamic Topology
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _electronFlowController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _EquivalentCircuitWirePainter(
                          isClosed: isKeyClosed,
                          isParallel: isParallel,
                          progress: _electronFlowController.value,
                        ),
                      );
                    },
                  ),
                ),
                _buildCircuitComponents(),
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

          // Right: Equivalent Comparison & Log
          Expanded(
            flex: 4,
            child: _buildObservationAndLogPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildCircuitComponents() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Mode Indicator Badge (Top Center)
            Positioned(
              left: w * 0.38,
              top: h * 0.05,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isParallel ? const Color(0x3300BCD4) : const Color(0x336C5CE7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isParallel ? Colors.cyanAccent : Colors.purpleAccent,
                  ),
                ),
                child: Text(
                  isParallel ? "PARALLEL CIRCUIT" : "SERIES CIRCUIT",
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: isParallel ? Colors.cyanAccent : const Color(0xffB388FF),
                  ),
                ),
              ),
            ),

            // Battery (Top Left)
            Positioned(
              left: w * 0.08,
              top: h * 0.16,
              child: _batteryWidget(),
            ),

            // Plug Key Switch (Top Right)
            Positioned(
              right: w * 0.08,
              top: h * 0.16,
              child: _plugKeyWidget(),
            ),

            // Series Ammeter (Bottom Left)
            Positioned(
              left: w * 0.10,
              bottom: h * 0.22,
              child: _meterWidget(
                label: "Ammeter (I)",
                unit: "A",
                value: currentI,
                prevValue: previousI,
                maxValue: 2.5,
                accentColor: const Color(0xffFF5252),
              ),
            ),

            // Resistor Block(s) - Animated Position based on Series/Parallel
            if (!isParallel) ...[
              // Series Layout: R1 followed by R2 on the bottom rail
              Positioned(
                left: w * 0.40,
                bottom: h * 0.24,
                child: _resistorBox("R₁", r1),
              ),
              Positioned(
                left: w * 0.64,
                bottom: h * 0.24,
                child: _resistorBox("R₂", r2),
              ),
            ] else ...[
              // Parallel Layout: R1 on upper branch, R2 on lower branch
              Positioned(
                left: w * 0.48,
                bottom: h * 0.36,
                child: _resistorBox("R₁", r1),
              ),
              Positioned(
                left: w * 0.48,
                bottom: h * 0.14,
                child: _resistorBox("R₂", r2),
              ),
            ],

            // Voltmeter (Measures potential difference across equivalent combination)
            Positioned(
              left: w * 0.48,
              bottom: h * 0.58,
              child: _meterWidget(
                label: "Voltmeter (V)",
                unit: "V",
                value: voltageV,
                prevValue: previousV,
                maxValue: 6.0,
                accentColor: Colors.cyanAccent,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _batteryWidget() {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xff1A173B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isKeyClosed ? Colors.greenAccent : Colors.white24,
          width: 1.4,
        ),
        boxShadow: [
          if (isKeyClosed)
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.3),
              blurRadius: 6,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _terminal(const Color(0xffFF5252), "+"),
              _terminal(Colors.white38, "−"),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            "Battery (6V)",
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: isKeyClosed ? Colors.greenAccent : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _terminal(Color color, String sign) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        sign,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }

  Widget _plugKeyWidget() {
    return GestureDetector(
      onTap: _toggleKey,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xff1E1942),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isKeyClosed ? Colors.greenAccent : const Color(0xffFF5252),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isKeyClosed ? Icons.power : Icons.power_off,
              size: 16,
              color: isKeyClosed ? Colors.greenAccent : const Color(0xffFF5252),
            ),
            const SizedBox(width: 4),
            Text(
              isKeyClosed ? "Key ON" : "Key OFF",
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isKeyClosed ? Colors.greenAccent : const Color(0xffFF5252),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resistorBox(String label, double resistance) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xff1A173B),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xffFFB300), width: 1.2),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.waves, size: 14, color: Color(0xffFFB300)),
          Text(
            label,
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            "${resistance.toStringAsFixed(1)} Ω",
            style: const TextStyle(fontSize: 7.5, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _meterWidget({
    required String label,
    required String unit,
    required double value,
    required double prevValue,
    required double maxValue,
    required Color accentColor,
  }) {
    return Container(
      width: 66,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xff1A173B),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accentColor.withOpacity(0.7), width: 1.3),
        boxShadow: [BoxShadow(color: accentColor.withOpacity(0.15), blurRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 1),
          SizedBox(
            width: 44,
            height: 22,
            child: AnimatedBuilder(
              animation: _needleAnimController,
              builder: (context, child) {
                final displayVal = (prevValue +
                    ((value - prevValue) * _needleAnimController.value));
                return CustomPaint(
                  painter: _MeterDialPainter(
                    fraction: (displayVal / maxValue).clamp(0.0, 1.0),
                    dialColor: accentColor,
                  ),
                );
              },
            ),
          ),
          Text(
            "${value.toStringAsFixed(2)} $unit",
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildObservationAndLogPanel() {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Equivalent Resistance Comparison",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          // Theory cards
          Row(
            children: [
              Expanded(
                child: _formulaCard(
                  "Series",
                  "Rs = R₁ + R₂",
                  "15.0 Ω",
                  !isParallel,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _formulaCard(
                  "Parallel",
                  "1/Rp = 1/R₁ + 1/R₂",
                  "3.33 Ω",
                  isParallel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Observation Table (Fixed with Expanded to eliminate 4.1px overflow)
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
                        Expanded(flex: 3, child: Center(child: Text("Mode", style: TextStyle(fontSize: 7.2, fontWeight: FontWeight.bold, color: Colors.cyanAccent)))),
                        Expanded(flex: 2, child: Center(child: Text("V(V)", style: TextStyle(fontSize: 7.2, fontWeight: FontWeight.bold, color: Colors.cyanAccent)))),
                        Expanded(flex: 2, child: Center(child: Text("I(A)", style: TextStyle(fontSize: 7.2, fontWeight: FontWeight.bold, color: Colors.cyanAccent)))),
                        Expanded(flex: 3, child: Center(child: Text("Req(Ω)", style: TextStyle(fontSize: 7.2, fontWeight: FontWeight.bold, color: Colors.cyanAccent)))),
                        Expanded(flex: 3, child: Center(child: Text("Theo", style: TextStyle(fontSize: 7.2, fontWeight: FontWeight.bold, color: Colors.cyanAccent)))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: recordedReadings.isEmpty
                        ? const Center(
                      child: Text(
                        "Record Series & Parallel readings",
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
                              Expanded(flex: 3, child: Center(child: Text("${r['Mode']}", style: const TextStyle(fontSize: 7.2, fontWeight: FontWeight.bold, color: Colors.white70)))),
                              Expanded(flex: 2, child: Center(child: Text("${r['V']}", style: const TextStyle(fontSize: 7.2, color: Colors.white60)))),
                              Expanded(flex: 2, child: Center(child: Text("${r['I']}", style: const TextStyle(fontSize: 7.2, color: Colors.white60)))),
                              Expanded(flex: 3, child: Center(child: Text("${r['Req']}", style: const TextStyle(fontSize: 7.2, fontWeight: FontWeight.bold, color: Colors.greenAccent)))),
                              Expanded(flex: 3, child: Center(child: Text("${r['Theo']}", style: const TextStyle(fontSize: 7.2, color: Colors.white38)))),
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

  Widget _formulaCard(String title, String formula, String expected, bool active) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: active ? const Color(0xff1E1942) : const Color(0xff1A173B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: active ? Colors.purpleAccent : Colors.white.withOpacity(0.08),
          width: active ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: active ? Colors.cyanAccent : Colors.white70,
            ),
          ),
          Text(
            formula,
            style: const TextStyle(fontSize: 7, color: Colors.white54),
          ),
          Text(
            "Expected: $expected",
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
              color: active ? Colors.greenAccent : Colors.white38,
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

  // Fixed Bottom Bar with horizontal scroll to prevent 69px overflow
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
            // Topology Selector
            Container(
              decoration: BoxDecoration(
                color: const Color(0xff1A173B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _topologyButton("Series", !isParallel, () => _switchTopology(false)),
                  _topologyButton("Parallel", isParallel, () => _switchTopology(true)),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // Key Switch Button
            ElevatedButton.icon(
              onPressed: _toggleKey,
              icon: Icon(
                isKeyClosed ? Icons.lock_open : Icons.lock_outline,
                size: 13,
              ),
              label: Text(
                isKeyClosed ? "Open Key" : "Close Key",
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isKeyClosed ? const Color(0xff2E7D32) : const Color(0xffD32F2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 6),

            // Record Button
            ElevatedButton.icon(
              onPressed: _recordReading,
              icon: const Icon(Icons.bookmark_add_outlined, size: 13),
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
            const SizedBox(width: 6),

            // Reset Button
            OutlinedButton.icon(
              onPressed: _resetLab,
              icon: const Icon(Icons.refresh, size: 13),
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

  Widget _topologyButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff6C5CE7) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.0,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }
}

// --- Wire Painter Supporting Both Series & Parallel Morphing ---

class _EquivalentCircuitWirePainter extends CustomPainter {
  final bool isClosed;
  final bool isParallel;
  final double progress;

  _EquivalentCircuitWirePainter({
    required this.isClosed,
    required this.isParallel,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wirePaint = Paint()
      ..color = isClosed ? Colors.greenAccent : const Color(0xff546E7A)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final voltmeterPaint = Paint()
      ..color = isClosed ? Colors.cyanAccent : const Color(0xff455A64)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    if (!isParallel) {
      // Series Circuit Wiring Path
      final path = Path()
        ..moveTo(w * 0.17, h * 0.22)
        ..lineTo(w * 0.88, h * 0.22) // to key
        ..lineTo(w * 0.88, h * 0.68)
        ..lineTo(w * 0.73, h * 0.68) // R2
        ..moveTo(w * 0.64, h * 0.68)
        ..lineTo(w * 0.49, h * 0.68) // R1
        ..moveTo(w * 0.40, h * 0.68)
        ..lineTo(w * 0.20, h * 0.68) // Ammeter
        ..moveTo(w * 0.10, h * 0.68)
        ..lineTo(w * 0.08, h * 0.68)
        ..lineTo(w * 0.08, h * 0.22)
        ..lineTo(w * 0.12, h * 0.22); // to battery

      canvas.drawPath(path, wirePaint);

      // Voltmeter taps across R1 + R2 in series
      final vShunt = Path()
        ..moveTo(w * 0.40, h * 0.68)
        ..lineTo(w * 0.40, h * 0.44)
        ..lineTo(w * 0.48, h * 0.44)
        ..moveTo(w * 0.56, h * 0.44)
        ..lineTo(w * 0.73, h * 0.44)
        ..lineTo(w * 0.73, h * 0.68);

      canvas.drawPath(vShunt, voltmeterPaint);
    } else {
      // Parallel Circuit Wiring Path
      final mainLoop = Path()
        ..moveTo(w * 0.17, h * 0.22)
        ..lineTo(w * 0.88, h * 0.22) // to key
        ..lineTo(w * 0.88, h * 0.68)
        ..lineTo(w * 0.70, h * 0.68)
        ..lineTo(w * 0.65, h * 0.52)
        ..lineTo(w * 0.56, h * 0.52) // upper R1 branch
        ..moveTo(w * 0.70, h * 0.68)
        ..lineTo(w * 0.65, h * 0.76)
        ..lineTo(w * 0.56, h * 0.76) // lower R2 branch
        ..moveTo(w * 0.48, h * 0.52)
        ..lineTo(w * 0.38, h * 0.52)
        ..lineTo(w * 0.34, h * 0.68)
        ..moveTo(w * 0.48, h * 0.76)
        ..lineTo(w * 0.38, h * 0.76)
        ..lineTo(w * 0.34, h * 0.68)
        ..lineTo(w * 0.20, h * 0.68)
        ..moveTo(w * 0.10, h * 0.68)
        ..lineTo(w * 0.08, h * 0.68)
        ..lineTo(w * 0.08, h * 0.22)
        ..lineTo(w * 0.12, h * 0.22);

      canvas.drawPath(mainLoop, wirePaint);

      final vShunt = Path()
        ..moveTo(w * 0.34, h * 0.68)
        ..lineTo(w * 0.34, h * 0.38)
        ..lineTo(w * 0.48, h * 0.38)
        ..moveTo(w * 0.56, h * 0.38)
        ..lineTo(w * 0.70, h * 0.38)
        ..lineTo(w * 0.70, h * 0.68);

      canvas.drawPath(vShunt, voltmeterPaint);
    }

    // Animated Electron Dots
    if (isClosed) {
      final electronPaint = Paint()
        ..color = const Color(0xff00E5FF)
        ..style = PaintingStyle.fill;

      for (double offset = 0.0; offset < 1.0; offset += 0.10) {
        final pos = (progress + offset) % 1.0;
        final p = _getPerimeterPoint(pos, w, h);
        canvas.drawCircle(p, 2.0, electronPaint);
      }
    }
  }

  Offset _getPerimeterPoint(double t, double w, double h) {
    if (t < 0.25) {
      final frac = t / 0.25;
      return Offset(w * 0.08 + frac * (w * 0.80), h * 0.22);
    } else if (t < 0.50) {
      final frac = (t - 0.25) / 0.25;
      return Offset(w * 0.88, h * 0.22 + frac * (h * 0.46));
    } else if (t < 0.75) {
      final frac = (t - 0.50) / 0.25;
      return Offset(w * 0.88 - frac * (w * 0.80), h * 0.68);
    } else {
      final frac = (t - 0.75) / 0.25;
      return Offset(w * 0.08, h * 0.68 - frac * (h * 0.46));
    }
  }

  @override
  bool shouldRepaint(covariant _EquivalentCircuitWirePainter oldDelegate) =>
      oldDelegate.progress != progress ||
          oldDelegate.isClosed != isClosed ||
          oldDelegate.isParallel != isParallel;
}

class _MeterDialPainter extends CustomPainter {
  final double fraction;
  final Color dialColor;

  _MeterDialPainter({required this.fraction, required this.dialColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.95);
    final radius = size.width * 0.48;

    final arcPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      arcPaint,
    );

    final angle = pi + (fraction * pi);
    final needleLength = radius * 0.90;
    final needleEnd = Offset(
      center.dx + (needleLength * cos(angle)),
      center.dy + (needleLength * sin(angle)),
    );

    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = dialColor
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 2.0, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MeterDialPainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}