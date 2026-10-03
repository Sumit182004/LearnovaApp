import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

// YOUR EXISTING EXPLANATION SCREEN
import '../explanation/explanation_screen.dart';

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

class _TopicsLoaderScreenState extends State<TopicsLoaderScreen> {
  bool isLoading = true;
  String error = "";

  List<dynamic> topics = [];

  @override
  void initState() {
    super.initState();
    loadTopics();
  }


  Future<void> loadTopics() async {
    try {

      final ref = FirebaseStorage.instance.ref(
        "syllabus/"
            "${widget.className}/"
            "${widget.subject.toLowerCase()}/"
            "chapters/"
            "${widget.chapterFile}",
      );

      final url = await ref.getDownloadURL();

      final response = await http.get(
        Uri.parse(url),
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to load chapter. Status: ${response.statusCode}",
        );
      }

      final Map<String, dynamic> data =
      jsonDecode(response.body) as Map<String, dynamic>;

      debugPrint("========== CHAPTER JSON ==========");
      debugPrint(data.toString());
      debugPrint("==================================");

      dynamic loadedTopics;

      if (data["topics"] != null) {
        loadedTopics = data["topics"];

        debugPrint(
          "Using JSON key: topics",
        );
      } else if (data["sections"] != null) {
        loadedTopics = data["sections"];

        debugPrint(
          "Using JSON key: sections",
        );
      } else {
        loadedTopics = [];

        debugPrint(
          "No topics or sections found in JSON",
        );
      }

      if (loadedTopics is! List) {
        throw Exception(
          "Invalid JSON format: topics/sections must be a list.",
        );
      }

      if (!mounted) return;

      setState(() {
        topics = loadedTopics;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        "ERROR LOADING TOPICS: $e",
      );

      if (!mounted) return;

      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // GET TOPIC TITLE

  String getTopicTitle(dynamic topic) {
    if (topic is! Map) {
      return topic.toString();
    }

    // Maths style
    if (topic["title"] != null) {
      return topic["title"].toString();
    }

    // Other possible naming
    if (topic["name"] != null) {
      return topic["name"].toString();
    }

    if (topic["topic"] != null) {
      return topic["topic"].toString();
    }

    return "Topic";
  }

  // GET TOPIC ID

  String getTopicId(
      dynamic topic,
      int index,
      ) {
    if (topic is Map) {
      if (topic["id"] != null) {
        return topic["id"].toString();
      }
    }

    return "${index + 1}";
  }

  String getTopicContent(dynamic topic) {
    if (topic is! Map) {
      return jsonEncode({
        "blocks": [
          {
            "type": "theory",
            "text": topic.toString(),
          }
        ]
      });
    }

    // KEEP THE ORIGINAL BLOCK STRUCTURE

    final rawBlocks = topic["blocks"];

    if (rawBlocks is List) {
      return jsonEncode({
        "blocks": rawBlocks,
      });
    }

    if (topic["content"] != null) {
      final content = topic["content"];

      // If content is already a JSON string, keep it.
      if (content is String) {
        try {
          jsonDecode(content);
          return content;
        } catch (_) {
          // Plain text content
          return jsonEncode({
            "blocks": [
              {
                "type": "theory",
                "text": content,
              }
            ]
          });
        }
      }

      // If content is already a Map/List
      return jsonEncode({
        "blocks": [
          {
            "type": "theory",
            "text": content.toString(),
          }
        ]
      });
    }

    return jsonEncode({
      "blocks": [
        {
          "type": "theory",
          "text": topic.toString(),
        }
      ]
    });
  }

  // OPEN EXISTING EXPLANATION SCREEN


  void openExplanation(
      dynamic topic,
      int index,
      ) {
    if (topic is! Map) return;

    final String topicTitle = getTopicTitle(
      topic,
    );

    final String topicId = getTopicId(
      topic,
      index,
    );
    final String content = getTopicContent(
      topic,
    );
    debugPrint(
      "======================================",
    );
    debugPrint(
      "OPENING EXPLANATION",
    );
    debugPrint(
      "Topic ID: $topicId",
    );
    debugPrint(
      "Topic: $topicTitle",
    );
    debugPrint(
      "Content length: ${content.length}",
    );
    debugPrint(
      "======================================",
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExplanationScreen(
          className: widget.className,
          subject: widget.subject,
          chapter: widget.chapterFile,
          topic: topicTitle,
          content: content,
        ),
      ),
    );
  }

  // SUBJECT ICON

  IconData getSubjectIcon() {
    switch (widget.subject.toLowerCase()) {
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

  // GLOW COLOR
  Color getGlowColor() {
    switch (widget.subject.toLowerCase()) {
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

  // BUILD

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

              // HEADER

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

                    const SizedBox(width: 10),

                    Icon(
                      getSubjectIcon(),
                      color: glow,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        widget.chapterFile
                            .replaceAll(".json", "")
                            .replaceAll("_", " ")
                            .toUpperCase(),

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // CONTENT

              Expanded(
                child: Builder(
                  builder: (_) {

                    // LOADING

                    if (isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.purpleAccent,
                        ),
                      );
                    }

                    // ERROR

                    if (error.isNotEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),

                          child: Text(
                            error,

                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),

                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    // NO TOPICS

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

                    // TOPICS

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),

                      itemCount: topics.length,

                      itemBuilder: (_, index) {
                        final topic = topics[index];

                        final title = getTopicTitle(
                          topic,
                        );

                        final id = getTopicId(
                          topic,
                          index,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: 16,
                          ),

                          child: InkWell(
                            borderRadius:
                            BorderRadius.circular(20),

                            // TOPIC CLICK
                            onTap: () {
                              openExplanation(
                                topic,
                                index,
                              );
                            },

                            child: Container(
                              padding:
                              const EdgeInsets.all(18),

                              decoration: BoxDecoration(
                                color: const Color(
                                  0xff1A173B,
                                ).withOpacity(0.6),

                                borderRadius:
                                BorderRadius.circular(20),

                                border: Border.all(
                                  color: Colors.white
                                      .withOpacity(0.08),
                                ),

                                boxShadow: [
                                  BoxShadow(
                                    color: glow
                                        .withOpacity(0.18),

                                    blurRadius: 15,

                                    spreadRadius: 1,
                                  ),
                                ],
                              ),

                              child: Row(
                                children: [

                                  // ICON

                                  Container(
                                    width: 48,
                                    height: 48,

                                    decoration:
                                    BoxDecoration(
                                      shape:
                                      BoxShape.circle,

                                      color: glow
                                          .withOpacity(.15),
                                    ),

                                    child: Icon(
                                      getSubjectIcon(),
                                      color: glow,
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 16,
                                  ),

                                  // TOPIC NAME

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,

                                      children: [

                                        Text(
                                          "Topic $id",

                                          style: TextStyle(
                                            color: glow,
                                            fontSize: 12,
                                            fontWeight:
                                            FontWeight.w600,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 4,
                                        ),

                                        Text(
                                          title,

                                          style:
                                          const TextStyle(
                                            color:
                                            Colors.white,
                                            fontSize: 17,
                                            fontWeight:
                                            FontWeight.bold,
                                          ),
                                        ),
                                      ],
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