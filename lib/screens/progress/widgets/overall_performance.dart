import 'package:flutter/material.dart';

import '../progress_helpers.dart';

class OverallPerformance extends StatelessWidget {
  final Map<String, dynamic> dashboard;

  const OverallPerformance({
    super.key,
    required this.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    final overall =
        (dashboard["overall"] as Map?)?.cast<String, dynamic>() ?? {};

    final int testsCompleted =
    toInt(overall["testsCompleted"]);

    final double averageScore =
    toDouble(overall["averageScore"]);

    final double highestScore =
    toDouble(overall["highestScore"]);

    final double latestScore =
    toDouble(overall["latestScore"]);

    if (testsCompleted == 0) {
      return _buildFirstTestCard();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff211B4A),
            Color(0xff121026),
          ],
        ),
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Colors.cyanAccent,
                      Colors.purpleAccent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Color(0xff0B0E1B),
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Overall Performance",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Keep learning and improving",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.assignment_rounded,
                  title: "Tests",
                  value: "$testsCompleted",
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _statCard(
                  icon: Icons.trending_up_rounded,
                  title: "Average",
                  value:
                  "${averageScore.toStringAsFixed(0)}%",
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _statCard(
                  icon: Icons.emoji_events_rounded,
                  title: "Best",
                  value:
                  "${highestScore.toStringAsFixed(0)}%",
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.speed_rounded,
                  color: Colors.purpleAccent,
                  size: 20,
                ),

                const SizedBox(width: 10),

                const Expanded(
                  child: Text(
                    "Latest Test Score",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),

                Text(
                  "${latestScore.toStringAsFixed(0)}%",
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.purpleAccent,
            size: 19,
          ),

          const SizedBox(height: 7),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstTestCard() {
    final subjects =
        (dashboard["subjects"] as Map?)?.cast<String, dynamic>() ?? {};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff211B4A),
            Color(0xff121026),
          ],
        ),
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(0.30),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Colors.cyanAccent,
                  Colors.purpleAccent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.3),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Color(0xff0B0E1B),
              size: 32,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "Your Progress Starts Here",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            "Complete your first Test Series to start "
                "tracking your learning progress.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.4,
            ),
          ),

          if (subjects.isNotEmpty) ...[
            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Your Current Levels",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            ...subjects.entries.map((entry) {
              final subjectData =
                  (entry.value as Map?)
                      ?.cast<String, dynamic>() ??
                      {};

              final level =
                  subjectData["currentLevel"]?.toString() ??
                      "beginner";

              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      capitalize(level),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}