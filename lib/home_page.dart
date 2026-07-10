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

  String userName = "User";

  String currentSubject = "Science";
  String currentChapter = "Chapter 1";
  String currentTopic = "Introduction";

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

  Widget menuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(18),

      child: Container(

        decoration: BoxDecoration(

          color: const Color(0xffBDEFFF),

          borderRadius: BorderRadius.circular(18),

        ),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(
              icon,
              size: 65,
              color: const Color(0xff081062),
            ),

            const SizedBox(height: 15),

            Text(

              title,

              style: const TextStyle(

                fontSize: 17,

                fontWeight: FontWeight.bold,

                color: Color(0xff081062),

              ),

            ),

          ],

        ),

      ),

    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

        body: Container(

        width: double.infinity,

        height: double.infinity,

        decoration: const BoxDecoration(

        gradient: LinearGradient(

        colors: [

        Color(0xff8BEAFB),

    Color(0xff081062),

    ],

    begin: Alignment.topCenter,

    end: Alignment.bottomCenter,

    ),

    ),

    child: SafeArea(

    child: Padding(

    padding: const EdgeInsets.symmetric(horizontal: 20),

    child: Column(

    crossAxisAlignment: CrossAxisAlignment.start,

    children: [

    const SizedBox(height: 15),

    Row(

    mainAxisAlignment:
    MainAxisAlignment.spaceBetween,

    children: [

    Column(

    crossAxisAlignment:
    CrossAxisAlignment.start,

    children: [

    const Text(

    "Welcome Back 👋",

    style: TextStyle(

    fontSize: 18,

    color: Colors.white70,

    ),

    ),

    const SizedBox(height: 5),

    Text(

    userName,

    style: const TextStyle(

    fontSize: 28,

    fontWeight: FontWeight.bold,

    color: Colors.white,

    ),

    ),

    ],

    ),

      Row(
        children: [

          IconButton(
            onPressed: () {

              Navigator.pushNamed(
                context,
                "/profile",
              );

            },
            icon: const Icon(
              Icons.account_circle,
              color: Colors.white,
              size: 38,
            ),
          ),

          IconButton(
            onPressed: logout,
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
          ),

        ],
      ),

    ],

    ),

    const SizedBox(height: 20),

    TextField(

    decoration: InputDecoration(

    hintText: "Search Subjects...",

    prefixIcon: const Icon(Icons.search),

    filled: true,

    fillColor: Colors.white,

    border: OutlineInputBorder(

    borderRadius:
    BorderRadius.circular(15),

    borderSide: BorderSide.none,

    ),

    ),

    ),

    const SizedBox(height: 25),

    Container(

    width: double.infinity,

    padding: const EdgeInsets.all(20),

    decoration: BoxDecoration(

    color: const Color(0xffC7F1FF),

    borderRadius:
    BorderRadius.circular(18),

    ),

    child: Column(

    crossAxisAlignment:
    CrossAxisAlignment.start,

    children: [

    const Text(

    "Continue Learning",

    style: TextStyle(

    fontSize: 20,

    fontWeight: FontWeight.bold,

    ),

    ),

    const SizedBox(height: 15),

    Text(
    currentSubject,
    style: const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    ),
    ),

    const SizedBox(height: 5),

    Text(currentChapter),

    Text(currentTopic),

    const SizedBox(height: 15),

      ElevatedButton(
        onPressed: () {

          Navigator.pushNamed(
            context,
            "/topics",
          );

        },

        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff081062),
        ),

        child: const Text(
          "Continue",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

    ],

    ),

    ),

    const SizedBox(height: 25),

    const Text(

    "Explore",

    style: TextStyle(

    fontSize: 22,

    fontWeight: FontWeight.bold,

    color: Colors.white,

    ),

    ),

    const SizedBox(height: 15),

    Expanded(

    child: GridView.count(

    crossAxisCount: 2,

    crossAxisSpacing: 18,

    mainAxisSpacing: 18,

    children: [
      menuCard(
        icon: Icons.menu_book_rounded,
        title: "Subjects",
        onTap: () {
          Navigator.pushNamed(
            context,
            "/subjects",
          );
        },
      ),

      menuCard(
        icon: Icons.smart_toy_outlined,
        title: "AI Assistant",
        onTap: () {
          Navigator.pushNamed(
            context,
            "/assistant",
          );
        },
      ),

      menuCard(
        icon: Icons.quiz_outlined,
        title: "Test Series",
        onTap: () {
          Navigator.pushNamed(
            context,
            "/tests",
          );
        },
      ),

      menuCard(
        icon: Icons.dashboard_outlined,
        title: "Dashboard",
        onTap: () {
          Navigator.pushNamed(
            context,
            "/dashboard",
          );
        },
      ),
    ],
    ),
    ),
    ],
    ),
    ),
    ),
        ),

      bottomNavigationBar: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),

        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceEvenly,

          children: [

            bottomItem(
              index: 0,
              icon: Icons.home,
              label: "Home",
              onTap: () {},
            ),

            bottomItem(
              index: 1,
              icon: Icons.menu_book,
              label: "Subjects",
              onTap: () {
                Navigator.pushNamed(
                  context,
                  "/subjects",
                );
              },
            ),

            bottomItem(
              index: 2,
              icon: Icons.quiz,
              label: "Tests",
              onTap: () {
                Navigator.pushNamed(
                  context,
                  "/tests",
                );
              },
            ),

            bottomItem(
              index: 3,
              icon: Icons.dashboard,
              label: "Dashboard",
              onTap: () {
                Navigator.pushNamed(
                  context,
                  "/dashboard",
                );
              },
            ),

            bottomItem(
              index: 4,
              icon: Icons.person,
              label: "Profile",
              onTap: () {
                Navigator.pushNamed(
                  context,
                  "/profile",
                );
              },
            ),

          ],
        ),
      ),
    );
  }

  Widget bottomItem({

    required int index,

    required IconData icon,

    required String label,

    required VoidCallback onTap,

  }) {

    bool selected = selectedIndex == index;

    return InkWell(

      onTap: () {

        setState(() {

          selectedIndex = index;

        });

        onTap();

      },

      child: Column(

        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [

          Icon(

            icon,

            size: 28,

            color: selected
                ? Colors.blue
                : const Color(0xff081062),

          ),

          const SizedBox(height: 3),

          Text(

            label,

            style: TextStyle(

              fontSize: 12,

              color: selected
                  ? Colors.blue
                  : const Color(0xff081062),

            ),

          ),

        ],

      ),

    );

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
      currentSubject =
          data["lastSubject"] ?? "Science";

      currentChapter =
          data["lastChapter"] ?? "Chapter 1";

      currentTopic =
          data["lastTopic"] ?? "Introduction";
    });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/login",
          (route) => false,
    );
  }
}