import 'package:flutter/material.dart';

class TestResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const TestResultScreen({
    super.key,
    required this.resultData,
  });

  @override
  Widget build(BuildContext context) {
    final score = resultData["score"] ?? 0;
    final correct = resultData["correctCount"] ?? 0;
    final wrong = resultData["wrongCount"] ?? 0;
    final unanswered = resultData["unansweredCount"] ?? 0;
    final totalQuestions =
        resultData["totalQuestions"] ?? 10;

    final subject =
        resultData["subject"]?.toString() ?? "Test";

    final chapter =
        resultData["chapter"]?.toString() ?? "";

    final topicPerformance =
        resultData["topicPerformance"]
        as Map<String, dynamic>? ??
            {};

    final questions =
        resultData["questions"] as List<dynamic>? ??
            [];

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
                        "Test Result",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const Icon(
                      Icons.emoji_events_outlined,
                      color: Colors.amberAccent,
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
                    children: [

                      // ==================================================
                      // TEST INFORMATION
                      // ==================================================

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),

                        decoration: BoxDecoration(
                          color: const Color(0xff1A173B)
                              .withOpacity(0.75),

                          borderRadius:
                          BorderRadius.circular(20),

                          border: Border.all(
                            color:
                            Colors.white.withOpacity(
                              0.08,
                            ),
                          ),
                        ),

                        child: Column(
                          children: [

                            Text(
                              subject,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              chapter,
                              textAlign:
                              TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 20),

                            Text(
                              "$score%",
                              style: const TextStyle(
                                color:
                                Colors.purpleAccent,
                                fontSize: 48,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              "Score",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // SUMMARY
                      // ==================================================

                      Row(
                        children: [

                          Expanded(
                            child: _summaryCard(
                              "Correct",
                              correct.toString(),
                              Colors.greenAccent,
                              Icons.check_circle,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: _summaryCard(
                              "Wrong",
                              wrong.toString(),
                              Colors.redAccent,
                              Icons.cancel,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: _summaryCard(
                              "Skipped",
                              unanswered.toString(),
                              Colors.orangeAccent,
                              Icons.remove_circle,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // QUESTION COUNT
                      // ==================================================

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(17),

                        decoration: BoxDecoration(
                          color: const Color(0xff1A173B)
                              .withOpacity(0.65),

                          borderRadius:
                          BorderRadius.circular(18),

                          border: Border.all(
                            color:
                            Colors.white.withOpacity(
                              0.08,
                            ),
                          ),
                        ),

                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,

                          children: [

                            const Text(
                              "Total Questions",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),

                            Text(
                              totalQuestions.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ==================================================
                      // TOPIC PERFORMANCE
                      // ==================================================

                      if (topicPerformance.isNotEmpty) ...[
                        const Align(
                          alignment:
                          Alignment.centerLeft,

                          child: Text(
                            "Topic Performance",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        ...topicPerformance.entries.map(
                              (entry) {
                            final topic =
                                entry.key;

                            final data =
                                entry.value
                                as Map<String,
                                    dynamic>? ??
                                    {};

                            final accuracy =
                                data["accuracy"] ?? 0;

                            final attempted =
                                data["attempted"] ??
                                    0;

                            final correctTopic =
                                data["correct"] ??
                                    0;

                            return Container(
                              width: double.infinity,
                              margin:
                              const EdgeInsets.only(
                                bottom: 10,
                              ),

                              padding:
                              const EdgeInsets.all(
                                16,
                              ),

                              decoration:
                              BoxDecoration(
                                color:
                                const Color(
                                  0xff1A173B,
                                ).withOpacity(0.65),

                                borderRadius:
                                BorderRadius.circular(
                                  16,
                                ),
                              ),

                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                                children: [

                                  Row(
                                    children: [

                                      Expanded(
                                        child: Text(
                                          _formatTopic(
                                            topic,
                                          ),

                                          style:
                                          const TextStyle(
                                            color:
                                            Colors.white,
                                            fontWeight:
                                            FontWeight
                                                .bold,
                                          ),
                                        ),
                                      ),

                                      Text(
                                        "$accuracy%",
                                        style:
                                        const TextStyle(
                                          color:
                                          Colors.purpleAccent,
                                          fontWeight:
                                          FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  Text(
                                    "$correctTopic / $attempted correct",

                                    style:
                                    const TextStyle(
                                      color:
                                      Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],

                      // ==================================================
                      // QUESTION-WISE RESULTS
                      // ==================================================

                      if (questions.isNotEmpty) ...[
                        const SizedBox(height: 15),

                        const Align(
                          alignment:
                          Alignment.centerLeft,

                          child: Text(
                            "Question-wise Result",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        ...List.generate(
                          questions.length,
                              (index) {
                            final question =
                            questions[index]
                            as Map<String,
                                dynamic>;

                            return _questionResultCard(
                              index + 1,
                              question,
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 25),

                      // ==================================================
                      // DONE
                      // ==================================================

                      SizedBox(
                        width: double.infinity,
                        height: 52,

                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.popUntil(
                              context,
                                  (route) =>
                              route.isFirst,
                            );
                          },

                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            Colors.purpleAccent,

                            foregroundColor:
                            Colors.white,

                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                16,
                              ),
                            ),
                          ),

                          child: const Text(
                            "Back to Home",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.bold,
                            ),
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

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard(
      String title,
      String value,
      Color color,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 8,
      ),

      decoration: BoxDecoration(
        color: const Color(0xff1A173B)
            .withOpacity(0.7),

        borderRadius:
        BorderRadius.circular(16),

        border: Border.all(
          color:
          Colors.white.withOpacity(0.06),
        ),
      ),

      child: Column(
        children: [

          Icon(
            icon,
            color: color,
            size: 23,
          ),

          const SizedBox(height: 7),

          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUESTION RESULT
  // ============================================================

  Widget _questionResultCard(
      int number,
      Map<String, dynamic> question,
      ) {
    final isCorrect =
        question["isCorrect"] == true;

    final isUnanswered =
        question["isUnanswered"] == true ||
            question["userAnswer"] == null ||
            question["userAnswer"]
                .toString()
                .trim()
                .isEmpty;

    final color = isUnanswered
        ? Colors.orangeAccent
        : isCorrect
        ? Colors.greenAccent
        : Colors.redAccent;

    final status = isUnanswered
        ? "Not Answered"
        : isCorrect
        ? "Correct"
        : "Wrong";

    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xff1A173B)
            .withOpacity(0.65),

        borderRadius:
        BorderRadius.circular(17),

        border: Border.all(
          color:
          color.withOpacity(0.25),
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              Container(
                width: 34,
                height: 34,

                alignment:
                Alignment.center,

                decoration:
                BoxDecoration(
                  shape:
                  BoxShape.circle,

                  color:
                  color.withOpacity(
                    0.15,
                  ),
                ),

                child: Text(
                  number.toString(),
                  style: TextStyle(
                    color: color,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            question["question"]
                ?.toString() ??
                "",

            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          _resultRow(
            "Your Answer",
            question["userAnswer"]
                ?.toString() ??
                "Not answered",
          ),

          if (question["correctAnswer"] != null)
            _resultRow(
              "Correct Answer",
              question["correctAnswer"]
                  .toString(),
            ),

          if (question["obtainedMarks"] != null)
            _resultRow(
              "Marks",
              "${question["obtainedMarks"]}"
                  " / "
                  "${question["marks"] ?? ""}",
            ),

          if (question["feedback"] != null &&
              question["feedback"]
                  .toString()
                  .isNotEmpty)
            _resultRow(
              "Feedback",
              question["feedback"]
                  .toString(),
            ),
        ],
      ),
    );
  }

  Widget _resultRow(
      String title,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(top: 7),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTopic(String topic) {
    return topic
        .replaceAll("_", " ")
        .split(" ")
        .map(
          (word) => word.isEmpty
          ? word
          : word[0].toUpperCase() +
          word.substring(1),
    )
        .join(" ");
  }
}