import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  String userName = "Mahek";
  String currentSubject = "Biology";
  String currentChapter = "Chapter 4";
  String currentTopic = "The Human Heart";
  double progress = 0.65;

  @override
  void initState() {
    super.initState();
    loadUser();
    loadContinueLearning();
  }

  Future<void> loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data()!;
      setState(() {
        userName = data["name"] ?? "User";
      });
    }
  }

  Future<void> loadContinueLearning() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    setState(() {
      currentSubject = data["lastSubject"] ?? "Biology";
      currentChapter = data["lastChapter"] ?? "Chapter 4";
      currentTopic = data["lastTopic"] ?? "The Human Heart";
    });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
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
                _buildSectionHeader("Quick Access"),
                const SizedBox(height: 12),
                _buildQuickAccess(),
                const SizedBox(height: 24),
                _buildSectionHeader("Recommended For You", showSeeAll: true),
                const SizedBox(height: 12),
                _buildRecommendations(),
                const SizedBox(height: 20),
                _buildStreakAndXP(),
                const SizedBox(height: 80), // Padding for floating navbar
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- Header ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Good Evening, $userName 👋",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Welcome back to Learnova\nYour AI Learning Universe",
              style: TextStyle(fontSize: 13, color: Colors.white60),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none, color: Colors.white),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, "/profile"),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.purpleAccent,
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage('assets/profile_placeholder.png'), // Replace with actual image asset or NetworkImage
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  // --- AI Mascot Banner ---
  Widget _buildAIBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xff1E1942).withOpacity(0.8),
            const Color(0xff121026).withOpacity(0.8),
          ],
        ),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hi $userName! 👋",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "What do you want to explore today?",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, "/assistant"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff6C5CE7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Let's Start ", style: TextStyle(color: Colors.white)),
                      Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Bot Icon/Asset Placeholder
          Container(
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xff6C5CE7).withOpacity(0.2),
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 50,
              color: Colors.cyanAccent,
            ),
          ),
        ],
      ),
    );
  }

  // --- Subject Universe Horizontal Scroll ---
  Widget _buildSubjectUniverse() {
    final subjects = [
      {'title': 'Mathematics', 'icon': Icons.functions, 'color': Colors.purpleAccent},
      {'title': 'Science', 'icon': Icons.public, 'color': Colors.lightBlueAccent},
      {'title': 'Chemistry', 'icon': Icons.science, 'color': Colors.pinkAccent},
      {'title': 'Biology', 'icon': Icons.eco, 'color': Colors.greenAccent},
      {'title': 'Programming', 'icon': Icons.code, 'color': Colors.blueAccent},
    ];

    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final item = subjects[index];
          return Container(
            margin: const EdgeInsets.only(right: 14),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        (item['color'] as Color).withOpacity(0.3),
                        Colors.black26,
                      ],
                    ),
                    border: Border.all(
                      color: (item['color'] as Color).withOpacity(0.5),
                    ),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['title'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Continue Journey + Time Freeze Split Cards ---
  Widget _buildJourneySection() {
    return Row(
      children: [
        // Continue Learning Card
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: _glassDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.favorite, color: Colors.redAccent),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentTopic,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "$currentChapter • $currentSubject",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Next: Blood Circulation",
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9),
                    ),
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, "/topics"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xff6C5CE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text("Continue ->", style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Time Freeze Card
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: _glassDecoration(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Time Freeze",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  "Freeze any process and explore step by step",
                  style: TextStyle(color: Colors.white54, fontSize: 9),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(Icons.hourglass_bottom, color: Colors.purpleAccent, size: 24),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  // --- Quick Access Tools ---
  Widget _buildQuickAccess() {
    final tools = [
      {'title': 'Voice Your\nDoubt', 'icon': Icons.mic_none},
      {'title': 'Teach Me\nBack', 'icon': Icons.record_voice_over_outlined},
      {'title': 'Consequence\nLab', 'icon': Icons.science_outlined},
      {'title': 'Dream Lab\n(Simulations)', 'icon': Icons.blur_on},
      {'title': 'MCQ\nPractice', 'icon': Icons.fact_check_outlined},
    ];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(8),
            decoration: _glassDecoration(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tool['icon'] as IconData, color: Colors.cyanAccent, size: 22),
                const SizedBox(height: 6),
                Text(
                  tool['title'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Recommended For You ---
  Widget _buildRecommendations() {
    final items = [
      {'title': 'Why Lightning Bends?', 'tag': 'STORY', 'time': '8 min read', 'color': Colors.purple},
      {'title': 'Make a Volcano Erupt', 'tag': 'EXPERIMENT', 'time': '12 min', 'color': Colors.orange},
      {'title': 'Cell Structure Quiz', 'tag': 'QUIZ', 'time': '15 Questions', 'color': Colors.green},
    ];

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(10),
            decoration: _glassDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item['tag'] as String,
                    style: TextStyle(color: item['color'] as Color, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  item['title'] as String,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  item['time'] as String,
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Streak and XP Progress Footer ---
  Widget _buildStreakAndXP() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _glassDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.orangeAccent),
              SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("12", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("Day Streak", style: TextStyle(color: Colors.white38, fontSize: 9)),
                ],
              ),
            ],
          ),
          Row(
            children: List.generate(
              6,
                  (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < 4 ? Colors.orangeAccent : Colors.white12,
                ),
              ),
            ),
          ),
          const Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("420", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("XP Points", style: TextStyle(color: Colors.white38, fontSize: 9)),
                ],
              ),
              SizedBox(width: 6),
              Icon(Icons.star, color: Colors.purpleAccent),
            ],
          ),
        ],
      ),
    );
  }

  // --- Bottom Navigation Bar ---
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xff121026),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home_filled, "Home"),
          _navItem(1, Icons.menu_book, "Learn"),
          // Center AI Tutor Button
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, "/assistant"),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.cyanAccent, Colors.purpleAccent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.4),
                    blurRadius: 10,
                  )
                ],
              ),
              child: const Icon(Icons.smart_toy, color: Colors.black, size: 26),
            ),
          ),
          _navItem(3, Icons.insert_chart_outlined, "Progress"),
          _navItem(4, Icons.person_outline, "Profile"),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => selectedIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.purpleAccent : Colors.white38, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.purpleAccent : Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---
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