import 'package:flutter/material.dart';

import '../../services/test_series_service.dart';

import 'widgets/overall_performance.dart';
import 'widgets/subject_progress.dart';
import 'widgets/performance_trend.dart';
import 'widgets/topic_performance.dart';
import 'widgets/personalized_learning.dart';
import 'widgets/recent_tests.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() =>
      _ProgressScreenState();
}

class _ProgressScreenState
    extends State<ProgressScreen> {

  final TestSeriesService _testSeriesService =
  TestSeriesService();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _dashboard;

  Map<String, dynamic>? _recommendation;
  bool _recommendationLoading = false;

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
      await _testSeriesService
          .getProgressDashboard();

      if (!mounted) return;

      setState(() {
        _dashboard = data;
        _loading = false;
      });

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
      await _testSeriesService
          .getTestRecommendation(
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
      backgroundColor:
      const Color(0xff0B0E1B),

      appBar: AppBar(
        backgroundColor:
        const Color(0xff0B0E1B),
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

        iconTheme:
        const IconThemeData(
          color: Colors.white,
        ),
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.purpleAccent,
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
      color: Colors.purpleAccent,
      backgroundColor:
      const Color(0xff1A173B),
      onRefresh: _loadProgress,

      child: SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(
          parent:
          BouncingScrollPhysics(),
        ),

        padding:
        const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          30,
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            OverallPerformance(
              dashboard: _dashboard!,
            ),

            const SizedBox(height: 24),

            _sectionTitle(
              "Subject Progress",
              "See how you are performing in each subject",
            ),

            const SizedBox(height: 12),

            SubjectProgress(
              dashboard: _dashboard!,
            ),

            const SizedBox(height: 24),

            _sectionTitle(
              "Performance Trend",
              "Your recent test scores",
            ),

            const SizedBox(height: 12),

            PerformanceTrend(
              dashboard: _dashboard!,
            ),

            const SizedBox(height: 24),

            _sectionTitle(
              "Weak Topics",
              "Topics that need more practice",
            ),

            const SizedBox(height: 12),

            TopicPerformance(
              dashboard: _dashboard!,
            ),

            const SizedBox(height: 24),

            PersonalizedLearning(
              recommendation:
              _recommendation,
              loading:
              _recommendationLoading,
            ),

            const SizedBox(height: 24),

            _sectionTitle(
              "Recent Tests",
              "Your latest Test Series attempts",
            ),

            const SizedBox(height: 12),

            RecentTests(
              dashboard: _dashboard!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(
      String title,
      String subtitle,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(25),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent
                    .withOpacity(0.12),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.purpleAccent,
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
              _error ??
                  "Something went wrong.",
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow:
              TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _loadProgress,

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.purpleAccent,
                foregroundColor:
                Colors.white,
                elevation: 0,

                padding:
                const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),

              child: const Text(
                "Try Again",
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}