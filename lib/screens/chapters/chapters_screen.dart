import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../topics/topics_loader_screen.dart';

class ChaptersScreen extends StatefulWidget {
  final String className;
  final String subject;

  const ChaptersScreen({
    super.key,
    required this.className,
    required this.subject,
  });

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  bool isLoading = true;
  String error = "";
  List<String> chapters = [];

  @override
  void initState() {
    super.initState();
    loadChapters();
  }

  Future<void> loadChapters() async {
    try {
      final ref = FirebaseStorage.instance.ref(
        "syllabus/${widget.className}/${widget.subject}",
      );

      final result = await ref.listAll();

      chapters = result.items
          .where((e) => e.name.endsWith(".json"))
          .map((e) => e.name)
          .toList();

      chapters.sort();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String formatChapter(String file) {
    return file
        .replaceAll(".json", "")
        .replaceAll("_", " ")
        .split(" ")
        .map((e) =>
    e.isEmpty ? e : e[0].toUpperCase() + e.substring(1))
        .join(" ");
  }

  IconData getSubjectIcon() {
    switch (widget.subject) {
      case "maths":
        return Icons.calculate;

      case "physics":
        return Icons.bolt;

      case "chemistry":
        return Icons.science;

      case "biology":
        return Icons.eco;

      default:
        return Icons.menu_book;
    }
  }

  Color getGlowColor() {
    switch (widget.subject) {
      case "maths":
        return Colors.lightBlueAccent;

      case "physics":
        return Colors.cyanAccent;

      case "chemistry":
        return Colors.orangeAccent;

      case "biology":
        return Colors.greenAccent;

      default:
        return Colors.purpleAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final glow = getGlowColor();

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

              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 15),

                child: Row(
                  children: [

                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Icon(
                      getSubjectIcon(),
                      color: glow,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        widget.subject.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Builder(
                  builder: (_) {
                    if (isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.purpleAccent,
                        ),
                      );
                    }

                    if (error.isNotEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            error,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (chapters.isEmpty) {
                      return const Center(
                        child: Text(
                          "No Chapters Found",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 18),

                      itemCount: chapters.length,

                      itemBuilder: (_, index) {
                        final chapter = chapters[index];

                        return Padding(
                          padding:
                          const EdgeInsets.only(bottom: 16),

                          child: InkWell(
                            borderRadius:
                            BorderRadius.circular(20),

                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TopicsLoaderScreen(
                                        className: widget.className,
                                        subject: widget.subject,
                                        chapterFile: chapter,
                                      ),
                                ),
                              );
                            },

                            child: Container(
                              padding:
                              const EdgeInsets.all(18),

                              decoration: BoxDecoration(
                                color: const Color(0xff1A173B)
                                    .withOpacity(0.6),

                                borderRadius:
                                BorderRadius.circular(20),

                                border: Border.all(
                                  color: Colors.white
                                      .withOpacity(0.08),
                                ),

                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    glow.withOpacity(0.18),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),

                              child: Row(
                                children: [

                                  Container(
                                    width: 48,
                                    height: 48,

                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                      glow.withOpacity(.15),
                                    ),

                                    child: Icon(
                                      getSubjectIcon(),
                                      color: glow,
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  Expanded(
                                    child: Text(
                                      formatChapter(chapter),

                                      style:
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color:
                                    Colors.purpleAccent,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}