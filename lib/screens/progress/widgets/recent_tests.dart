import 'package:flutter/material.dart';

import '../progress_helpers.dart';

class RecentTests extends StatelessWidget {
  final Map<String, dynamic> dashboard;

  const RecentTests({
    super.key,
    required this.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    final recentTests =
        (dashboard["recentTests"] as List?) ?? [];

    if (recentTests.isEmpty) {
      return _emptyCard();
    }

    return Column(
      children: recentTests.map((item) {
        final data =
            (item as Map?)?.cast<String, dynamic>() ?? {};

        final subject =
            data["subject"]?.toString() ??
                "Subject";

        final chapter =
            data["chapter"]?.toString() ??
                "Chapter";

        final level =
            data["level"]?.toString() ??
                "beginner";

        final score =
        toDouble(data["score"]);

        return Container(
          margin:
          const EdgeInsets.only(bottom: 10),
          padding:
          const EdgeInsets.all(14),
          decoration:
          cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.cyanAccent
                          .withOpacity(0.18),
                      Colors.purpleAccent
                          .withOpacity(0.18),
                    ],
                  ),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Icon(
                  subjectIcon(subject),
                  color: Colors.purpleAccent,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style:
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      formatChapter(chapter),
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      capitalize(level),
                      style:
                      const TextStyle(
                        color:
                        Colors.purpleAccent,
                        fontSize: 10,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scoreColor(score)
                      .withOpacity(0.12),
                  borderRadius:
                  BorderRadius.circular(10),
                  border: Border.all(
                    color: scoreColor(score)
                        .withOpacity(0.25),
                  ),
                ),
                child: Text(
                  "${score.toStringAsFixed(0)}%",
                  style: TextStyle(
                    color:
                    scoreColor(score),
                    fontSize: 14,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
            Icons.assignment_outlined,
            color: Colors.white38,
            size: 22,
          ),

          SizedBox(width: 12),

          Text(
            "Your recent tests will appear here",
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