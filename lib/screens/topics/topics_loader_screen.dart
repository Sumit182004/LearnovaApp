import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:learnovaapp/screens/explanation/explanation_screen.dart';

class TopicsLoaderScreen extends StatefulWidget {
  final String className;
  final String subject;
  final String chapterFile;

  const TopicsLoaderScreen({
    super.key,
    required this.className,
    required this.subject,
    required this.chapterFile,
  });

  @override
  State<TopicsLoaderScreen> createState() =>
      _TopicsLoaderScreenState();
}

class _TopicsLoaderScreenState
    extends State<TopicsLoaderScreen> {

  bool isLoading = true;
  String error = "";
  List topics = [];

  @override
  void initState() {
    super.initState();
    loadTopics();
  }

  Future<void> loadTopics() async {
    try {
      final ref = FirebaseStorage.instance.ref(
        "syllabus/${widget.className}/${widget.subject}/${widget.chapterFile}",
      );

      final url = await ref.getDownloadURL();

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception("Unable to load JSON");
      }

      final data = jsonDecode(response.body);
      print(data);
      print(data.keys);
      topics = data["topics"] ?? [];

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

  String get chapterTitle {
    return widget.chapterFile
        .replaceAll(".json", "")
        .replaceAll("_", " ")
        .split(" ")
        .map(
          (e) => e.isEmpty
          ? e
          : e[0].toUpperCase() + e.substring(1),
    )
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

                    Icon(
                      getSubjectIcon(),
                      color: glow,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        chapterTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
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
                          ),
                        ),
                      );
                    }

                    if (topics.isEmpty) {
                      return const Center(
                        child: Text(
                          "No Topics Found",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                      ),
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final topic = topics[index];
                        final String title = topic["title"] ?? "Topic";
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 16,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),

                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ExplanationScreen(
                                    className: widget.className,
                                    subject: widget.subject,
                                    chapter: widget.chapterFile.replaceAll(".json", ""),
                                    topic: title,
                                    content: jsonEncode(topic),
                                  ),
                                ),
                              );
                            },

                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xff1A173B).withOpacity(.6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(.08),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: glow.withOpacity(.18),
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
                                      color: glow.withOpacity(.15),
                                    ),
                                    child: Icon(
                                      Icons.school,
                                      color: glow,
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.purpleAccent,
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