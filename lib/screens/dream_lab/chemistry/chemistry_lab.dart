import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/practical_model.dart';
import '../widgets/experiment_modules.dart';
import '../widgets/instructions_panel.dart';

import 'scenes/p01_ph_scene.dart';
import 'scenes/p02_reaction_scene.dart';
import 'scenes/p03_reactivity_scene.dart';
import 'scenes/p08_acetic_acid_scene.dart';
import 'scenes/p09_soap_scene.dart';

class ChemistryLab extends StatefulWidget {
  final VoidCallback? onSwitchToPhysics;

  const ChemistryLab({
    super.key,
    this.onSwitchToPhysics,
  });

  @override
  State<ChemistryLab> createState() => _ChemistryLabState();
}

class _ChemistryLabState extends State<ChemistryLab> {
  bool isLoading = true;
  String error = "";

  List<Practical> practicals = [];
  int selectedPracticalIndex = -1;
  Practical? selectedPractical;

  bool leftPanelOpen = true;
  bool rightPanelOpen = true;

  static const double leftPanelWidth = 220;
  static const double rightPanelWidth = 225;

  @override
  void initState() {
    super.initState();
    loadPracticals();
  }

  Future<void> loadPracticals() async {
    try {
      final ref = FirebaseStorage.instance.ref(
        "syllabus/class10/chemistry/practicals/chemistry_practicals_class10.json",
      );

      final url = await ref.getDownloadURL();
      final response = await NetworkAssetBundle(Uri.parse(url)).load("");
      final jsonString = utf8.decode(response.buffer.asUint8List());
      final decoded = jsonDecode(jsonString);

      final List<Practical> loaded = [];
      if (decoded is Map && decoded["practicals"] is List) {
        for (final item in decoded["practicals"]) {
          if (item is Map) {
            loaded.add(Practical.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        practicals = loaded;
        isLoading = false;
        if (loaded.isNotEmpty) {
          selectedPracticalIndex = 0;
          selectedPractical = loaded[0];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void selectPractical(int index) {
    if (index < 0 || index >= practicals.length) return;
    setState(() {
      selectedPracticalIndex = index;
      selectedPractical = practicals[index];
    });
  }

  void toggleLeftPanel() => setState(() => leftPanelOpen = !leftPanelOpen);
  void toggleRightPanel() => setState(() => rightPanelOpen = !rightPanelOpen);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xff0B0E1B),
        gradient: RadialGradient(
          center: Alignment(-0.8, -0.6),
          radius: 1.2,
          colors: [
            Color(0xff2A1B54),
            Color(0xff0B0E1B),
          ],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: leftPanelOpen ? leftPanelWidth : 0,
            child: ClipRect(
              child: OverflowBox(
                minWidth: leftPanelWidth,
                maxWidth: leftPanelWidth,
                alignment: Alignment.topLeft,
                child: _buildModules(),
              ),
            ),
          ),
          if (leftPanelOpen) const SizedBox(width: 12),
          Expanded(
            child: _buildSceneArea(),
          ),
          if (rightPanelOpen) const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: rightPanelOpen ? rightPanelWidth : 0,
            child: ClipRect(
              child: OverflowBox(
                minWidth: rightPanelWidth,
                maxWidth: rightPanelWidth,
                alignment: Alignment.topRight,
                child: InstructionsPanel(
                  practical: selectedPractical,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModules() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
    }
    if (error.isNotEmpty) {
      return Center(
        child: Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
      );
    }
    return ExperimentModules(
      practicals: practicals,
      selectedIndex: selectedPracticalIndex,
      onSelected: selectPractical,
    );
  }

  Widget _buildSceneArea() {
    return Stack(
      children: [
        Positioned.fill(child: _buildScene()),
        Positioned(
          left: -4,
          top: 0,
          bottom: 0,
          child: Center(
            child: _panelArrow(
              icon: leftPanelOpen ? Icons.chevron_left : Icons.chevron_right,
              onTap: toggleLeftPanel,
            ),
          ),
        ),
        Positioned(
          right: -4,
          top: 0,
          bottom: 0,
          child: Center(
            child: _panelArrow(
              icon: rightPanelOpen ? Icons.chevron_right : Icons.chevron_left,
              onTap: toggleRightPanel,
            ),
          ),
        ),
      ],
    );
  }

  Widget _panelArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xff1A173B),
      elevation: 6,
      shape: CircleBorder(
        side: BorderSide(color: Colors.purpleAccent.withOpacity(0.4), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 26,
            color: Colors.cyanAccent,
          ),
        ),
      ),
    );
  }

  Widget _buildScene() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff121026).withOpacity(0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildSelectedScene(),
    );
  }

  Widget _buildSelectedScene() {
    if (selectedPractical == null) {
      return const Center(
        child: Text(
          "Select a practical",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70),
        ),
      );
    }

    switch (selectedPractical!.id) {
      case "P01":
        return P01PHScene(practical: selectedPractical!);
      case "P02":
        return P02ReactionScene(practical: selectedPractical!);
      case "P03":
        return P03ReactivityScene(practical: selectedPractical!);
      case "P08":
        return P08AceticAcidScene(practical: selectedPractical!);
      case "P09":
        return P09SoapScene(practical: selectedPractical!);
      default:
        return const Center(
          child: Text("Practical Scene in development", style: TextStyle(color: Colors.white54)),
        );
    }
  }
}