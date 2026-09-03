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
  State<ExplanationScreen> createState() => _ExplanationScreenState();
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
        Uri.parse("$baseUrl/generate-explanation"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "standard": widget.className,
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

      final responseData = jsonDecode(response.body);

      explanation = responseData["data"];

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

  String get subject {
    final value = widget.subject.toLowerCase().trim();

    if (value == "math" ||
        value == "mathematics" ||
        value == "maths") {
      return "maths";
    }

    if (value == "phy" || value == "physics") {
      return "physics";
    }

    if (value == "chem" || value == "chemistry") {
      return "chemistry";
    }

    if (value == "bio" || value == "biology") {
      return "biology";
    }

    return value;
  }

  bool hasText(dynamic value) {
    return value != null &&
        value.toString().trim().isNotEmpty;
  }

  bool hasList(dynamic value) {
    return value is List && value.isNotEmpty;
  }

  bool isExercise() {
    final content = widget.content.toLowerCase();

    return content.contains('"type":"exercise"') ||
        content.contains('"type": "exercise"');
  }

  bool isIntroduction() {
    final content = widget.content.toLowerCase();

    return content.contains('"type":"introduction"') ||
        content.contains('"type": "introduction"');
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                if (isExercise())
                  buildExerciseContent()
                else if (isIntroduction())
                  buildIntroductionContent()
                else
                  buildNormalContent(),

                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      // Assessment
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

  Widget buildExerciseContent() {
    if (subject == "maths") {
      return buildIfHasText(
        "🧮 Solution",
        explanation?["worked_example"],
      );
    }

    if (subject == "physics") {
      return buildIfHasText(
        "⚡ Solution",
        explanation?["example_or_application"],
      );
    }

    if (subject == "chemistry") {
      return buildIfHasText(
        "🧪 Solution",
        explanation?["example"],
      );
    }

    if (subject == "biology") {
      return buildIfHasText(
        "🧬 Solution",
        explanation?["example"],
      );
    }

    return const SizedBox();
  }

  Widget buildIntroductionContent() {
    return buildIfHasText(
      "👋 Introduction",
      explanation?["introduction"],
    );
  }

  Widget buildNormalContent() {
    final List<Widget> sections = [];

    if (hasText(explanation?["introduction"])) {
      sections.add(
        buildSection(
          title: "👋 Introduction",
          child: buildText(explanation?["introduction"]),
        ),
      );
    }

    if (hasText(explanation?["concept_explanation"])) {
      sections.add(
        buildSection(
          title: "📘 Explanation",
          child: buildText(
            explanation?["concept_explanation"],
          ),
        ),
      );
    }

    if (subject == "physics") {
      if (hasText(explanation?["formula"])) {
        sections.add(
          buildSection(
            title: "📐 Formula",
            child: buildText(
              explanation?["formula"],
            ),
          ),
        );
      }

      if (hasText(explanation?["observation"])) {
        sections.add(
          buildSection(
            title: "🔎 Observation",
            child: buildText(
              explanation?["observation"],
            ),
          ),
        );
      }

      if (hasText(
        explanation?["example_or_application"],
      )) {
        sections.add(
          buildSection(
            title: "💡 Example / Application",
            child: buildText(
              explanation?["example_or_application"],
            ),
          ),
        );
      }
    }

    if (subject == "chemistry") {
      if (hasList(explanation?["reactions"])) {
        sections.add(
          buildListSection(
            title: "🧪 Reactions",
            items: explanation?["reactions"],
          ),
        );
      }

      if (hasList(explanation?["observations"])) {
        sections.add(
          buildListSection(
            title: "🔎 Observations",
            items: explanation?["observations"],
          ),
        );
      }

      if (hasText(explanation?["example"])) {
        sections.add(
          buildSection(
            title: "💡 Example",
            child: buildText(
              explanation?["example"],
            ),
          ),
        );
      }
    }

    if (subject == "biology") {
      if (hasText(
        explanation?["structure_or_process"],
      )) {
        sections.add(
          buildSection(
            title: "🧬 Structure / Process",
            child: buildText(
              explanation?["structure_or_process"],
            ),
          ),
        );
      }

      if (hasText(
        explanation?["functions_or_explanation"],
      )) {
        sections.add(
          buildSection(
            title: "⚙️ Functions / Explanation",
            child: buildText(
              explanation?["functions_or_explanation"],
            ),
          ),
        );
      }

      if (hasText(explanation?["example"])) {
        sections.add(
          buildSection(
            title: "💡 Example",
            child: buildText(
              explanation?["example"],
            ),
          ),
        );
      }
    }

    if (subject == "maths") {
      if (hasText(explanation?["worked_example"])) {
        sections.add(
          buildSection(
            title: "💡 Example",
            child: buildText(
              explanation?["worked_example"],
            ),
          ),
        );
      }
    }

    if (hasList(explanation?["key_points"])) {
      sections.add(
        buildKeyPoints(),
      );
    }

    if (hasText(explanation?["summary"])) {
      sections.add(
        buildSection(
          title: "📝 Summary",
          child: buildText(
            explanation?["summary"],
          ),
        ),
      );
    }

    if (hasList(
      explanation?["practice_questions"],
    )) {
      sections.add(
        buildPracticeQuestions(),
      );
    }

    if (hasText(explanation?["image_url"])) {
      sections.add(buildImage());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < sections.length; i++) ...[
          sections[i],
          if (i < sections.length - 1)
            const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget buildIfHasText(
      String title,
      dynamic value,
      ) {
    if (!hasText(value)) {
      return const SizedBox();
    }

    return buildSection(
      title: title,
      child: buildText(value),
    );
  }

  Widget buildText(dynamic value) {
    return Text(
      value.toString().replaceAll("**", ""),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        height: 1.7,
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

    if (points.isEmpty) {
      return const SizedBox();
    }

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
                      points[index]
                          .toString()
                          .replaceAll("**", ""),
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

  Widget buildListSection({
    required String title,
    required List<dynamic> items,
  }) {
    if (items.isEmpty) {
      return const SizedBox();
    }

    return buildSection(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          items.length,
              (index) {
            return Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: Text(
                "${index + 1}. ${items[index]}"
                    .toString()
                    .replaceAll("**", ""),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.6,
                ),
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
        borderRadius: BorderRadius.circular(15),
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

    if (questions.isEmpty) {
      return const SizedBox();
    }

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
                      questions[index]
                          .toString()
                          .replaceAll("**", ""),
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