import 'package:flutter/material.dart';

import '../progress_helpers.dart';

class PerformanceTrend extends StatelessWidget {
  final Map<String, dynamic> dashboard;

  const PerformanceTrend({
    super.key,
    required this.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    final trend =
        (dashboard["trend"] as List?) ?? [];

    if (trend.isEmpty) {
      return _emptyCard();
    }

    final values = trend.map((item) {
      if (item is Map) {
        return toDouble(item["score"]);
      }

      return 0.0;
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                color: Colors.purpleAccent,
                size: 21,
              ),

              SizedBox(width: 9),

              Text(
                "Recent Scores",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.end,
              children: List.generate(
                values.length,
                    (index) {
                  final score = values[index];

                  final height =
                  (score / 100 * 115)
                      .clamp(8.0, 115.0);

                  return Expanded(
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.end,
                        children: [
                          Text(
                            score.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(8),
                              gradient:
                              const LinearGradient(
                                begin:
                                Alignment.topCenter,
                                end:
                                Alignment.bottomCenter,
                                colors: [
                                  Colors.cyanAccent,
                                  Colors.purpleAccent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purpleAccent
                                      .withOpacity(0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "${index + 1}",
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
            Icons.show_chart_rounded,
            color: Colors.white38,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Complete tests to see your performance trend",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}