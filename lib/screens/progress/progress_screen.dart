import 'package:flutter/material.dart';

import '../../services/test_series_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final TestSeriesService _testSeriesService =
  TestSeriesService();

  bool isLoading = true;
  String? error;

  Map<String, dynamic> dashboard = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }


  // LOAD PROGRESS


  Future<void> _loadProgress() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final data =
      await _testSeriesService.getProgressDashboard();

      if (!mounted) return;

      setState(() {
        dashboard = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }


  // HELPERS


  String _formatLevel(dynamic level) {
    if (level == null) return "Beginner";

    final value = level.toString();

    return value.isEmpty
        ? "Beginner"
        : value[0].toUpperCase() +
        value.substring(1).toLowerCase();
  }

  String _formatScore(dynamic score) {
    if (score == null) return "--";

    return "${double.parse(score.toString()).round()}%";
  }

  String _formatTopic(String topic) {
    return topic
        .replaceAll("_", " ")
        .split(" ")
        .map(
          (word) => word.isEmpty
          ? word
          : word[0].toUpperCase() +
          word.substring(1).toLowerCase(),
    )
        .join(" ");
  }


  // MAIN UI


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "My Progress",
          style: TextStyle(
            color: Color(0xFF222222),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadProgress,
        child: _buildBody(),
      ),
    );
  }


  // BODY


  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 180),

          const Icon(
            Icons.error_outline,
            size: 55,
            color: Colors.redAccent,
          ),

          const SizedBox(height: 16),

          const Center(
            child: Text(
              "Unable to load progress",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: ElevatedButton(
              onPressed: _loadProgress,
              child: const Text("Retry"),
            ),
          ),
        ],
      );
    }

    final overall =
        dashboard["overall"] as Map<String, dynamic>? ?? {};

    final subjects =
        dashboard["subjects"] as Map<String, dynamic>? ?? {};

    final trend =
        dashboard["trend"] as List<dynamic>? ?? [];

    final weakTopics =
        dashboard["weakTopics"] as List<dynamic>? ?? [];

    final recentTests =
        dashboard["recentTests"] as List<dynamic>? ?? [];

    final testsCompleted =
        overall["testsCompleted"] ?? 0;


    // Empty state


    if (testsCompleted == 0) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),

          Icon(
            Icons.auto_graph_rounded,
            size: 80,
            color: Colors.blueGrey.shade300,
          ),

          const SizedBox(height: 24),

          const Text(
            "Your progress will appear here",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "Complete your first Test Series to start "
                "tracking your performance, weak topics "
                "and improvement.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 30),

          if (subjects.isNotEmpty)
            _buildInitialLevels(subjects),
        ],
      );
    }

    // Dashboard

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        30,
      ),
      children: [
        _buildOverallCard(overall),

        const SizedBox(height: 24),

        _buildSectionTitle("Subject Progress"),

        const SizedBox(height: 12),

        _buildSubjects(subjects),

        const SizedBox(height: 28),

        if (trend.isNotEmpty) ...[
          _buildSectionTitle("Performance Trend"),

          const SizedBox(height: 12),

          _buildTrend(trend),

          const SizedBox(height: 28),
        ],

        if (weakTopics.isNotEmpty) ...[
          _buildSectionTitle("Weak Topics"),

          const SizedBox(height: 12),

          _buildWeakTopics(weakTopics),

          const SizedBox(height: 28),
        ],

        if (recentTests.isNotEmpty) ...[
          _buildSectionTitle("Recent Tests"),

          const SizedBox(height: 12),

          _buildRecentTests(recentTests),
        ],
      ],
    );
  }


  // OVERALL CARD


  Widget _buildOverallCard(
      Map<String, dynamic> overall) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E5E0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            "Overall Performance",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildStat(
                  "Tests",
                  "${overall["testsCompleted"] ?? 0}",
                  Icons.assignment_rounded,
                ),
              ),

              Expanded(
                child: _buildStat(
                  "Average",
                  _formatScore(
                    overall["averageScore"],
                  ),
                  Icons.show_chart_rounded,
                ),
              ),

              Expanded(
                child: _buildStat(
                  "Best",
                  _formatScore(
                    overall["highestScore"],
                  ),
                  Icons.emoji_events_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F2),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 20,
                ),

                const SizedBox(width: 10),

                const Text(
                  "Latest Score",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const Spacer(),

                Text(
                  _formatScore(
                    overall["latestScore"],
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // STAT


  Widget _buildStat(
      String title,
      String value,
      IconData icon,
      ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Colors.blueGrey,
        ),

        const SizedBox(height: 8),

        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }


  // SECTION TITLE


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    );
  }


  // SUBJECTS


  Widget _buildSubjects(
      Map<String, dynamic> subjects) {
    return Column(
      children: subjects.entries.map((entry) {
        final subject = entry.key;

        final data =
            entry.value as Map<String, dynamic>? ?? {};

        final tests =
            data["testsCompleted"] ?? 0;

        final average =
        data["averageScore"];

        final level =
        data["currentLevel"];

        final score = average == null
            ? 0.0
            : double.tryParse(
          average.toString(),
        ) ??
            0.0;

        return Container(
          margin: const EdgeInsets.only(
            bottom: 12,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5E5E0),
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                      const Color(0xFFF1F3F2),
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatLevel(level),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
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
                        value: score / 100,
                        minHeight: 8,
                        backgroundColor:
                        const Color(0xFFE9E9E5),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Text(
                    average == null
                        ? "--"
                        : _formatScore(average),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                "$tests test${tests == 1 ? '' : 's'} completed",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }


  // TREND


  Widget _buildTrend(List<dynamic> trend) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E5E0),
        ),
      ),
      child: Column(
        children: trend.map((item) {
          final score =
              double.tryParse(
                item["score"]?.toString() ?? "",
              ) ??
                  0;

          return Padding(
            padding:
            const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 95,
                  child: Text(
                    item["subject"]?.toString() ??
                        "Test",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                Expanded(
                  child: ClipRRect(
                    borderRadius:
                    BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      minHeight: 8,
                      backgroundColor:
                      const Color(0xFFE9E9E5),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                SizedBox(
                  width: 42,
                  child: Text(
                    "${score.round()}%",
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }


  // WEAK TOPICS


  Widget _buildWeakTopics(
      List<dynamic> weakTopics) {
    return Column(
      children: weakTopics.map((item) {
        final accuracy =
            double.tryParse(
              item["accuracy"]?.toString() ?? "",
            ) ??
                0;

        return Container(
          margin: const EdgeInsets.only(
            bottom: 10,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5E5E0),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding:
                const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F0),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.deepOrange,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTopic(
                        item["topic"]?.toString() ??
                            "",
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "${item["subject"] ?? ""} • "
                          "${item["chapter"] ?? ""}",
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                        Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                "${accuracy.round()}%",
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }


  // RECENT TESTS


  Widget _buildRecentTests(
      List<dynamic> tests) {
    return Column(
      children: tests.map((test) {
        return Container(
          margin: const EdgeInsets.only(
            bottom: 10,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5E5E0),
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                child: Icon(
                  Icons.assignment_rounded,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      test["subject"]?.toString() ??
                          "Test",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      test["chapter"]?.toString() ??
                          "",
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                        Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                _formatScore(
                  test["score"],
                ),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }


  // INITIAL ASSESSMENT LEVELS


  Widget _buildInitialLevels(
      Map<String, dynamic> subjects) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          "Your Current Levels",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 12),

        ...subjects.entries.map((entry) {
          return Container(
            margin:
            const EdgeInsets.only(bottom: 10),
            padding:
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(14),
              border: Border.all(
                color:
                const Color(0xFFE5E5E0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _formatLevel(entry.value),
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}