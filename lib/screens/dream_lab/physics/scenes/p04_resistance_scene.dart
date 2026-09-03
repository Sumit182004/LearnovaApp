import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/practical_model.dart';

class P04ResistanceScene extends StatefulWidget {
  final Practical practical;

  const P04ResistanceScene({
    super.key,
    required this.practical,
  });

  @override
  State<P04ResistanceScene> createState() => _P04ResistanceSceneState();
}

class _P04ResistanceSceneState extends State<P04ResistanceScene>
    with TickerProviderStateMixin {
  late AnimationController _electronFlowController;
  late AnimationController _needleAnimController;
  late AnimationController _sparkController;

  // Circuit electrical parameters
  final double fixedResistorR = 5.0; // 5 Ohms
  final double batteryVoltage = 6.0; // 6 Volts
  double rheostatR = 15.0; // Adjustable 1 to 25 Ohms
  bool isKeyClosed = false;

  // Meter readings
  double currentI = 0.0;
  double voltageV = 0.0;
  double previousI = 0.0;
  double previousV = 0.0;

  final List<Map<String, double>> recordedReadings = [];
  String observation =
      "Tap the brass plug key to complete the circuit and initiate current flow.";

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

    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _calculateCircuit();
  }

  @override
  void dispose() {
    _electronFlowController.dispose();
    _needleAnimController.dispose();
    _sparkController.dispose();
    super.dispose();
  }

  void _calculateCircuit() {
    previousI = currentI;
    previousV = voltageV;

    if (!isKeyClosed) {
      currentI = 0.0;
      voltageV = 0.0;
    } else {
      final totalR = fixedResistorR + rheostatR;
      currentI = batteryVoltage / totalR; // I = V / R_total
      voltageV = currentI * fixedResistorR; // V = I * R

      final speedMs = (1800 - (currentI * 1200)).clamp(300, 2000).toInt();
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
      if (isKeyClosed) {
        _sparkController.forward(from: 0.0);
      }
      _calculateCircuit();
      if (isKeyClosed) {
        observation =
        "Circuit complete. Electrons flowing! Current: ${currentI.toStringAsFixed(2)} A, Voltage: ${voltageV.toStringAsFixed(2)} V.";
      } else {
        observation = "Circuit open. Electron flow interrupted (0 A, 0 V).";
      }
    });
  }

  void _recordReading() {
    if (!isKeyClosed) {
      setState(() {
        observation = "Close the plug key first before recording readings.";
      });
      return;
    }

    final alreadyRecorded = recordedReadings.any(
          (r) => (r["I"]! - currentI).abs() < 0.02,
    );

    if (alreadyRecorded) {
      setState(() {
        observation = "Reading already recorded for this rheostat setting.";
      });
      return;
    }

    setState(() {
      recordedReadings.add({
        "V": double.parse(voltageV.toStringAsFixed(2)),
        "I": double.parse(currentI.toStringAsFixed(2)),
        "R": double.parse((voltageV / currentI).toStringAsFixed(2)), // R = V / I
      });
      recordedReadings.sort((a, b) => a["I"]!.compareTo(b["I"]!));
      observation =
      "Data point added: V = ${voltageV.toStringAsFixed(2)} V, I = ${currentI.toStringAsFixed(2)} A (R ≈ ${(voltageV / currentI).toStringAsFixed(2)} Ω).";
    });
  }

  void _resetCircuit() {
    setState(() {
      isKeyClosed = false;
      rheostatR = 15.0;
      recordedReadings.clear();
      _calculateCircuit();
      observation =
      "Experiment reset. Plug key opened. Ready for new trial.";
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
          // Left: Animated Interactive Bench
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _electronFlowController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _LiveCircuitWirePainter(
                          isClosed: isKeyClosed,
                          flowProgress: _electronFlowController.value,
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

          // Right: Real-Time V-I Graph & Data Table
          Expanded(
            flex: 4,
            child: _buildGraphAndDataPanel(),
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
            // 1. Dual-Cell Battery Pack (Top Left)
            Positioned(
              left: w * 0.05,
              top: h * 0.12,
              child: _buildLabBattery(),
            ),

            // 2. Brass Plug Key (Top Center)
            Positioned(
              left: w * 0.32,
              top: h * 0.10,
              child: _buildLabPlugKey(),
            ),

            // 3. Ceramic Wire-Wound Rheostat (Top Right)
            Positioned(
              right: w * 0.04,
              top: h * 0.08,
              child: _buildLabRheostat(),
            ),

            // 4. Series Needle Ammeter (Bottom Left)
            Positioned(
              left: w * 0.12,
              bottom: h * 0.22,
              child: _buildAnimatedDial(
                label: "Ammeter (A)",
                unit: "A",
                value: currentI,
                prevValue: previousI,
                maxValue: 1.5,
                accentColor: const Color(0xffFF5252),
              ),
            ),

            // 5. Standard Resistor Wire (Bottom Center)
            Positioned(
              left: w * 0.44,
              bottom: h * 0.22,
              child: _buildLabResistor(),
            ),

            // 6. Parallel Voltmeter (Directly centered above Resistor)
            Positioned(
              left: w * 0.44,
              bottom: h * 0.52,
              child: _buildAnimatedDial(
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

  Widget _buildLabBattery() {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xff1A173B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isKeyClosed ? Colors.greenAccent : Colors.white24,
          width: 1.5,
        ),
        boxShadow: [
          if (isKeyClosed)
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.35),
              blurRadius: 8,
              spreadRadius: 1,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _cellGraphic(),
              const SizedBox(width: 3),
              _cellGraphic(),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            isKeyClosed ? "6V (Active)" : "6V (Idle)",
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
              color: isKeyClosed ? Colors.greenAccent : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _terminal(Color color, String sign) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        sign,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }

  Widget _cellGraphic() {
    return Container(
      width: 16,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xff121026),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xffFFB300), width: 1.2),
      ),
    );
  }

  Widget _buildLabPlugKey() {
    return GestureDetector(
      onTap: _toggleKey,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xff1E1942),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xffFFD700).withOpacity(0.6), width: 1.4),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _brassBlock(),
                    Container(
                      width: 14,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isKeyClosed ? const Color(0xffFFD700) : const Color(0xff0B0E1B),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      alignment: Alignment.center,
                      child: isKeyClosed
                          ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xffFFF176),
                          shape: BoxShape.circle,
                        ),
                      )
                          : null,
                    ),
                    _brassBlock(),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isKeyClosed ? "Plug In (ON)" : "Plug Out (OFF)",
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.bold,
                    color: isKeyClosed ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: isKeyClosed ? -4 : -18,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 10,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xff121026),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xffFFD700), width: 1.2),
              ),
            ),
          ),
          if (isKeyClosed)
            AnimatedBuilder(
              animation: _sparkController,
              builder: (context, child) {
                if (_sparkController.value == 0 || _sparkController.isCompleted) {
                  return const SizedBox.shrink();
                }
                return CustomPaint(
                  size: const Size(20, 20),
                  painter: _SparkPainter(progress: _sparkController.value),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _brassBlock() {
    return Container(
      width: 14,
      height: 16,
      decoration: BoxDecoration(
        color: const Color(0xffD4AF37),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xff996515), width: 1),
      ),
    );
  }

  Widget _buildLabRheostat() {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xff1A173B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Rheostat",
                style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              Text(
                "${rheostatR.toStringAsFixed(0)} Ω",
                style: const TextStyle(
                  fontSize: 8.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 14,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 9,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xff2A1B54),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                  ),
                  child: CustomPaint(
                    painter: _RheostatCoilPainter(),
                  ),
                ),
                Positioned(
                  left: ((rheostatR - 1.0) / 24.0) * 85.0,
                  child: Container(
                    width: 7,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xffD4AF37),
                      borderRadius: BorderRadius.circular(1.5),
                      border: Border.all(color: Colors.black87, width: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 18,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
              ),
              child: Slider(
                value: rheostatR,
                min: 1.0,
                max: 25.0,
                activeColor: const Color(0xff6C5CE7),
                inactiveColor: Colors.white12,
                onChanged: (val) {
                  setState(() {
                    rheostatR = val;
                    _calculateCircuit();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabResistor() {
    final double heatFraction = isKeyClosed ? (currentI / 1.2).clamp(0.0, 1.0) : 0.0;
    final Color wireGlow = Color.lerp(
      const Color(0xffFF8F00),
      const Color(0xffFF3D00),
      heatFraction,
    )!;

    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xff1A173B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: wireGlow, width: 1.4),
        boxShadow: [
          if (heatFraction > 0.3)
            BoxShadow(
              color: wireGlow.withOpacity(0.35 * heatFraction),
              blurRadius: 6,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.waves, size: 16, color: wireGlow),
          const Text(
            "Resistor (R)",
            style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            "${fixedResistorR.toStringAsFixed(0)} Ω (Const.)",
            style: const TextStyle(fontSize: 7.5, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDial({
    required String label,
    required String unit,
    required double value,
    required double prevValue,
    required double maxValue,
    required Color accentColor,
  }) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xff1A173B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.6), width: 1.4),
        boxShadow: [
          BoxShadow(color: accentColor.withOpacity(0.15), blurRadius: 4),
        ],
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
          const SizedBox(height: 2),
          SizedBox(
            width: 48,
            height: 26,
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

  Widget _buildGraphAndDataPanel() {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "V-I Plot & Records",
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          // V-I Cartesian Chart
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xff1A173B).withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: _VICartesianPlotPainter(readings: recordedReadings),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Data Log Table
          Expanded(
            flex: 2,
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
                    color: const Color(0xff1E1942),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        Text("No.", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                        Text("V (Volt)", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                        Text("I (Amp)", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                        Text("R (Ω)", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: recordedReadings.isEmpty
                        ? const Center(
                      child: Text(
                        "No readings recorded",
                        style: TextStyle(fontSize: 8.5, color: Colors.white38),
                      ),
                    )
                        : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: recordedReadings.length,
                      itemBuilder: (context, i) {
                        final r = recordedReadings[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text("${i + 1}", style: const TextStyle(fontSize: 8, color: Colors.white70)),
                              Text("${r['V']}", style: const TextStyle(fontSize: 8, color: Colors.white70)),
                              Text("${r['I']}", style: const TextStyle(fontSize: 8, color: Colors.white70)),
                              Text(
                                "${r['R']}",
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.greenAccent,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xff121026),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _toggleKey,
            icon: Icon(
              isKeyClosed ? Icons.lock_open : Icons.lock_outline,
              size: 14,
            ),
            label: Text(
              isKeyClosed ? "Open Key" : "Close Key",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isKeyClosed ? const Color(0xff2E7D32) : const Color(0xffD32F2F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _recordReading,
            icon: const Icon(Icons.bookmark_add_outlined, size: 14),
            label: const Text(
              "Record V & I",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff6C5CE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _resetCircuit,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text(
              "Reset",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withOpacity(0.15)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Custom Painters ---

class _LiveCircuitWirePainter extends CustomPainter {
  final bool isClosed;
  final double flowProgress;

  _LiveCircuitWirePainter({
    required this.isClosed,
    required this.flowProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final baseWirePaint = Paint()
      ..color = isClosed ? Colors.greenAccent : const Color(0xff546E7A)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final parallelWirePaint = Paint()
      ..color = isClosed ? Colors.cyanAccent : const Color(0xff455A64)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final seriesPath = Path()
      ..moveTo(w * 0.17, h * 0.20)
      ..lineTo(w * 0.32, h * 0.20)
      ..moveTo(w * 0.44, h * 0.20)
      ..lineTo(w * 0.78, h * 0.20)
      ..lineTo(w * 0.88, h * 0.20)
      ..lineTo(w * 0.88, h * 0.68)
      ..lineTo(w * 0.55, h * 0.68)
      ..moveTo(w * 0.44, h * 0.68)
      ..lineTo(w * 0.22, h * 0.68)
      ..moveTo(w * 0.12, h * 0.68)
      ..lineTo(w * 0.05, h * 0.68)
      ..lineTo(w * 0.05, h * 0.20)
      ..lineTo(w * 0.08, h * 0.20);

    canvas.drawPath(seriesPath, baseWirePaint);

    final parallelPath = Path()
      ..moveTo(w * 0.44, h * 0.68)
      ..lineTo(w * 0.44, h * 0.46)
      ..moveTo(w * 0.55, h * 0.68)
      ..lineTo(w * 0.55, h * 0.46);

    canvas.drawPath(parallelPath, parallelWirePaint);

    if (isClosed) {
      final electronPaint = Paint()
        ..color = const Color(0xff00E5FF)
        ..style = PaintingStyle.fill;

      for (double offset = 0.0; offset < 1.0; offset += 0.08) {
        final pos = (flowProgress + offset) % 1.0;
        final point = _getPointAlongSeriesLoop(pos, w, h);
        canvas.drawCircle(point, 2.0, electronPaint);
      }
    }
  }

  Offset _getPointAlongSeriesLoop(double t, double w, double h) {
    if (t < 0.25) {
      final frac = t / 0.25;
      return Offset(w * 0.05 + frac * (w * 0.83), h * 0.20);
    } else if (t < 0.50) {
      final frac = (t - 0.25) / 0.25;
      return Offset(w * 0.88, h * 0.20 + frac * (h * 0.48));
    } else if (t < 0.75) {
      final frac = (t - 0.50) / 0.25;
      return Offset(w * 0.88 - frac * (w * 0.83), h * 0.68);
    } else {
      final frac = (t - 0.75) / 0.25;
      return Offset(w * 0.05, h * 0.68 - frac * (h * 0.48));
    }
  }

  @override
  bool shouldRepaint(covariant _LiveCircuitWirePainter oldDelegate) =>
      oldDelegate.flowProgress != flowProgress || oldDelegate.isClosed != isClosed;
}

class _RheostatCoilPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xffFFB300)
      ..strokeWidth = 1.0;

    for (double x = 2; x < size.width - 2; x += 3) {
      canvas.drawLine(Offset(x, 1), Offset(x, size.height - 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

    final tickPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 5; i++) {
      final tickAngle = pi + (i * (pi / 5));
      final p1 = Offset(center.dx + (radius * cos(tickAngle)), center.dy + (radius * sin(tickAngle)));
      final p2 = Offset(center.dx + ((radius - 3) * cos(tickAngle)), center.dy + ((radius - 3) * sin(tickAngle)));
      canvas.drawLine(p1, p2, tickPaint);
    }

    final angle = pi + (fraction * pi);
    final needleLength = radius * 0.90;
    final needleEnd = Offset(
      center.dx + (needleLength * cos(angle)),
      center.dy + (needleLength * sin(angle)),
    );

    final needlePaint = Paint()
      ..color = dialColor
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 2.0, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MeterDialPainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}

class _SparkPainter extends CustomPainter {
  final double progress;
  _SparkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rand = Random(7);
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(1.0 - progress)
      ..strokeWidth = 1.2;

    for (int i = 0; i < 6; i++) {
      final angle = (i * (pi / 3)) + rand.nextDouble() * 0.3;
      final dist = (progress * 10.0) + 2.0;
      final end = Offset(center.dx + cos(angle) * dist, center.dy + sin(angle) * dist);
      canvas.drawLine(center, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _VICartesianPlotPainter extends CustomPainter {
  final List<Map<String, double>> readings;

  _VICartesianPlotPainter({required this.readings});

  @override
  void paint(Canvas canvas, Size size) {
    final padL = 24.0;
    final padB = 18.0;
    final padT = 8.0;
    final padR = 8.0;

    final origin = Offset(padL, size.height - padB);
    final axisPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.2;

    canvas.drawLine(origin, Offset(origin.dx, padT), axisPaint);
    canvas.drawLine(origin, Offset(size.width - padR, origin.dy), axisPaint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = const TextSpan(
      text: "V",
      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(4, padT));

    textPainter.text = const TextSpan(
      text: "I",
      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xffFF5252)),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 12, origin.dy - 12));

    if (readings.isEmpty) return;

    final maxI = 1.5;
    final maxV = 6.0;

    final plotW = size.width - padL - padR;
    final plotH = size.height - padB - padT;

    final trendPaint = Paint()
      ..color = Colors.purpleAccent.withOpacity(0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final endX = origin.dx + plotW;
    final endY = origin.dy - ((maxI * 5.0 / maxV) * plotH);
    canvas.drawLine(origin, Offset(endX, endY.clamp(padT, origin.dy)), trendPaint);

    final pointPaint = Paint()..color = const Color(0xffFF5252);

    for (final r in readings) {
      final iVal = r["I"]!;
      final vVal = r["V"]!;

      final px = origin.dx + ((iVal / maxI) * plotW);
      final py = origin.dy - ((vVal / maxV) * plotH);

      canvas.drawCircle(Offset(px, py), 2.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VICartesianPlotPainter oldDelegate) => true;
}