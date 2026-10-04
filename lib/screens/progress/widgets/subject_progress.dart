import 'package:flutter/material.dart';

import '../progress_helpers.dart';

class SubjectProgress extends StatelessWidget {
  final Map<String, dynamic> dashboard;

  const SubjectProgress({
    super.key,
    required this.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    final subjects =
        (dashboard["subjects"] as Map?)?.cast<String, dynamic>() ?? {};

    if (subjects.isEmpty) {
      return _emptyCard();
    }

    return Column(
      children: subjects.entries.map((entry) {
        final data =
            (entry.value as Map?)?.cast<String, dynamic>() ?? {};

        final double average =
        toDouble(data["averageScore"]);

        final int tests =
        toInt(data["testsCompleted"]);

        final String level =
            data["currentLevel"]?.toString() ?? "beginner";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  _subjectIcon(entry.key),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "$tests test${tests == 1 ? '' : 's'} completed",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _levelBadge(level),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                      BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value:
                        (average / 100).clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor:
                        Colors.white.withOpacity(0.08),
                        valueColor:
                        const AlwaysStoppedAnimation(
                          Colors.cyanAccent,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Text(
                    "${average.toStringAsFixed(0)}%",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _subjectIcon(String subject) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyanAccent.withOpacity(0.18),
            Colors.purpleAccent.withOpacity(0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(0.20),
        ),
      ),
      child: Icon(
        subjectIcon(subject),
        color: Colors.purpleAccent,
        size: 22,
      ),
    );
  }

  Widget _levelBadge(String level) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.purpleAccent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(0.25),
        ),
      ),
      child: Text(
        capitalize(level),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: const Row(
        children: [
          Icon(
            Icons.menu_book_outlined,
            color: Colors.white38,
            size: 22,
          ),
          SizedBox(width: 12),
          Text(
            "No subject progress yet",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}