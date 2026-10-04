import 'package:flutter/material.dart';

import '../progress_helpers.dart';
import '../../test_series/test_series_screen.dart';

class PersonalizedLearning extends StatelessWidget {
  final Map<String, dynamic>? recommendation;
  final bool loading;

  const PersonalizedLearning({
    super.key,
    required this.recommendation,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: cardDecoration(),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.purpleAccent,
              ),
            ),

            SizedBox(width: 12),

            Text(
              "Analyzing your performance...",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (recommendation == null) {
      return const SizedBox.shrink();
    }

    final data =
        (recommendation!["recommendation"] as Map?)
            ?.cast<String, dynamic>() ??
            {};

    final subject =
        data["subject"]?.toString() ?? "Subject";

    final chapter =
        data["chapter"]?.toString() ?? "Chapter";

    final topic =
    data["recommendedTopic"]?.toString();

    final level =
        data["recommendedLevel"]?.toString() ??
            "beginner";

    final action =
        data["recommendedAction"]?.toString() ?? "";

    final reason =
        data["reason"]?.toString() ??
            "Continue practicing to improve your performance.";

    String title = "Keep Practicing";

    IconData icon =
        Icons.auto_awesome_rounded;

    if (action == "practice_weak_topic") {
      title = "Focus on Your Weak Topic";
      icon = Icons.track_changes_rounded;
    } else if (action == "repeat_current_level") {
      title = "Strengthen Your Current Level";
      icon = Icons.replay_rounded;
    } else if (action == "progress_to_next_level") {
      title = "You're Ready to Level Up";
      icon = Icons.trending_up_rounded;
    } else if (action == "practice_current_chapter") {
      title = "Continue Your Learning";
      icon = Icons.menu_book_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff211B4A),
            Color(0xff121026),
          ],
        ),
        border: Border.all(
          color:
          Colors.purpleAccent.withOpacity(0.30),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.purpleAccent.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.cyanAccent,
                      Colors.purpleAccent,
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xff0B0E1B),
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Personalized Learning",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      "Based on your recent performance",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            title,
            style: const TextStyle(
              color: Colors.purpleAccent,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "$subject • ${formatChapter(chapter)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          if (topic != null &&
              topic.isNotEmpty) ...[
            const SizedBox(height: 8),

            Text(
              "Focus: ${formatTopic(topic)}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 8),

          Text(
            reason,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.signal_cellular_alt_rounded,
                color: Colors.purpleAccent,
                size: 17,
              ),

              const SizedBox(width: 6),

              Text(
                "Recommended level: ${capitalize(level)}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TestSeriesScreen(
                          initialSubject: subject,
                          initialChapter: chapter,
                        ),
                  ),
                );
              },
              icon: const Icon(
                Icons.play_arrow_rounded,
                size: 20,
              ),
              label: const Text(
                "Practice Now",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                Colors.purpleAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}