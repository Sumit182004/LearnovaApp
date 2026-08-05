import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExplanationScreen extends StatefulWidget {
  final String className;
  final String subject;
  final String chapter;
  final String topic;
  final String content;

  const ExplanationScreen({
    super.key,
    required this.className,
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.content,
  });

  @override
  State<ExplanationScreen> createState() =>
      _ExplanationScreenState();
}

class _ExplanationScreenState extends State<ExplanationScreen> {
  bool isLoading = true;
  bool hasError = false;

  String errorMessage = "";

  Map<String, dynamic>? explanation;

  static const String baseUrl =
      "https://learnovaapp-lfgn.onrender.com";

  @override
  void initState() {
    super.initState();
    loadExplanation();
  }

  Future<void> loadExplanation() async {
    try {
      final response = await http.post(
        Uri.parse(
          "$baseUrl/generate-explanation",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "className": widget.className,
          "subject": widget.subject,
          "chapter": widget.chapter,
          "topic": widget.topic,
          "content": widget.content,
        }),
      );
      print("STATUS CODE: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Unable to load explanation");
      }

      final responseData =
      jsonDecode(response.body);

      explanation =
      responseData["data"];
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xff0B0E1B),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.purpleAccent,
          ),
        ),
      );
    }

    if (hasError) {
      return Scaffold(
        backgroundColor: const Color(0xff0B0E1B),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
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
                    Expanded(
                      child: Text(
                        widget.topic,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                buildSection(
                  title: "📘 Explanation",
                  child: Text(
                    explanation?["explanation"] ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                buildKeyPoints(),
                const SizedBox(height: 20),
                buildSection(
                  title: "💡 Example",
                  child: Text(
                    explanation?["example"] ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                buildImage(),
                const SizedBox(height: 20),
                buildSection(
                  title: "📝 Summary",
                  child: Text(
                    explanation?["summary"] ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                buildPracticeQuestions(),
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.purpleAccent,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                            16),
                      ),
                    ),
                    onPressed: () {

                      /// Assessment

                    },
                    child: const Text(
                      "Take Assessment",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff1A173B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white24,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget buildKeyPoints() {
    final List<dynamic> points =
        explanation?["key_points"] ?? [];
    return buildSection(
      title: "⭐ Key Points",
      child: Column(
        children: List.generate(
          points.length,
              (index) {
            return Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      points[index].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  Widget buildImage() {
    final image =
        explanation?["image_url"] ?? "";
    if (image.toString().isEmpty) {
      return const SizedBox();
    }
    return buildSection(
      title: "🖼 Diagram",
      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(15),
        child: Image.network(
          image,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
  Widget buildPracticeQuestions() {
    final List<dynamic> questions =
        explanation?["practice_questions"] ?? [];
    return buildSection(
      title: "🎯 Practice Questions",
      child: Column(
        children: List.generate(
          questions.length,
              (index) {
            return Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    "${index + 1}. ",
                    style: const TextStyle(
                      color: Colors.purpleAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      questions[index].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}