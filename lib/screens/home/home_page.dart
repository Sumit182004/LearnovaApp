import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnovaapp/screens/ai_assistant/ai_assistant_screen.dart';
import 'package:learnovaapp/screens/dream_lab/Dream_lab_Screen.dart';
import 'package:learnovaapp/services/test_series_service.dart';
import '../chapters/chapters_screen.dart';
import '../test_series/test_series_screen.dart';
import '../progress/progress_screen.dart';
import '../progress/widgets/personalized_learning.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int selectedIndex = 0;

  String userName = "Student";
  String userStandard = "class10";
// Continue Learning data
  String? currentSubject;
  String? currentChapter;
  String? currentTopic;
  double? currentProgress;
  Map<String, dynamic>? _progressDashboard;
  Map<String, dynamic>? _homeRecommendation;

  bool _isHomeDataLoading = true;
  Future<void> _loadHomeLearningData() async {
    if (!mounted) return;

    setState(() {
      _isHomeDataLoading = true;
    });

    try {
      final dashboard =
      await TestSeriesService().getProgressDashboard();

      final latestTest = dashboard['latestTest'];

      Map<String, dynamic>? recommendation;

      if (latestTest != null &&
          latestTest['subject'] != null &&
          latestTest['chapter'] != null) {
        recommendation =
        await TestSeriesService().getTestRecommendation(
          subject: latestTest['subject'].toString(),
          chapter: latestTest['chapter'].toString(),
        );
      }

      if (!mounted) return;

      setState(() {
        _progressDashboard = dashboard;
        _homeRecommendation = recommendation;
        _isHomeDataLoading = false;
      });
    } catch (e) {
      debugPrint('Home learning data error: $e');

      if (!mounted) return;

      setState(() {
        _isHomeDataLoading = false;
      });
    }
  }
// Loading state
  bool isLoadingUser = true;

  late AnimationController _robotController;
  late Animation<Offset> _robotAnimation;
  List<Map<String, dynamic>> get subjects {
    if (userStandard == "class12") {
      return [
        {
          "title": "Planet Mathematics",
          "folder": "maths",
          "asset": "assets/Maths_3D.png",
          "glowColor": Colors.lightBlueAccent,
        },
        {
          "title": "Planet Physics",
          "folder": "physics",
          "asset": "assets/Physics_3D.png",
          "glowColor": Colors.cyanAccent,
        },
        {
          "title": "Planet Chemistry",
          "folder": "chemistry",
          "asset": "assets/Chemistry_3D.png",
          "glowColor": Colors.orangeAccent,
        },
        {
          "title": "English",
          "folder": "english",
          "asset": null,
          "glowColor": Colors.purpleAccent,
        },
      ];
    }

    return [
      {
        "title": "Planet Mathematics",
        "folder": "maths",
        "asset": "assets/Maths_3D.png",
        "glowColor": Colors.lightBlueAccent,
      },
      {
        "title": "Planet Physics",
        "folder": "physics",
        "asset": "assets/Physics_3D.png",
        "glowColor": Colors.cyanAccent,
      },
      {
        "title": "Planet Chemistry",
        "folder": "chemistry",
        "asset": "assets/Chemistry_3D.png",
        "glowColor": Colors.orangeAccent,
      },
      {
        "title": "Planet Biology",
        "folder": "biology",
        "asset": "assets/Biology_3D.png",
        "glowColor": Colors.greenAccent,
      },
      {
        "title": "English",
        "folder": "english",
        "asset": null,
        "glowColor": Colors.purpleAccent,
      },
    ];
  }
  @override
  void initState() {
    super.initState();
    loadUser();
    _loadHomeLearningData();
    _robotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _robotAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.06),
    ).animate(CurvedAnimation(
      parent: _robotController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _robotController.dispose();
    super.dispose();
  }

  Future<void> loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() => isLoadingUser = false);
      }
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!mounted) return;
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        final standard = (data["standard"] ?? "class10")
            .toString()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '');
        final savedProgress = double.tryParse(
          data["lastProgress"]?.toString() ?? "",
        );
        setState(() {
          userName = data["name"]?.toString() ?? "Student";
          userStandard = standard;
          currentSubject = data["lastSubject"]?.toString();
          currentChapter = data["lastChapter"]?.toString();
          currentTopic = data["lastTopic"]?.toString();
          currentProgress = savedProgress == null
              ? null
              : savedProgress.clamp(0.0, 1.0).toDouble();

          isLoadingUser = false;
        });
      } else {
        setState(() => isLoadingUser = false);
      }
    } catch (e) {
      debugPrint("Home page loading error: $e");

      if (mounted) {
        setState(() => isLoadingUser = false);
      }
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
  }

  void openSubject(String subject) {
    String folder = subject.toLowerCase().trim();

    if (folder == "mathematics" || folder == "math") {
      folder = "maths";
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChaptersScreen(
          className: userStandard,
          subject: folder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B0E1B),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.2,
            colors: [
              Color(0xff2A1B54),
              Color(0xff0B0E1B),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildAIBanner(),
                const SizedBox(height: 24),
                _buildSectionHeader("Explore Subjects"),
                const SizedBox(height: 12),
                _buildSubjectUniverse(),
                const SizedBox(height: 24),
                _buildSectionHeader("Continue Your Journey"),
                const SizedBox(height: 12),
                _buildJourneySection(),
                const SizedBox(height: 24),
                _buildSectionHeader("Your Performance"),
                const SizedBox(height: 12),
                _buildHomePerformance(),
                const SizedBox(height: 24),
                _buildSectionHeader("Quick Access"),
                _buildQuickAccess(),
                const SizedBox(height: 24),
                _buildSectionHeader("Recommended For You"),
                const SizedBox(height: 12),
                _buildRecommendations(),
                const SizedBox(height: 20),

              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Good Evening, $userName 👋",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Welcome back to Learnova\nYour AI Learning Universe",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, "/profile"),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.purpleAccent,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAIBanner() {
    return SizedBox(
      height: 175,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  const Color(0xff1E1942).withOpacity(0.8),
                  const Color(0xff121026).withOpacity(0.8),
                ],
              ),
              border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Hi $userName! 👋",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "What do you want to explore today?",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, "/assistant"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff6C5CE7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Let's Start ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(flex: 2, child: SizedBox()),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: 5,
            child: SlideTransition(
              position: _robotAnimation,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AiAssistantScreen(),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: -15,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    "assets/ai_mascot.png",
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectUniverse() {
    final subjectList = subjects;

    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: subjectList.length,
        itemBuilder: (context, index) {
          final subject = subjectList[index];
          final glowColor = subject["glowColor"] as Color;
          final asset = subject["asset"] as String?;

          return GestureDetector(
            onTap: () => openSubject(subject["folder"] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xff121026),
                      border: Border.all(
                        color: glowColor.withOpacity(0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: asset != null
                          ? Image.asset(
                        asset,
                        fit: BoxFit.cover,
                      )
                          : const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.purpleAccent,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subject["title"] as String,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJourneySection() {
    if (isLoadingUser) {
      return Container(
        height: 110,
        decoration: _glassDecoration(),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.cyanAccent,
          ),
        ),
      );
    }

    final hasLearningActivity =
        currentSubject != null && currentSubject!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasLearningActivity
                      ? Icons.menu_book_rounded
                      : Icons.school_rounded,
                  color: Colors.purpleAccent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLearningActivity
                          ? (currentTopic?.isNotEmpty == true
                          ? currentTopic!
                          : "Continue Learning")
                          : "Start Your Learning Journey",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasLearningActivity
                          ? "${currentChapter ?? ''} • $currentSubject"
                          : "Explore your subjects and start learning",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (hasLearningActivity && currentProgress != null) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: currentProgress,
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.indigoAccent,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 5),
            Text(
              "${(currentProgress! * 100).round()}% completed",
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ],

          const SizedBox(height: 14),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                if (hasLearningActivity) {
                  openSubject(currentSubject!);
                } else {
                  openSubject(subjects.first["folder"] as String);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff6C5CE7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                hasLearningActivity
                    ? "Continue Learning →"
                    : "Explore Subjects →",
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess() {
    final tools = [
      {
        "title": "AI\nAssistant",
        "icon": Icons.smart_toy_outlined,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AiAssistantScreen(),
            ),
          );
        },
      },
      {
        "title": "Virtual\nLab",
        "icon": Icons.science_outlined,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DreamLabScreen(),
            ),
          );
        },
      },
      {
        "title": "Practice\nTest",
        "icon": Icons.fact_check_outlined,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TestSeriesScreen(),
            ),
          );
        },
      },
      {
        "title": "My\nProgress",
        "icon": Icons.analytics_outlined,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProgressScreen(),
            ),
          );
        },
      },
    ];

    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];

          return GestureDetector(
            onTap: tool["onTap"] as VoidCallback,
            child: Container(
              width: 82,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: _glassDecoration(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tool["icon"] as IconData,
                    color: Colors.cyanAccent,
                    size: 24,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    tool["title"] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendations() {
    if (_isHomeDataLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_homeRecommendation == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _glassDecoration(),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personalized Learning',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Complete a practice test to receive '
                  'personalized learning recommendations.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return PersonalizedLearning(
      recommendation: _homeRecommendation,
      loading: false,
    );
  }
  Widget _buildHomePerformance() {
    final overall =
    _progressDashboard?['overall']
    as Map<String, dynamic>?;

    if (overall == null) {
      return const SizedBox.shrink();
    }
    final testsCompleted = overall['testsCompleted'] ?? 0;
    final averageScore = overall['averageScore'];
    final highestScore = overall['highestScore'];

    Widget buildStat(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _glassDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        buildStat(
          'Tests Completed',
          '$testsCompleted',
        ),
        const SizedBox(width: 10),
        buildStat(
          'Average Score',
          averageScore == null
              ? '--'
              : '${averageScore}%',
        ),
        const SizedBox(width: 10),
        buildStat(
          'Best Score',
          highestScore == null
              ? '--'
              : '${highestScore}%',
        ),
      ],
    );
  }


  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff121026),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // HOME
              _navItem(
                index: 0,
                icon: Icons.home_filled,
                label: "Home",
                onTap: () {
                  setState(() => selectedIndex = 0);
                },
              ),

              // LEARN
              _navItem(
                index: 1,
                icon: Icons.menu_book,
                label: "Learn",
                  onTap: () {
                    setState(() => selectedIndex = 1);
                    openSubject(subjects.first["folder"] as String);
                  },
              ),

              // AI ASSISTANT
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => selectedIndex = 2);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AiAssistantScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.cyanAccent,
                            Color(0xff6C5CE7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff6C5CE7)
                                .withOpacity(0.5),
                            blurRadius: 14,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: Color(0xff0B0E1B),
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),

              // MCQ PRACTICE
              _navItem(
                index: 3,
                icon: Icons.fact_check_outlined,
                label: "MCQ",
                onTap: () {
                  setState(() => selectedIndex = 3);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TestSeriesScreen(),
                    ),
                  );
                },
              ),

              // PROGRESS
              _navItem(
                index: 4,
                icon: Icons.insert_chart_outlined,
                label: "Progress",
                onTap: () {
                  setState(() => selectedIndex = 4);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProgressScreen(),
                    ),
                  );
                },

              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final bool isSelected = selectedIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.purpleAccent.withOpacity(0.12),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.cyanAccent : Colors.white38,
                  size: isSelected ? 24 : 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.cyanAccent : Colors.white38,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showSeeAll = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        if (showSeeAll)
          const Text("See All >", style: TextStyle(color: Colors.purpleAccent, fontSize: 12)),
      ],
    );
  }

  BoxDecoration _glassDecoration() {
    return BoxDecoration(
      color: const Color(0xff1A173B).withOpacity(0.6),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    );
  }
}