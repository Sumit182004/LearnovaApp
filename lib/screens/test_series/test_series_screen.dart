import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../services/test_series_service.dart';
import 'take_test_screen.dart';

class TestSeriesScreen extends StatefulWidget {
  const TestSeriesScreen({super.key});

  @override
  State<TestSeriesScreen> createState() => _TestSeriesScreenState();
}

class _TestSeriesScreenState extends State<TestSeriesScreen> {
  final TestSeriesService _testSeriesService = TestSeriesService();

  bool isLoadingUser = true;
  bool isLoadingChapters = false;
  bool isGeneratingTest = false;

  String userStandard = "";

  String? selectedSubject;
  String? selectedStorageSubject;
  String? selectedChapter;

  List<String> chapters = [];

  String error = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // ============================================================
  // LOAD USER
  // ============================================================

  Future<void> loadUser() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        setState(() {
          error = "User is not logged in.";
          isLoadingUser = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!doc.exists) {
        setState(() {
          error = "Student profile not found.";
          isLoadingUser = false;
        });
        return;
      }

      final data = doc.data() ?? {};

      final standard = data["standard"]
          ?.toString()
          .toLowerCase()
          .replaceAll(" ", "") ??
          "";

      setState(() {
        userStandard = standard;
        isLoadingUser = false;
      });
    } catch (e) {
      setState(() {
        error = "Unable to load student information.";
        isLoadingUser = false;
      });
    }
  }

  // ============================================================
  // SUBJECTS
  // ============================================================

  List<Map<String, String>> getSubjects() {
    if (userStandard == "class10") {
      return [
        {
          "name": "Mathematics",
          "storage": "maths",
        },
        {
          "name": "Science",
          "storage": "science",
        },
        {
          "name": "English",
          "storage": "english",
        },
      ];
    }

    if (userStandard == "class12") {
      return [
        {
          "name": "Mathematics",
          "storage": "maths",
        },
        {
          "name": "Physics",
          "storage": "physics",
        },
        {
          "name": "Chemistry",
          "storage": "chemistry",
        },
        {
          "name": "English",
          "storage": "english",
        },
      ];
    }

    return [];
  }

  // ============================================================
  // LOAD CHAPTERS
  // ============================================================

  Future<void> loadChapters({
    required String subject,
    required String storageSubject,
  }) async {
    setState(() {
      selectedSubject = subject;
      selectedStorageSubject = storageSubject;
      selectedChapter = null;
      chapters = [];
      isLoadingChapters = true;
      error = "";
    });

    try {
      final ref = FirebaseStorage.instance.ref(
        "syllabus/$userStandard/$storageSubject/chapters",
      );

      final result = await ref.listAll();

      final loadedChapters = result.items
          .where(
            (item) => item.name.toLowerCase().endsWith(".json"),
      )
          .map(
            (item) => item.name,
      )
          .toList();

      loadedChapters.sort();

      if (!mounted) return;

      setState(() {
        chapters = loadedChapters;
        isLoadingChapters = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = "Unable to load chapters.";
        isLoadingChapters = false;
      });
    }
  }

  // ============================================================
  // FORMAT CHAPTER NAME
  // ============================================================

  String formatChapter(String file) {
    return file
        .replaceAll(".json", "")
        .replaceAll("_", " ")
        .split(" ")
        .map(
          (word) => word.isEmpty
          ? word
          : word[0].toUpperCase() + word.substring(1),
    )
        .join(" ");
  }

  // ============================================================
  // SUBJECT ICON
  // ============================================================

  IconData getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case "mathematics":
        return Icons.calculate;

      case "science":
        return Icons.science;

      case "physics":
        return Icons.bolt;

      case "chemistry":
        return Icons.science_outlined;

      case "english":
        return Icons.menu_book;

      default:
        return Icons.school;
    }
  }

  // ============================================================
  // SUBJECT COLOR
  // ============================================================

  Color getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case "mathematics":
        return Colors.lightBlueAccent;

      case "science":
        return Colors.greenAccent;

      case "physics":
        return Colors.cyanAccent;

      case "chemistry":
        return Colors.orangeAccent;

      case "english":
        return Colors.purpleAccent;

      default:
        return Colors.purpleAccent;
    }
  }

  // ============================================================
  // GENERATE TEST
  // ============================================================

  Future<void> generateTest() async {
    if (selectedSubject == null ||
        selectedChapter == null ||
        selectedSubject!.isEmpty ||
        selectedChapter!.isEmpty) {
      return;
    }

    setState(() {
      isGeneratingTest = true;
      error = "";
    });

    try {
      final result = await _testSeriesService.generateTest(
        standard: userStandard,
        subject: selectedSubject!,
        chapter: selectedChapter!,
      );

      if (!mounted) return;

      setState(() {
        isGeneratingTest = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TakeTestScreen(
            testData: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isGeneratingTest = false;
        error = e.toString().replaceFirst(
          "Exception: ",
          "",
        );
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final subjects = getSubjects();

    if (isLoadingUser) {
      return const Scaffold(
        backgroundColor: Color(0xff0B0E1B),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.purpleAccent,
          ),
        ),
      );
    }

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
          child: Column(
            children: [

              // ==================================================
              // HEADER
              // ==================================================

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),

                child: Row(
                  children: [

                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },

                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 8),

                    const Expanded(
                      child: Text(
                        "Test Series",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Icon(
                      Icons.quiz_outlined,
                      color: Colors.purpleAccent,
                      size: 28,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // CONTENT
              // ==================================================

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const SizedBox(height: 10),

                      // ==================================================
                      // STANDARD
                      // ==================================================

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),

                        decoration: BoxDecoration(
                          color: const Color(0xff1A173B)
                              .withOpacity(0.7),

                          borderRadius:
                          BorderRadius.circular(20),

                          border: Border.all(
                            color:
                            Colors.white.withOpacity(0.08),
                          ),
                        ),

                        child: Row(
                          children: [

                            Container(
                              width: 48,
                              height: 48,

                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.purpleAccent
                                    .withOpacity(0.15),
                              ),

                              child: const Icon(
                                Icons.school,
                                color: Colors.purpleAccent,
                              ),
                            ),

                            const SizedBox(width: 15),

                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,

                              children: [
                                const Text(
                                  "Your Class",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  userStandard.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "Select Subject",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==================================================
                      // SUBJECTS
                      // ==================================================

                      ...subjects.map(
                            (subjectData) {

                          final subject =
                          subjectData["name"]!;

                          final storageSubject =
                          subjectData["storage"]!;

                          final isSelected =
                              selectedSubject ==
                                  subject;

                          final color =
                          getSubjectColor(subject);

                          return Padding(
                            padding:
                            const EdgeInsets.only(
                              bottom: 12,
                            ),

                            child: InkWell(
                              borderRadius:
                              BorderRadius.circular(18),

                              onTap: () {
                                loadChapters(
                                  subject: subject,
                                  storageSubject:
                                  storageSubject,
                                );
                              },

                              child: Container(
                                padding:
                                const EdgeInsets.all(17),

                                decoration:
                                BoxDecoration(
                                  color: isSelected
                                      ? color.withOpacity(
                                    0.15,
                                  )
                                      : const Color(
                                    0xff1A173B,
                                  ).withOpacity(
                                    0.6,
                                  ),

                                  borderRadius:
                                  BorderRadius.circular(
                                    18,
                                  ),

                                  border: Border.all(
                                    color: isSelected
                                        ? color
                                        : Colors.white
                                        .withOpacity(
                                      0.08,
                                    ),
                                  ),
                                ),

                                child: Row(
                                  children: [

                                    Icon(
                                      getSubjectIcon(
                                        subject,
                                      ),
                                      color: color,
                                      size: 28,
                                    ),

                                    const SizedBox(
                                      width: 15,
                                    ),

                                    Expanded(
                                      child: Text(
                                        subject,
                                        style:
                                        const TextStyle(
                                          color:
                                          Colors.white,
                                          fontSize: 17,
                                          fontWeight:
                                          FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    Icon(
                                      isSelected
                                          ? Icons
                                          .check_circle
                                          : Icons
                                          .arrow_forward_ios,
                                      color: isSelected
                                          ? color
                                          : Colors
                                          .purpleAccent,
                                      size: 19,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // CHAPTERS
                      // ==================================================

                      if (selectedSubject != null) ...[
                        Text(
                          "Select Chapter",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 14),

                        if (isLoadingChapters)
                          const Center(
                            child: Padding(
                              padding:
                              EdgeInsets.all(30),
                              child:
                              CircularProgressIndicator(
                                color:
                                Colors.purpleAccent,
                              ),
                            ),
                          )

                        else if (chapters.isEmpty)
                          Container(
                            width: double.infinity,
                            padding:
                            const EdgeInsets.all(20),

                            decoration: BoxDecoration(
                              color: const Color(
                                0xff1A173B,
                              ).withOpacity(0.6),

                              borderRadius:
                              BorderRadius.circular(18),
                            ),

                            child: const Text(
                              "No chapters found.",
                              textAlign:
                              TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          )

                        else
                          ...chapters.map(
                                (chapter) {

                              final isSelected =
                                  selectedChapter ==
                                      chapter;

                              final color =
                              getSubjectColor(
                                selectedSubject!,
                              );

                              return Padding(
                                padding:
                                const EdgeInsets.only(
                                  bottom: 12,
                                ),

                                child: InkWell(
                                  borderRadius:
                                  BorderRadius.circular(
                                    18,
                                  ),

                                  onTap: () {
                                    setState(() {
                                      selectedChapter =
                                          chapter;
                                      error = "";
                                    });
                                  },

                                  child: Container(
                                    padding:
                                    const EdgeInsets.all(
                                      17,
                                    ),

                                    decoration:
                                    BoxDecoration(
                                      color: isSelected
                                          ? color
                                          .withOpacity(
                                        0.15,
                                      )
                                          : const Color(
                                        0xff1A173B,
                                      ).withOpacity(
                                        0.6,
                                      ),

                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        18,
                                      ),

                                      border: Border.all(
                                        color: isSelected
                                            ? color
                                            : Colors.white
                                            .withOpacity(
                                          0.08,
                                        ),
                                      ),
                                    ),

                                    child: Row(
                                      children: [

                                        Container(
                                          width: 44,
                                          height: 44,

                                          decoration:
                                          BoxDecoration(
                                            shape:
                                            BoxShape
                                                .circle,
                                            color: color
                                                .withOpacity(
                                              0.15,
                                            ),
                                          ),

                                          child: Icon(
                                            Icons.menu_book,
                                            color: color,
                                          ),
                                        ),

                                        const SizedBox(
                                          width: 14,
                                        ),

                                        Expanded(
                                          child: Text(
                                            formatChapter(
                                              chapter,
                                            ),

                                            style:
                                            const TextStyle(
                                              color:
                                              Colors.white,
                                              fontSize: 16,
                                              fontWeight:
                                              FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        Icon(
                                          isSelected
                                              ? Icons
                                              .check_circle
                                              : Icons.radio_button_unchecked,

                                          color: isSelected
                                              ? color
                                              : Colors
                                              .white38,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],

                      // ==================================================
                      // ERROR
                      // ==================================================

                      if (error.isNotEmpty)
                        Padding(
                          padding:
                          const EdgeInsets.only(
                            top: 10,
                            bottom: 10,
                          ),

                          child: Text(
                            error,
                            style: const TextStyle(
                              color: Colors.redAccent,
                            ),
                          ),
                        ),

                      // ==================================================
                      // GENERATE BUTTON
                      // ==================================================

                      if (selectedChapter != null)
                        SizedBox(
                          width: double.infinity,
                          height: 54,

                          child: ElevatedButton(
                            onPressed:
                            isGeneratingTest
                                ? null
                                : generateTest,

                            style:
                            ElevatedButton.styleFrom(
                              backgroundColor:
                              Colors.purpleAccent,

                              foregroundColor:
                              Colors.white,

                              disabledBackgroundColor:
                              Colors.purpleAccent
                                  .withOpacity(
                                0.4,
                              ),

                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                  16,
                                ),
                              ),
                            ),

                            child: isGeneratingTest
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                                : const Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                              children: [

                                Icon(
                                  Icons
                                      .play_arrow_rounded,
                                ),

                                SizedBox(width: 8),

                                Text(
                                  "Generate Test",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}