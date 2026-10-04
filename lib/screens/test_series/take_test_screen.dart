import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/test_series_service.dart';
import 'test_result_screen.dart';

class TakeTestScreen extends StatefulWidget {
  final Map<String, dynamic> testData;

  const TakeTestScreen({
    super.key,
    required this.testData,
  });

  @override
  State<TakeTestScreen> createState() => _TakeTestScreenState();
}

class _TakeTestScreenState extends State<TakeTestScreen> with WidgetsBindingObserver {
  final TestSeriesService _testSeriesService =
  TestSeriesService();

  late final List<dynamic> questions;
  Timer? _timer;
  int currentQuestionIndex = 0;
  int secondsLeft = 0;
  bool isSubmitting = false;
  final Map<String, String> answers = {};
  final Map<String, TextEditingController> writtenControllers =
  {};
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (!isSubmitting) {
        _submitTest();
      }
    }
  }
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    questions =
        widget.testData["questions"] as List<dynamic>? ?? [];

    _initializeWrittenControllers();
    _startTimer();
  }

  // WRITTEN ANSWER CONTROLLERS

  void _initializeWrittenControllers() {
    for (final question in questions) {
      final questionId =
      question["questionId"]?.toString();

      final type =
      question["type"]?.toString().toLowerCase();

      if (questionId != null && type == "written") {
        writtenControllers[questionId] =
            TextEditingController();
      }
    }
  }

  // TIMER

  void _startTimer() {
    final timeLimit =
    widget.testData["time_limit_minutes"];

    final minutes =
    timeLimit is int
        ? timeLimit
        : int.tryParse(
      timeLimit?.toString() ?? "",
    ) ??
        20;

    secondsLeft = minutes * 60;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (!mounted || isSubmitting) {
          timer.cancel();
          return;
        }

        if (secondsLeft <= 1) {
          timer.cancel();
          secondsLeft = 0;

          _autoSubmit();

          return;
        }

        setState(() {
          secondsLeft--;
        });
      },
    );
  }

  String get timerDisplay {
    final minutes = secondsLeft ~/ 60;
    final seconds = secondsLeft % 60;

    return "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}";
  }

  bool get timerWarning => secondsLeft <= 60;

  // ANSWER

  void _selectMcqAnswer(
      String questionId,
      String answer,
      ) {
    setState(() {
      answers[questionId] = answer;
    });
  }

  void _saveWrittenAnswer(
      String questionId,
      String answer,
      ) {
    answers[questionId] = answer;
  }

  // NAVIGATION

  void _nextQuestion() {
    if (currentQuestionIndex <
        questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  // TIMER EXPIRY

  Future<void> _autoSubmit() async {
    if (isSubmitting || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Time's up! Submitting your test...",
        ),
        backgroundColor: Colors.orange,
      ),
    );

    await _submitTest();
  }

  // BACK BUTTON

  Future<bool> _handleBack() async {
    if (isSubmitting) {
      return false;
    }

    final shouldSubmit =
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
          const Color(0xff1A173B),

          title: const Text(
            "Leave Test?",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          content: const Text(
            "If you leave now, your test will be submitted.",
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                "Stay",
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                Colors.purpleAccent,
              ),
              child: const Text(
                "Submit & Exit",
              ),
            ),
          ],
        );
      },
    );

    if (shouldSubmit == true) {
      await _submitTest();
    }

    return false;
  }

  // SUBMIT TEST

  Future<void> _submitTest() async {
    if (isSubmitting) {
      return;
    }

    _timer?.cancel();

    setState(() {
      isSubmitting = true;
    });

    try {
      // Save written answers before submission.
      for (final question in questions) {
        final questionId =
        question["questionId"]?.toString();

        final type =
        question["type"]?.toString().toLowerCase();

        if (questionId != null &&
            type == "written") {
          answers[questionId] =
              writtenControllers[questionId]
                  ?.text
                  .trim() ??
                  "";
        }
      }

      final submittedAnswers =
      questions.map((question) {
        final questionId =
            question["questionId"]?.toString() ?? "";

        return {
          "questionId": questionId,
          "answer": answers[questionId] ?? "",
        };
      }).toList();

      final result =
      await _testSeriesService.submitTest(
        testId:
        widget.testData["testId"].toString(),
        answers: submittedAnswers,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TestResultScreen(
            resultData: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              "Exception: ",
              "",
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // DISPOSE

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _timer?.cancel();

    for (final controller in writtenControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }


  // BUILD

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xff0B0E1B),
        body: Center(
          child: Text(
            "No questions available.",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    final question =
    questions[currentQuestionIndex];

    final questionId =
        question["questionId"]?.toString() ?? "";

    final questionType =
    question["type"]?.toString().toLowerCase();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },

      child: Scaffold(
        backgroundColor:
        const Color(0xff0B0E1B),

        body: SafeArea(
          child: Column(
            children: [

              // ==================================================
              // HEADER
              // ==================================================

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                decoration: BoxDecoration(
                  color:
                  const Color(0xff15132D),

                  border: Border(
                    bottom: BorderSide(
                      color:
                      Colors.white.withOpacity(
                        0.08,
                      ),
                    ),
                  ),
                ),

                child: Row(
                  children: [

                    IconButton(
                      onPressed: isSubmitting
                          ? null
                          : _handleBack,

                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          Text(
                            widget.testData[
                            "subject"]
                                ?.toString() ??
                                "Test",

                            style:
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            widget.testData[
                            "chapter"]
                                ?.toString() ??
                                "",

                            style:
                            const TextStyle(
                              color:
                              Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),

                      decoration: BoxDecoration(
                        color: timerWarning
                            ? Colors.redAccent
                            .withOpacity(0.15)
                            : Colors.purpleAccent
                            .withOpacity(0.15),

                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),

                      child: Row(
                        children: [

                          Icon(
                            Icons.timer_outlined,
                            size: 20,
                            color: timerWarning
                                ? Colors.redAccent
                                : Colors
                                .purpleAccent,
                          ),

                          const SizedBox(width: 6),

                          Text(
                            timerDisplay,
                            style: TextStyle(
                              color: timerWarning
                                  ? Colors.redAccent
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // PROGRESS
              // ==================================================

              Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  18,
                  15,
                  18,
                  5,
                ),

                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

                  children: [

                    Text(
                      "Question "
                          "${currentQuestionIndex + 1}"
                          " / ${questions.length}",

                      style:
                      const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    Text(
                      questionType == "written"
                          ? "Written"
                          : "MCQ",

                      style: TextStyle(
                        color: questionType ==
                            "written"
                            ? Colors.orangeAccent
                            : Colors
                            .lightBlueAccent,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                ),

                child: LinearProgressIndicator(
                  value:
                  (currentQuestionIndex + 1) /
                      questions.length,

                  minHeight: 5,

                  backgroundColor:
                  Colors.white10,

                  color:
                  Colors.purpleAccent,
                ),
              ),

              // ==================================================
              // QUESTION
              // ==================================================

              Expanded(
                child: SingleChildScrollView(
                  padding:
                  const EdgeInsets.all(18),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.all(20),

                        decoration:
                        BoxDecoration(
                          color:
                          const Color(0xff1A173B)
                              .withOpacity(
                            0.75,
                          ),

                          borderRadius:
                          BorderRadius.circular(
                            20,
                          ),

                          border: Border.all(
                            color: Colors.white
                                .withOpacity(
                              0.08,
                            ),
                          ),
                        ),

                        child: Text(
                          question["question"]
                              ?.toString() ??
                              "",

                          style:
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.5,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // MCQ
                      // ==================================================

                      if (questionType == "mcq")
                        _buildMcq(
                          questionId,
                          question,
                        ),

                      // ==================================================
                      // WRITTEN
                      // ==================================================

                      if (questionType == "written")
                        _buildWritten(
                          questionId,
                          question,
                        ),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // BOTTOM NAVIGATION
              // ==================================================

              Container(
                padding:
                const EdgeInsets.fromLTRB(
                  18,
                  10,
                  18,
                  14,
                ),

                decoration: BoxDecoration(
                  color:
                  const Color(0xff15132D),

                  border: Border(
                    top: BorderSide(
                      color: Colors.white
                          .withOpacity(
                        0.08,
                      ),
                    ),
                  ),
                ),

                child: Row(
                  children: [

                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                        currentQuestionIndex ==
                            0 ||
                            isSubmitting
                            ? null
                            : _previousQuestion,

                        style:
                        OutlinedButton.styleFrom(
                          foregroundColor:
                          Colors.white,

                          side: const BorderSide(
                            color:
                            Colors.white24,
                          ),

                          padding:
                          const EdgeInsets
                              .symmetric(
                            vertical: 14,
                          ),
                        ),

                        child: const Text(
                          "Previous",
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child:
                      currentQuestionIndex ==
                          questions.length -
                              1
                          ? ElevatedButton(
                        onPressed:
                        isSubmitting
                            ? null
                            : _submitTest,

                        style:
                        ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          Colors
                              .purpleAccent,

                          foregroundColor:
                          Colors.white,

                          padding:
                          const EdgeInsets
                              .symmetric(
                            vertical: 14,
                          ),
                        ),

                        child: isSubmitting
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth:
                            2,
                            color:
                            Colors.white,
                          ),
                        )
                            : const Text(
                          "Submit Test",
                        ),
                      )
                          : ElevatedButton(
                        onPressed:
                        isSubmitting
                            ? null
                            : _nextQuestion,

                        style:
                        ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          Colors
                              .purpleAccent,

                          foregroundColor:
                          Colors.white,

                          padding:
                          const EdgeInsets
                              .symmetric(
                            vertical: 14,
                          ),
                        ),

                        child: const Text(
                          "Next",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MCQ WIDGET
  // ============================================================

  Widget _buildMcq(
      String questionId,
      Map<String, dynamic> question,
      ) {
    final options =
        question["options"] as List<dynamic>? ??
            [];

    final selected =
    answers[questionId];

    return Column(
      children: List.generate(
        options.length,
            (index) {

          final option = options[index].toString();
          final optionKey = String.fromCharCode(65 + index);
          final optionIndex = index.toString();
          final isSelected = selected == optionKey;

          return Padding(
            padding:
            const EdgeInsets.only(
              bottom: 12,
            ),

            child: InkWell(
              borderRadius:
              BorderRadius.circular(16),

              onTap: () {
                _selectMcqAnswer(
                  questionId,
                  optionIndex,
                );
              },

              child: Container(
                width: double.infinity,
                padding:
                const EdgeInsets.all(16),

                decoration:
                BoxDecoration(
                  color: isSelected
                      ? Colors.purpleAccent
                      .withOpacity(
                    0.18,
                  )
                      : const Color(
                    0xff1A173B,
                  ).withOpacity(
                    0.6,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),

                  border: Border.all(
                    color: isSelected
                        ? Colors.purpleAccent
                        : Colors.white
                        .withOpacity(
                      0.08,
                    ),
                  ),
                ),

                child: Row(
                  children: [

                    Container(
                      width: 32,
                      height: 32,

                      alignment:
                      Alignment.center,

                      decoration:
                      BoxDecoration(
                        shape:
                        BoxShape.circle,

                        color: isSelected
                            ? Colors
                            .purpleAccent
                            : Colors.white10,
                      ),

                      child: Text(
                        String.fromCharCode(
                          65 + index,
                        ),

                        style:
                        const TextStyle(
                          color: Colors.white,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Text(
                        option,

                        style:
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // WRITTEN WIDGET
  // ============================================================

  Widget _buildWritten(
      String questionId,
      Map<String, dynamic> question,
      ) {
    final controller =
    writtenControllers[questionId]!;

    final wordLimit =
        question["wordLimit"] ?? 80;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        Text(
          "Write your answer",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: controller,

          maxLines: 8,

          onChanged: (value) {
            _saveWrittenAnswer(
              questionId,
              value,
            );
          },

          style: const TextStyle(
            color: Colors.white,
            height: 1.4,
          ),

          decoration:
          InputDecoration(
            hintText:
            "Type your answer here...",

            hintStyle:
            const TextStyle(
              color: Colors.white38,
            ),

            filled: true,

            fillColor:
            const Color(0xff1A173B)
                .withOpacity(
              0.7,
            ),

            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                16,
              ),

              borderSide:
              const BorderSide(
                color: Colors.white12,
              ),
            ),

            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                16,
              ),

              borderSide:
              const BorderSide(
                color: Colors.white12,
              ),
            ),

            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                16,
              ),

              borderSide:
              const BorderSide(
                color:
                Colors.purpleAccent,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Word limit: $wordLimit words",
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}