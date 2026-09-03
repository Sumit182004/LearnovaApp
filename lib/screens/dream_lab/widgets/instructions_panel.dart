import 'package:flutter/material.dart';
import '../models/practical_model.dart';

class InstructionsPanel extends StatelessWidget {
  final Practical? practical;

  const InstructionsPanel({
    super.key,
    required this.practical,
  });

  @override
  Widget build(BuildContext context) {
    if (practical == null) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xff121026).withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: const Center(
          child: Text(
            "Select an experiment",
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
      );
    }

    // Safely extract whatever description or step list exists on your model
    final dynamic rawPractical = practical;

    String headerText = practical!.title;
    try {
      if (rawPractical.theory != null && rawPractical.theory.toString().isNotEmpty) {
        headerText = rawPractical.theory.toString();
      }
    } catch (_) {}

    List<String> stepList = [];
    try {
      if (rawPractical.instructions is List && rawPractical.instructions.isNotEmpty) {
        stepList = List<String>.from(rawPractical.instructions.map((e) => e.toString()));
      }
    } catch (_) {}

    if (stepList.isEmpty) {
      try {
        if (rawPractical.steps is List && rawPractical.steps.isNotEmpty) {
          stepList = List<String>.from(rawPractical.steps.map((e) => e.toString()));
        }
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff121026).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.12),
            blurRadius: 16,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: const [
                Icon(Icons.menu_book, size: 16, color: Colors.purpleAccent),
                SizedBox(width: 6),
                Text(
                  "Instructions",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.08)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xff1A173B).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
                  ),
                  child: Text(
                    headerText,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "STEPS",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                if (stepList.isEmpty)
                  const Text(
                    "Follow the on-screen experimental apparatus to complete the trial.",
                    style: TextStyle(fontSize: 10, color: Colors.white54),
                  )
                else
                  ...stepList.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final step = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xff6C5CE7),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "$idx",
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Colors.white70,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}