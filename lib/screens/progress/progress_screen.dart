import 'package:flutter/material.dart';
import '../../services/test_series_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final TestSeriesService _testSeriesService = TestSeriesService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _dashboard;

  Map<String, dynamic>? _recommendation;
  bool _recommendationLoading = false;
  
  // LEARNOVA COLORS

  static const Color backgroundColor = Color(0xff0B0E1B);
  static const Color cardColor = Color(0xff1A173B);
  static const Color secondaryCardColor = Color(0xff121026);
  static const Color purpleColor = Color(0xff6C5CE7);
  static const Color cyanColor = Colors.cyanAccent;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _loading = true;
      _error = null;
      _recommendation = null;
    });

    try {
      final data =
      await _testSeriesService.getProgressDashboard();

      if (!mounted) return;

      setState(() {
        _dashboard = data;
        _loading = false;
      });

      // LOAD PERSONALIZED RECOMMENDATION

      final latestTest =
          (data["latestTest"] as Map?)
              ?.cast<String, dynamic>() ??
              {};

      final subject =
      latestTest["subject"]?.toString();

      final chapter =
      latestTest["chapter"]?.toString();

      if (subject != null &&
          subject.isNotEmpty &&
          chapter != null &&
          chapter.isNotEmpty) {
        await _loadRecommendation(
          subject: subject,
          chapter: chapter,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
  Future<void> _loadRecommendation({
    required String subject,
    required String chapter,
  }) async {
    if (!mounted) return;

    setState(() {
      _recommendationLoading = true;
    });

    try {
      final data =
      await _testSeriesService.getTestRecommendation(
        subject: subject,
        chapter: chapter,
      );

      if (!mounted) return;

      setState(() {
        _recommendation = data;
        _recommendationLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _recommendationLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "My Progress",
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: _buildBody(),
    );
  }

  
  // BODY
  

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: cyanColor,
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_dashboard == null) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: cyanColor,
      backgroundColor: cardColor,
      onRefresh: _loadProgress,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallSection(),

            const SizedBox(height: 24),

            _buildSectionTitle(
              "Subject Progress",
              "See how you are performing in each subject",
            ),

            const SizedBox(height: 12),

            _buildSubjectProgress(),

            const SizedBox(height: 24),

            _buildSectionTitle(
              "Performance Trend",
              "Your recent test scores",
            ),

            const SizedBox(height: 12),

            _buildPerformanceTrend(),

            const SizedBox(height: 24),

            _buildSectionTitle(
              "Weak Topics",
              "Topics that need more practice",
            ),

            const SizedBox(height: 12),

            _buildWeakTopics(),

            _buildPersonalizedLearning(),

            const SizedBox(height: 24),
            const SizedBox(height: 24),

            _buildSectionTitle(
              "Recent Tests",
              "Your latest Test Series attempts",
            ),

            const SizedBox(height: 12),

            _buildRecentTests(),
          ],
        ),
      ),
    );
  }

  
  // SECTION TITLE
  

  Widget _buildSectionTitle(
      String title,
      String subtitle,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  
  // OVERALL PERFORMANCE
  

  Widget _buildOverallSection() {
    final overall =
        (_dashboard?["overall"] as Map?)?.cast<String, dynamic>() ??
            {};

    final int testsCompleted =
    _toInt(overall["testsCompleted"]);

    final double averageScore =
    _toDouble(overall["averageScore"]);

    final double highestScore =
    _toDouble(overall["highestScore"]);

    final double latestScore =
    _toDouble(overall["latestScore"]);

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
          color: purpleColor.withOpacity(0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: purpleColor.withOpacity(0.12),
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
                      cyanColor,
                      purpleColor,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: purpleColor.withOpacity(0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: backgroundColor,
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
                  value: "${averageScore.toStringAsFixed(0)}%",
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _statCard(
                  icon: Icons.emoji_events_rounded,
                  title: "Best",
                  value: "${highestScore.toStringAsFixed(0)}%",
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
                  color: cyanColor,
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
                    color: cyanColor,
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

  
  // FIRST TEST EMPTY STATE
  

  Widget _buildFirstTestCard() {
    final subjects =
        (_dashboard?["subjects"] as Map?)?.cast<String, dynamic>() ??
            {};

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
          color: purpleColor.withOpacity(0.30),
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
                  cyanColor,
                  purpleColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: purpleColor.withOpacity(0.3),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: backgroundColor,
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

            ...subjects.entries.map(
                  (entry) {
                final subjectData =
                    (entry.value as Map?)?.cast<String, dynamic>() ??
                        {};

                final level =
                    subjectData["currentLevel"]?.toString() ??
                        "beginner";

                return _levelRow(
                  entry.key,
                  level,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  
  // STAT CARD
  

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
            color: cyanColor,
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

  
  // SUBJECT PROGRESS
  

  Widget _buildSubjectProgress() {
    final subjects =
        (_dashboard?["subjects"] as Map?)?.cast<String, dynamic>() ??
            {};

    if (subjects.isEmpty) {
      return _smallEmptyCard(
        Icons.menu_book_outlined,
        "No subject progress yet",
      );
    }

    return Column(
      children: subjects.entries.map(
            (entry) {
          final data =
              (entry.value as Map?)?.cast<String, dynamic>() ??
                  {};

          final double average =
          _toDouble(data["averageScore"]);

          final int tests =
          _toInt(data["testsCompleted"]);

          final String level =
              data["currentLevel"]?.toString() ??
                  "beginner";

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(15),
            decoration: _cardDecoration(),
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
                            cyanColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Text(
                      "${average.toStringAsFixed(0)}%",
                      style: const TextStyle(
                        color: cyanColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }

  
  // PERFORMANCE TREND
  

  Widget _buildPerformanceTrend() {
    final trend =
        (_dashboard?["trend"] as List?) ?? [];

    if (trend.isEmpty) {
      return _smallEmptyCard(
        Icons.show_chart_rounded,
        "Complete tests to see your performance trend",
      );
    }

    final values = trend
        .map((item) {
      if (item is Map) {
        return _toDouble(item["score"]);
      }
      return 0.0;
    })
        .toList();

    final maxScore = values.isEmpty
        ? 100.0
        : values.reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.show_chart_rounded,
                color: cyanColor,
                size: 21,
              ),

              const SizedBox(width: 9),

              const Text(
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
                  maxScore <= 0
                      ? 8.0
                      : (score / 100 * 115)
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
                            "${score.toStringAsFixed(0)}",
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
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  cyanColor,
                                  purpleColor,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: purpleColor
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

  
  // WEAK TOPICS
  

  Widget _buildWeakTopics() {
    final weakTopics =
        (_dashboard?["weakTopics"] as List?) ?? [];

    if (weakTopics.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: cyanColor,
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
      children: weakTopics.map(
            (item) {
          final data =
              (item as Map?)?.cast<String, dynamic>() ??
                  {};

          final topic =
              data["topic"]?.toString() ??
                  "Unknown Topic";

          final accuracy =
          _toDouble(data["accuracy"]);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: purpleColor.withOpacity(0.14),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    color: purpleColor,
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
                        _formatTopic(topic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                          Colors.white.withOpacity(0.08),
                          valueColor:
                          const AlwaysStoppedAnimation(
                            purpleColor,
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
        },
      ).toList(),
    );
  }

  // PERSONALIZED LEARNING

  Widget _buildPersonalizedLearning() {
    if (_recommendationLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cyanColor,
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

    if (_recommendation == null) {
      return const SizedBox.shrink();
    }

    final recommendation =
        (_recommendation?["recommendation"] as Map?)
            ?.cast<String, dynamic>() ??
            {};

    final subject =
        recommendation["subject"]?.toString() ??
            "Subject";

    final chapter =
        recommendation["chapter"]?.toString() ??
            "Chapter";

    final action =
        recommendation["recommendedAction"]?.toString() ??
            "";

    final topic =
    recommendation["recommendedTopic"]?.toString();

    final level =
        recommendation["recommendedLevel"]?.toString() ??
            "beginner";

    final reason =
        recommendation["reason"]?.toString() ??
            "Continue practicing to improve your performance.";

    String title = "Keep Practicing";

    IconData icon = Icons.auto_awesome_rounded;

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
          color: purpleColor.withOpacity(0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: purpleColor.withOpacity(0.10),
            blurRadius: 16,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      cyanColor,
                      purpleColor,
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  color: backgroundColor,
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
              color: cyanColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "$subject • $chapter",
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
              "Focus: ${_formatTopic(topic)}",
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
                color: purpleColor,
                size: 17,
              ),

              const SizedBox(width: 6),

              Text(
                "Recommended level: ${_capitalize(level)}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // RECENT TESTS

  Widget _buildRecentTests() {
    final recentTests =
        (_dashboard?["recentTests"] as List?) ?? [];

    if (recentTests.isEmpty) {
      return _smallEmptyCard(
        Icons.assignment_outlined,
        "Your recent tests will appear here",
      );
    }

    return Column(
      children: recentTests.map(
            (item) {
          final data =
              (item as Map?)?.cast<String, dynamic>() ??
                  {};

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
          _toDouble(data["score"]);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                _subjectIcon(subject),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        chapter,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        _capitalize(level),
                        style: const TextStyle(
                          color: cyanColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _scoreColor(score)
                        .withOpacity(0.12),
                    borderRadius:
                    BorderRadius.circular(10),
                    border: Border.all(
                      color: _scoreColor(score)
                          .withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    "${score.toStringAsFixed(0)}%",
                    style: TextStyle(
                      color: _scoreColor(score),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }

  
  // SUBJECT ICON
  

  Widget _subjectIcon(String subject) {
    IconData icon = Icons.menu_book_rounded;

    final normalized = subject.toLowerCase();

    if (normalized.contains("math")) {
      icon = Icons.calculate_rounded;
    } else if (normalized.contains("science")) {
      icon = Icons.science_rounded;
    } else if (normalized.contains("physics")) {
      icon = Icons.bolt_rounded;
    } else if (normalized.contains("chemistry")) {
      icon = Icons.science_outlined;
    } else if (normalized.contains("english")) {
      icon = Icons.translate_rounded;
    } else if (normalized.contains("biology")) {
      icon = Icons.biotech_rounded;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cyanColor.withOpacity(0.18),
            purpleColor.withOpacity(0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: purpleColor.withOpacity(0.20),
        ),
      ),
      child: Icon(
        icon,
        color: cyanColor,
        size: 22,
      ),
    );
  }

  
  // LEVEL BADGE
  

  Widget _levelBadge(String level) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: purpleColor.withOpacity(0.14),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: purpleColor.withOpacity(0.25),
        ),
      ),
      child: Text(
        _capitalize(level),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  
  // LEVEL ROW
  

  Widget _levelRow(
      String subject,
      String level,
      ) {
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
              subject,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          _levelBadge(level),
        ],
      ),
    );
  }

  
  // EMPTY CARD
  

  Widget _smallEmptyCard(
      IconData icon,
      String message,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white38,
            size: 22,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  // ERROR
  

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: purpleColor.withOpacity(0.12),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: cyanColor,
                size: 32,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Couldn't load your progress",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _error ?? "Something went wrong.",
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _loadProgress,
              style: ElevatedButton.styleFrom(
                backgroundColor: purpleColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Try Again",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  // EMPTY STATE
  

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "Your progress will appear here.",
        style: TextStyle(
          color: Colors.white60,
          fontSize: 14,
        ),
      ),
    );
  }

  
  // CARD DECORATION
  

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: cardColor.withOpacity(0.72),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(
        color: Colors.white.withOpacity(0.07),
      ),
    );
  }

  // HELPERS

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;

    return value[0].toUpperCase() +
        value.substring(1).toLowerCase();
  }

  String _formatTopic(String topic) {
    return topic
        .replaceAll("_", " ")
        .replaceAll("-", " ")
        .split(" ")
        .map((word) {
      if (word.isEmpty) return word;

      return word[0].toUpperCase() +
          word.substring(1).toLowerCase();
    })
        .join(" ");
  }

  Color _scoreColor(double score) {
    if (score >= 75) {
      return cyanColor;
    }

    if (score >= 40) {
      return Colors.orangeAccent;
    }

    return Colors.redAccent;
  }
}