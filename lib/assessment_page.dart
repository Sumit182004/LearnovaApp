import 'package:flutter/material.dart';

import 'services/assessment_service.dart';

class AssessmentPage extends StatefulWidget {
  final String standard;

  const AssessmentPage({
    super.key,
    required this.standard,
  });

  @override
  State<AssessmentPage> createState() =>
      _AssessmentPageState();
}

class _AssessmentPageState
    extends State<AssessmentPage> {
  bool isLoading = true;
  bool isSubmitting = false;

  String? errorMessage;
  String? assessmentId;

  List<dynamic> questions = [];

  int currentQuestionIndex = 0;

  // questionId -> selected option index
  final Map<int, int> selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    loadAssessment();
  }

  // LOAD ASSESSMENT

  Future<void> loadAssessment() async {
    try {
      final result =
      await AssessmentService.generateAssessment(
        standard: widget.standard,
      );

      if (!mounted) return;

      setState(() {
        assessmentId = result['assessmentId'];

        questions = result['questions'] ?? [];

        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }

  // SELECT ANSWER

  void selectAnswer(
      int questionId,
      int optionIndex,
      ) {
    setState(() {
      selectedAnswers[questionId] =
          optionIndex;
    });
  }

  // NEXT QUESTION

  void nextQuestion() {
    final question =
    questions[currentQuestionIndex];

    final int questionId =
    question['id'];

    if (!selectedAnswers.containsKey(
      questionId,
    )) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select an answer first.',
          ),
        ),
      );

      return;
    }

    if (
    currentQuestionIndex <
        questions.length - 1
    ) {
      setState(() {
        currentQuestionIndex++;
      });
    }
  }

  // PREVIOUS QUESTION

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  // SUBMIT ASSESSMENT

  Future<void> submitAssessment() async {
    final question =
    questions[currentQuestionIndex];

    final int questionId =
    question['id'];

    // Ensure last question is answered.
    if (!selectedAnswers.containsKey(
      questionId,
    )) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select an answer first.',
          ),
        ),
      );

      return;
    }

    if (
    selectedAnswers.length !=
        questions.length
    ) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please answer all questions.',
          ),
        ),
      );

      return;
    }

    if (assessmentId == null) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final result =
      await AssessmentService
          .submitAssessment(
        assessmentId: assessmentId!,
        selectedAnswers: selectedAnswers,
      );

      if (!mounted) return;

      // For now we show a success message.
      // Later we can create a separate result page.

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ??
                'Assessment completed successfully.',
          ),
        ),
      );

      // Assessment is completed.
      // Go to home page.

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e
                .toString()
                .replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xff081062),
      body: SafeArea(
        child: buildBody(),
      ),
    );
  }

  Widget buildBody() {
    // Loading Gemini assessment
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'Preparing your assessment...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
              ),
            ),
          ],
        ),
      );
    }

    // Error
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 70,
              ),
              const SizedBox(height: 20),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });

                  loadAssessment();
                },
                child: const Text(
                  'Try Again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return const Center(
        child: Text(
          'No assessment questions found.',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      );
    }

    return buildQuestionPage();
  }

  // QUESTION UI

  Widget buildQuestionPage() {
    final question =
    questions[currentQuestionIndex];

    final int questionId =
    question['id'];

    final List<dynamic> options =
    question['options'];

    final int? selectedOption =
    selectedAnswers[questionId];

    final bool isLastQuestion =
        currentQuestionIndex ==
            questions.length - 1;

    final double progress =
        (currentQuestionIndex + 1) /
            questions.length;

    return Column(
      children: [
        // Progress section
        Padding(
          padding:
          const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
                children: [
                  const Text(
                    'Initial Assessment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${currentQuestionIndex + 1}'
                        ' / '
                        '${questions.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                borderRadius:
                BorderRadius.circular(10,
                ),
              ),
            ],
          ),
        ),

        // Question card
        Expanded(
          child: Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(25),
            decoration:
            const BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.only(
                topLeft:
                Radius.circular(30),
                topRight:
                Radius.circular(30),
              ),
            ),
            child:
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    question['subject'] ??
                        '',
                    style:
                    const TextStyle(
                      color: Colors.blue,
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  Text(
                    question[
                    'question'] ??
                        '',
                    style:
                    const TextStyle(
                      fontSize: 21,
                      fontWeight:
                      FontWeight.w600,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  // Options
                  ...List.generate(
                    options.length,
                        (index) {
                      final bool
                      isSelected =
                          selectedOption ==
                              index;

                      return Padding(
                        padding:
                        const EdgeInsets
                            .only(
                          bottom: 15,
                        ),
                        child:
                        InkWell(
                          onTap: () {
                            selectAnswer(
                              questionId,
                              index,
                            );
                          },
                          borderRadius:
                          BorderRadius
                              .circular(15,
                          ),
                          child:
                          Container(
                            width: double
                                .infinity,
                            padding:
                            const EdgeInsets
                                .all(17,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              isSelected
                                  ? const Color(
                                0xffE8EAFF,
                              )
                                  : Colors
                                  .white,
                              border:
                              Border.all(
                                color:
                                isSelected
                                    ? const Color(
                                  0xff081062,
                                )
                                    : Colors
                                    .grey
                                    .shade300,
                                width:
                                isSelected
                                    ? 2
                                    : 1,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                15,
                              ),
                            ),
                            child: Row(
                              children: [
                                Radio<int>(
                                  value:
                                  index,
                                  groupValue:
                                  selectedOption,
                                  onChanged:
                                      (value) {
                                    if (value !=
                                        null) {
                                      selectAnswer(
                                        questionId,
                                        value,
                                      );
                                    }
                                  },
                                ),
                                Expanded(
                                  child:
                                  Text(
                                    options[
                                    index]
                                        .toString(),
                                    style:
                                    const TextStyle(
                                      fontSize: 16,
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

                  const SizedBox(
                    height: 20,
                  ),

                  // Navigation buttons
                  Row(
                    children: [
                      if (
                      currentQuestionIndex >
                          0)
                        Expanded(
                          child:
                          OutlinedButton(
                            onPressed:
                            isSubmitting
                                ? null
                                : previousQuestion,
                            style:
                            OutlinedButton
                                .styleFrom(
                              minimumSize:
                              const Size(0, 55,
                              ),
                            ),
                            child:
                            const Text(
                              'Previous',
                            ),
                          ),
                        ),

                      if (
                      currentQuestionIndex >
                          0)
                        const SizedBox(
                          width: 15,
                        ),

                      Expanded(
                        child:
                        ElevatedButton(
                          onPressed:
                          isSubmitting
                              ? null
                              : isLastQuestion
                              ? submitAssessment
                              : nextQuestion,
                          style:
                          ElevatedButton
                              .styleFrom(
                            backgroundColor:
                            const Color(
                              0xff081062,
                            ),
                            minimumSize:
                            const Size(0, 55,
                            ),
                          ),
                          child:
                          isSubmitting
                              ? const SizedBox(
                            width: 23,
                            height: 23,
                            child:
                            CircularProgressIndicator(
                              color:
                              Colors.white,
                              strokeWidth:
                              2,
                            ),
                          )
                              : Text(
                            isLastQuestion
                                ? 'Submit Assessment'
                                : 'Next',
                            style:
                            const TextStyle(
                              color:
                              Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}