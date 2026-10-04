import 'package:flutter/material.dart';

import '../progress_helpers.dart';

class TopicPerformance extends StatelessWidget {
  final Map<String, dynamic> dashboard;

  const TopicPerformance({
    super.key,
    required this.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    final weakTopics =
        (dashboard["weakTopics"] as List?) ?? [];

    if (weakTopics.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: cardDecoration(),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.purpleAccent,
              size: 24,
            ),

            SizedBox(width: 12),

            Expanded(
              child: Text(
                "No weak topics identified yet. Keep practicing!",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: weakTopics.map((item) {
        final data =
            (item as Map?)?.cast<String, dynamic>() ?? {};

        final topic =
            data["topic"]?.toString() ?? "Unknown Topic";

        final accuracy =
        toDouble(data["accuracy"]);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.purpleAccent
                      .withOpacity(0.14),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: Colors.purpleAccent,
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatTopic(topic),
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 7),

                    ClipRRect(
                      borderRadius:
                      BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value:
                        (accuracy / 100)
                            .clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor:
                        Colors.white
                            .withOpacity(0.08),
                        valueColor:
                        const AlwaysStoppedAnimation(
                          Colors.purpleAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Text(
                "${accuracy.toStringAsFixed(0)}%",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}