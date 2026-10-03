import json
import uuid

from fastapi import HTTPException, Header
from pydantic import BaseModel
from firebase_admin import firestore

from rag.retriever import retrieve_chunks
from rag.context_builder import build_rag_context


db = None
client = None
verify_token = None

# REQUEST MODEL

class TestGenerationRequest(BaseModel):
    standard: str
    subject: str
    chapter: str

class TestAnswer(BaseModel):
    questionId: str
    answer: str | None = None


class TestSubmissionRequest(BaseModel):
    testId: str
    answers: list[TestAnswer]
# TEST CONFIGURATION

SUPPORTED_SUBJECTS = {
    "Mathematics",
    "Science",
    "English",
    "Physics",
    "Chemistry",
}

# LEVEL ORDER

LEVEL_ORDER = {
    "beginner": 0,
    "intermediate": 1,
    "advanced": 2,
}

# NORMALIZE LEVEL


def normalize_level(level: str) -> str:

    if not level:
        return "beginner"

    level = level.lower().strip()

    if level not in LEVEL_ORDER:
        return "beginner"

    return level

# GET STUDENT LEVEL

def get_student_level(uid: str, subject: str) -> str:

    user_ref = (
        db.collection("users")
        .document(uid)
    )

    user_doc = user_ref.get()

    if not user_doc.exists:
        raise HTTPException(
            status_code=404,
            detail="Student profile not found."
        )

    user_data = user_doc.to_dict() or {}

    subject_levels = user_data.get(
        "subjectLevels",
        {}
    )

    level = subject_levels.get(
        subject,
        "beginner"
    )

    return normalize_level(level)

# GET PREVIOUS ATTEMPTS

def get_previous_attempts(
    uid: str,
    subject: str,
    chapter: str,
):

    attempts_ref = (
        db.collection("users")
        .document(uid)
        .collection("testAttempts")
    )

    query = (
        attempts_ref
        .where(
            "subject",
            "==",
            subject
        )
        .where(
            "chapter",
            "==",
            chapter
        )
        .order_by(
            "completedAt",
            direction=firestore.Query.DESCENDING
        )
        .limit(5)
    )

    docs = query.stream()

    attempts = []

    for doc in docs:

        data = doc.to_dict()

        attempts.append(data)

    return attempts

# BUILD PREVIOUS PERFORMANCE

def build_performance_context(attempts):

    if not attempts:

        return {
            "hasPreviousTests": False,
            "summary": "No previous test has been attempted."
        }

    performance = []

    for attempt in attempts:

        questions = attempt.get(
            "questions",
            []
        )

        wrong_questions = []
        weak_topics = {}

        for question in questions:

            is_correct = question.get(
                "isCorrect"
            )

            topic = question.get(
                "topic",
                "general"
            )

            if is_correct is False:

                wrong_questions.append(
                    question.get(
                        "question",
                        ""
                    )
                )

                weak_topics[topic] = (
                    weak_topics.get(topic, 0) + 1
                )

        performance.append({
            "testNumber": attempt.get(
                "testNumber"
            ),
            "level": attempt.get(
                "level"
            ),
            "score": attempt.get(
                "score"
            ),
            "correctCount": attempt.get(
                "correctCount"
            ),
            "wrongCount": attempt.get(
                "wrongCount"
            ),
            "unansweredCount": attempt.get(
                "unansweredCount"
            ),
            "weakTopics": weak_topics,
            "wrongQuestions": wrong_questions[:10],
        })

    return {
        "hasPreviousTests": True,
        "previousAttempts": performance,
    }

# BUILD TEST PROMPT

def build_test_prompt(
    standard: str,
    subject: str,
    chapter: str,
    level: str,
    performance_context: dict,
    rag_context: str,
):

    if subject.lower() == "mathematics":

        question_rules = """
Generate exactly 10 MCQ questions.

Every question MUST:
- be an MCQ
- have exactly 4 options
- have exactly one correct answer
- contain a topic
- contain a short explanation
"""

    elif subject.lower() == "science":

        question_rules = """
Generate exactly 10 questions.

The test must contain:
- 7 MCQ questions
- 3 written/descriptive questions

MCQ questions:
- exactly 4 options
- exactly one correct answer

Written questions:
- include modelAnswer
- include marks
- include wordLimit
- include topic
- include explanation
"""

    else:

        question_rules = """
Generate exactly 10 MCQ questions.

Every question MUST:
- be an MCQ
- have exactly 4 options
- have exactly one correct answer
- contain a topic
- contain a short explanation
"""

    previous_instruction = json.dumps(
        performance_context,
        indent=2
    )

    return f"""
You are an expert educational test designer
for Learnova.

Create a personalized test for:

Standard: Class {standard}
Subject: {subject}
Chapter: {chapter}
Current Student Level: {level}

IMPORTANT:

The test must be based primarily on the
provided Learnova chapter knowledge.

Do not create questions from unrelated
outside content.

The student has the following previous
performance:

{previous_instruction}

Use this performance to personalize the
new test.

If previous attempts exist:

1. Avoid repeating previous questions.
2. Focus more on weak topics.
3. Include concepts the student previously
   answered incorrectly.
4. Maintain the student's current level
   unless the performance clearly supports
   progression.
5. Do not simply copy previous questions.

If there are no previous attempts:

Create a balanced test suitable for the
student's current level.

DIFFICULTY:

Beginner:
- basic concepts
- direct understanding
- simple applications

Intermediate:
- conceptual understanding
- moderate application
- some reasoning

Advanced:
- deeper reasoning
- application
- slightly challenging questions

Do not create Olympiad/JEE/NEET-level
questions unless specifically supported
by the chapter content.

QUESTION RULES:

{question_rules}

RAG CHAPTER KNOWLEDGE:

{rag_context}

OUTPUT RULES:

1. Generate EXACTLY 10 questions.
2. Return ONLY valid JSON.
3. Do not use Markdown.
4. Do not add comments.
5. Do not add text before or after JSON.
6. Do not repeat previous questions.

Return exactly this structure:

{{
    "questions": [
        {{
            "type": "mcq",
            "question": "Question text",
            "options": [
                "Option A",
                "Option B",
                "Option C",
                "Option D"
            ],
            "correctAnswer": 0,
            "topic": "topic_name",
            "explanation": "Short explanation"
        }}
    ]
}}

For written questions use:

{{
    "type": "written",
    "question": "Question text",
    "modelAnswer": "Expected answer",
    "marks": 3,
    "wordLimit": 80,
    "topic": "topic_name",
    "explanation": "Short explanation"
}}

For MCQs:

correctAnswer must be:

0 = first option
1 = second option
2 = third option
3 = fourth option
"""
# VALIDATE GENERATED TEST

def validate_test(
    questions,
    subject
):

    # Must contain exactly 10
    if not isinstance(
        questions,
        list
    ):
        return False

    if len(questions) != 10:
        return False

    if subject.lower() == "science":

        mcq_count = 0
        written_count = 0

        for question in questions:

            question_type = question.get(
                "type"
            )

            if question_type == "mcq":
                mcq_count += 1

            elif question_type == "written":
                written_count += 1

            else:
                return False

        if mcq_count != 7:
            return False

        if written_count != 3:
            return False

    else:

        for question in questions:

            if question.get("type") != "mcq":
                return False

    # Validate individual questions

    for question in questions:

        if not question.get(
            "question"
        ):
            return False

        if not question.get(
            "topic"
        ):
            return False

        question_type = question.get(
            "type"
        )

        # MCQ

        if question_type == "mcq":

            options = question.get(
                "options"
            )

            if (
                not isinstance(options, list)
                or len(options) != 4
            ):
                return False

            correct_answer = question.get(
                "correctAnswer"
            )

            if (
                not isinstance(
                    correct_answer,
                    int
                )
                or correct_answer < 0
                or correct_answer > 3
            ):
                return False
        # Written

        elif question_type == "written":

            if not question.get(
                "modelAnswer"
            ):
                return False

            if not isinstance(
                question.get("marks"),
                int
            ):
                return False

            if not isinstance(
                question.get("wordLimit"),
                int
            ):
                return False

        else:

            return False

    return True


def evaluate_mcq(question, user_answer):
    """
    Evaluate one MCQ question.
    """

    correct_answer = question.get("correctAnswer")

    if user_answer is None or user_answer == "":
        return {
            "isCorrect": False,
            "isUnanswered": True,
            "obtainedMarks": 0,
        }

    try:
        user_answer_index = int(user_answer)
    except (ValueError, TypeError):
        return {
            "isCorrect": False,
            "isUnanswered": False,
            "obtainedMarks": 0,
        }

    is_correct = (
        user_answer_index == correct_answer
    )

    return {
        "isCorrect": is_correct,
        "isUnanswered": False,
        "obtainedMarks": 1 if is_correct else 0,
    }
def evaluate_written_answer(
    question,
    student_answer,
):
    question_text = question.get("question", "")
    model_answer = question.get("modelAnswer", "")
    max_marks = int(question.get("marks", 1))
    word_limit = int(question.get("wordLimit", 80))

    prompt = f"""
You are evaluating a school-level Science answer.

Question:
{question_text}

Model Answer:
{model_answer}

Student Answer:
{student_answer}

Maximum Marks:
{max_marks}

Expected Word Limit:
{word_limit} words

Evaluate the student's answer based on:
1. Correctness
2. Important scientific concepts
3. Relevance to the question
4. Completeness

Do not give marks simply because the answer is long.

Give partial marks when the student has some
correct concepts but the answer is incomplete.

Return ONLY valid JSON:

{{
    "obtainedMarks": 0,
    "isCorrect": false,
    "feedback": "Short feedback for the student."
}}

Rules:
- obtainedMarks must be between 0 and {max_marks}.
- Use only integer or decimal marks appropriate for the
  maximum marks.
- Do not exceed {max_marks}.
- Keep feedback short and student-friendly.
"""

    try:
        response = client.models.generate_content(
            model="gemini-3.5-flash",
            contents=prompt,
        )

        if not response.text:
            raise ValueError(
                "Gemini returned an empty response."
            )

        raw_response = (
            response.text
            .replace("```json", "")
            .replace("```", "")
            .strip()
        )

        evaluation = json.loads(raw_response)

        obtained_marks = float(
            evaluation.get(
                "obtainedMarks",
                0
            )
        )

        # Safety validation
        obtained_marks = max(
            0,
            min(
                obtained_marks,
                max_marks
            )
        )

        return {
            "obtainedMarks": obtained_marks,
            "isCorrect": bool(
                evaluation.get(
                    "isCorrect",
                    False
                )
            ),
            "feedback": evaluation.get(
                "feedback",
                ""
            ),
        }

    except Exception as e:

        print(
            "Written Answer Evaluation Error:",
            str(e)
        )

        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to evaluate written answer."
            )
        )
# REGISTER ROUTES


def calculate_new_level(
    current_level: str,
    recent_scores: list[float],
) -> str:

    current_level = normalize_level(
        current_level
    )

    if not recent_scores:
        return current_level

    # Use the latest 3 tests
    scores = recent_scores[:3]

    average_score = (
        sum(scores) / len(scores)
    )

    # ------------------------------------------
    # Progression
    # ------------------------------------------

    if current_level == "beginner":

        if (
            len(scores) >= 2
            and average_score >= 75
        ):
            return "intermediate"

        return "beginner"

    if current_level == "intermediate":

        if (
            len(scores) >= 2
            and average_score >= 80
        ):
            return "advanced"

        if (
            len(scores) >= 3
            and average_score < 40
        ):
            return "beginner"

        return "intermediate"

    # ------------------------------------------
    # Advanced
    # ------------------------------------------

    if current_level == "advanced":

        if (
            len(scores) >= 3
            and average_score < 40
        ):
            return "intermediate"

        return "advanced"

    return current_level
def get_recent_scores(
    uid: str,
    subject: str,
    chapter: str,
):

    attempts_ref = (
        db.collection("users")
        .document(uid)
        .collection("testAttempts")
    )

    query = (
        attempts_ref
        .where(
            "subject",
            "==",
            subject
        )
        .where(
            "chapter",
            "==",
            chapter
        )
        .order_by(
            "completedAt",
            direction=firestore.Query.DESCENDING
        )
        .limit(3)
    )

    docs = query.stream()

    scores = []

    for doc in docs:

        data = doc.to_dict()

        score = data.get(
            "score"
        )

        if score is not None:
            scores.append(
                float(score)
            )

    return scores


def register_test_series_routes(
    app,
    firestore_db,
    gemini_client,
    verify_firebase_token,
):

    global db
    global client
    global verify_token

    db = firestore_db
    client = gemini_client
    verify_token = verify_firebase_token

    # GENERATE TEST

    @app.post("/generate-test")
    def generate_test(
        request: TestGenerationRequest,
        authorization: str = Header(None),
    ):

        # Verify Firebase user

        decoded_token = verify_token(
            authorization
        )

        uid = decoded_token["uid"]

        # Normalize standard

        standard = (
            request.standard
            .lower()
            .replace("class", "")
            .replace("standard", "")
            .replace("th", "")
            .strip()
        )

        subject = request.subject.strip()
        chapter = request.chapter.strip()

        if not standard:

            raise HTTPException(
                status_code=400,
                detail="Standard is required."
            )

        if not subject:

            raise HTTPException(
                status_code=400,
                detail="Subject is required."
            )

        if not chapter:

            raise HTTPException(
                status_code=400,
                detail="Chapter is required."
            )

        # Get student's current level

        current_level = get_student_level(
            uid,
            subject
        )

        print()
        print("=" * 60)
        print("TEST GENERATION")
        print("=" * 60)
        print("User:", uid)
        print("Standard:", standard)
        print("Subject:", subject)
        print("Chapter:", chapter)
        print("Level:", current_level)

        # Get previous attempts

        try:

            previous_attempts = (
                get_previous_attempts(
                    uid,
                    subject,
                    chapter
                )
            )

        except Exception as e:

            print(
                "Previous Attempts Error:",
                str(e)
            )

            previous_attempts = []

        performance_context = (
            build_performance_context(
                previous_attempts
            )
        )

        # Retrieve chapter knowledge

        try:

            rag_results = retrieve_chunks(
                question=chapter,
                chat_history=[],
                top_k=8,
            )

            rag_context = build_rag_context(
                rag_results
            )

        except Exception as e:

            print(
                "RAG Error:",
                str(e)
            )

            raise HTTPException(
                status_code=500,
                detail="Unable to retrieve chapter content."
            )

        if not rag_context:

            raise HTTPException(
                status_code=404,
                detail=(
                    "No relevant chapter content "
                    "was found."
                )
            )
        
        # Build Gemini prompt
        
        prompt = build_test_prompt(
            standard=standard,
            subject=subject,
            chapter=chapter,
            level=current_level,
            performance_context=performance_context,
            rag_context=rag_context,
        )

        # Generate test

        try:

            response = client.models.generate_content(
                model="gemini-3.5-flash",
                contents=prompt,
            )

            if not response.text:

                raise HTTPException(
                    status_code=500,
                    detail=(
                        "Gemini returned an empty response."
                    )
                )

            raw_response = (
                response.text
                .replace("```json", "")
                .replace("```", "")
                .strip()
            )

            generated = json.loads(
                raw_response
            )

            questions = generated.get(
                "questions",
                []
            )

        except json.JSONDecodeError:

            raise HTTPException(
                status_code=500,
                detail=(
                    "Gemini returned invalid JSON."
                )
            )

        except HTTPException:

            raise

        except Exception as e:

            print(
                "Test Generation Error:",
                str(e)
            )

            raise HTTPException(
                status_code=500,
                detail=(
                    "Unable to generate test."
                )
            )

        # Validate test

        if not validate_test(
            questions,
            subject
        ):

            raise HTTPException(
                status_code=500,
                detail=(
                    "Generated test did not "
                    "match the required structure."
                )
            )

        # Create test ID

        test_id = str(
            uuid.uuid4()
        )

        # Add question IDs

        for index, question in enumerate(
            questions,
            start=1
        ):

            question["questionId"] = (
                f"{test_id}_{index}"
            )
        # IMPORTANT:
        # This is NOT a completed attempt.

        generated_test_ref = (
            db.collection("generatedTests")
            .document(test_id)
        )

        generated_test_ref.set(
            {
                "testId": test_id,
                "userId": uid,
                "standard": standard,
                "subject": subject,
                "chapter": chapter,
                "level": current_level,
                "questions": questions,
                "totalQuestions": 10,
                "createdAt":
                    firestore.SERVER_TIMESTAMP,
                "status": "generated",
            }
        )
        # Remove answers before sending to Flutter
        
        safe_questions = []

        for question in questions:

            safe_question = {
                "questionId":
                    question["questionId"],
                "type":
                    question["type"],
                "question":
                    question["question"],
                "topic":
                    question["topic"],
            }

            if question["type"] == "mcq":

                safe_question[
                    "options"
                ] = question["options"]

            elif question["type"] == "written":

                safe_question[
                    "marks"
                ] = question["marks"]

                safe_question[
                    "wordLimit"
                ] = question["wordLimit"]

            safe_questions.append(
                safe_question
            )

        print()
        print(
            "Test generated successfully:",
            test_id
        )

        return {
            "status": "success",
            "testId": test_id,
            "standard": standard,
            "subject": subject,
            "chapter": chapter,
            "level": current_level,
            "totalQuestions": 10,
            "questions": safe_questions,
        }
        # ========================================================
    # SUBMIT TEST
    # ========================================================

    @app.post("/submit-test")
    def submit_test(
        request: TestSubmissionRequest,
        authorization: str = Header(None),
    ):

        # ----------------------------------------------
        # Verify Firebase user
        # ----------------------------------------------

        decoded_token = verify_token(
            authorization
        )

        uid = decoded_token["uid"]

        print()
        print("=" * 60)
        print("TEST SUBMISSION")
        print("=" * 60)
        print("User:", uid)
        print("Test ID:", request.testId)

        # ----------------------------------------------
        # Get generated test
        # ----------------------------------------------

        test_ref = (
            db.collection("generatedTests")
            .document(request.testId)
        )

        test_doc = test_ref.get()

        if not test_doc.exists:

            raise HTTPException(
                status_code=404,
                detail="Test not found."
            )

        test_data = test_doc.to_dict()

        # ----------------------------------------------
        # Make sure this test belongs to this user
        # ----------------------------------------------

        if test_data.get("userId") != uid:

            raise HTTPException(
                status_code=403,
                detail="You cannot submit this test."
            )

        # ----------------------------------------------
        # Prevent duplicate submission
        # ----------------------------------------------

        if test_data.get("status") == "completed":

            raise HTTPException(
                status_code=400,
                detail="This test has already been submitted."
            )

        questions = test_data.get(
            "questions",
            []
        )

        # ----------------------------------------------
        # Convert submitted answers to dictionary
        # ----------------------------------------------

        submitted_answers = {
            answer.questionId: answer.answer
            for answer in request.answers
        }

        # ----------------------------------------------
        # Counters
        # ----------------------------------------------

        correct_count = 0
        wrong_count = 0
        unanswered_count = 0

        total_marks = 0
        obtained_marks = 0

        topic_performance = {}
        question_results = []

        # ==================================================
        # EVALUATE EACH QUESTION
        # ==================================================

        for question in questions:

            question_id = question.get(
                "questionId"
            )

            question_type = question.get(
                "type"
            )

            topic = question.get(
                "topic",
                "general"
            )

            user_answer = submitted_answers.get(
                question_id
            )

            # ------------------------------------------
            # Initialize topic
            # ------------------------------------------

            if topic not in topic_performance:

                topic_performance[topic] = {
                    "attempted": 0,
                    "correct": 0,
                    "wrong": 0,
                    "unanswered": 0,
                }

            # ------------------------------------------
            # MCQ
            # ------------------------------------------

            if question_type == "mcq":

                evaluation = evaluate_mcq(
                    question,
                    user_answer
                )

                total_marks += 1

                topic_performance[
                    topic
                ]["attempted"] += (
                    0
                    if evaluation["isUnanswered"]
                    else 1
                )

                if evaluation["isUnanswered"]:

                    unanswered_count += 1

                    topic_performance[
                        topic
                    ]["unanswered"] += 1

                elif evaluation["isCorrect"]:

                    correct_count += 1
                    obtained_marks += 1

                    topic_performance[
                        topic
                    ]["correct"] += 1

                else:

                    wrong_count += 1

                    topic_performance[
                        topic
                    ]["wrong"] += 1

                question_results.append({
                    "questionId": question_id,
                    "type": "mcq",
                    "question":
                        question.get(
                            "question",
                            ""
                        ),
                    "options":
                        question.get(
                            "options",
                            []
                        ),
                    "correctAnswer":
                        question.get(
                            "correctAnswer"
                        ),
                    "userAnswer":
                        user_answer,
                    "isCorrect":
                        evaluation["isCorrect"],
                    "isUnanswered":
                        evaluation["isUnanswered"],
                    "topic": topic,
                    "explanation":
                        question.get(
                            "explanation",
                            ""
                        ),
                })

            # ------------------------------------------
            # WRITTEN
            # ------------------------------------------

            elif question_type == "written":

                total_question_marks = int(
                    question.get(
                        "marks",
                        1
                    )
                )

                total_marks += (
                    total_question_marks
                )

                # No answer
                if (
                    user_answer is None
                    or not str(
                        user_answer
                    ).strip()
                ):

                    unanswered_count += 1

                    topic_performance[
                        topic
                    ]["unanswered"] += 1

                    question_results.append({
                        "questionId":
                            question_id,
                        "type":
                            "written",
                        "question":
                            question.get(
                                "question",
                                ""
                            ),
                        "userAnswer":
                            "",
                        "modelAnswer":
                            question.get(
                                "modelAnswer",
                                ""
                            ),
                        "marks":
                            total_question_marks,
                        "obtainedMarks":
                            0,
                        "topic":
                            topic,
                        "isCorrect":
                            False,
                        "isUnanswered":
                            True,
                    })

                    continue

                evaluation = evaluate_written_answer(
                    question,
                    user_answer,
                )

                obtained = evaluation[
                    "obtainedMarks"
                ]

                obtained_marks += obtained

                topic_performance[
                    topic
                ]["attempted"] += 1

                if evaluation["isCorrect"]:

                    topic_performance[
                        topic
                    ]["correct"] += 1

                else:

                    topic_performance[
                        topic
                    ]["wrong"] += 1

                question_results.append({
                    "questionId":
                        question_id,

                    "type":
                        "written",

                    "question":
                        question.get(
                            "question",
                            ""
                        ),

                    "userAnswer":
                        user_answer,

                    "modelAnswer":
                        question.get(
                            "modelAnswer",
                            ""
                        ),

                    "marks":
                        total_question_marks,

                    "obtainedMarks":
                        obtained,

                    "topic":
                        topic,

                    "isCorrect":
                        evaluation["isCorrect"],

                    "isUnanswered":
                        False,

                    "feedback":
                        evaluation["feedback"],
                })

        # ==================================================
        # SCORE
        # ==================================================

        if total_marks > 0:

            score = round(
                (
                    obtained_marks
                    / total_marks
                ) * 100,
                2
            )

        else:

            score = 0

        # ==================================================
        # TOPIC ACCURACY
        # ==================================================

        for topic, performance in (
            topic_performance.items()
        ):

            attempted = performance[
                "attempted"
            ]

            if attempted > 0:

                performance["accuracy"] = round(
                    (
                        performance["correct"]
                        / attempted
                    ) * 100,
                    2
                )

            else:

                performance["accuracy"] = 0

        # ==================================================
        # CREATE ATTEMPT ID
        # ==================================================

        attempt_id = str(
            uuid.uuid4()
        )

        # Determine test number
        previous_attempts = (
            db.collection("users")
            .document(uid)
            .collection("testAttempts")
            .where(
                "subject",
                "==",
                test_data.get("subject")
            )
            .where(
                "chapter",
                "==",
                test_data.get("chapter")
            )
            .stream()
        )

        test_number = 1

        for _ in previous_attempts:
            test_number += 1

        # ==================================================
        # SAVE ATTEMPT
        # ==================================================

        attempt_data = {

            "attemptId":
                attempt_id,

            "testId":
                request.testId,

            "subject":
                test_data.get(
                    "subject"
                ),

            "chapter":
                test_data.get(
                    "chapter"
                ),

            "standard":
                test_data.get(
                    "standard"
                ),

            "testNumber":
                test_number,

            "level":
                test_data.get(
                    "level"
                ),

            "totalQuestions":
                len(questions),

            "correctCount":
                correct_count,

            "wrongCount":
                wrong_count,

            "unansweredCount":
                unanswered_count,

            "totalMarks":
                total_marks,

            "obtainedMarks":
                obtained_marks,

            "score":
                score,

            "topicPerformance":
                topic_performance,

            "questions":
                question_results,

            "completedAt":
                firestore.SERVER_TIMESTAMP,
        }

        attempt_ref = (
            db.collection("users")
            .document(uid)
            .collection("testAttempts")
            .document(attempt_id)
        )

        attempt_ref.set(
            attempt_data
        )

        subject = test_data.get(
            "subject"
        )

        chapter = test_data.get(
            "chapter"
        )

        current_level = test_data.get(
            "level",
            "beginner"
        )

        recent_scores = get_recent_scores(
            uid,
            subject,
            chapter,
        )

        new_level = calculate_new_level(
            current_level,
            recent_scores,
        )

        print(
            "Previous Level:",
            current_level
        )

        print(
            "Recent Scores:",
            recent_scores
        )

        print(
            "New Level:",
            new_level
        )

        user_ref = (
            db.collection("users")
            .document(uid)
        )

        user_ref.set(
            {
                "subjectLevels": {
                    subject: new_level
                }
            },
            merge=True,
        )

        # ==================================================
        # MARK GENERATED TEST AS COMPLETED
        # ==================================================

        test_ref.update({
            "status": "completed",
            "completedAt":
                firestore.SERVER_TIMESTAMP,
            "attemptId":
                attempt_id,
        })

        print()
        print(
            "Test submitted successfully."
        )
        print(
            "Score:",
            score
        )

        # ==================================================
        # RESPONSE
        # ==================================================

        return {

            "status": "success",

            "message":
                "Test submitted successfully.",

            "attemptId":
                attempt_id,

            "testNumber":
                test_number,

            "subject":
                test_data.get(
                    "subject"
                ),

            "chapter":
                test_data.get(
                    "chapter"
                ),

            "level":
                test_data.get(
                    "level"
                ),

            "totalQuestions":
                len(questions),

            "correctCount":
                correct_count,

            "wrongCount":
                wrong_count,

            "unansweredCount":
                unanswered_count,

            "totalMarks":
                total_marks,

            "obtainedMarks":
                obtained_marks,

            "score":
                score,

            "topicPerformance":
                topic_performance,

            "questions":
                question_results,
        }

    # ==================================================
# TEST HISTORY
# ==================================================

    @app.get("/test-history")
    def get_test_history(
        subject: str | None = None,
        chapter: str | None = None,
        authorization: str = Header(None),
    ):

        # ----------------------------------------------
        # Verify Firebase user
        # ----------------------------------------------

        decoded_token = verify_token(
            authorization
        )

        uid = decoded_token["uid"]

        # ----------------------------------------------
        # Get attempts collection
        # ----------------------------------------------

        attempts_ref = (
            db.collection("users")
            .document(uid)
            .collection("testAttempts")
        )

        # ----------------------------------------------
        # Build query
        # ----------------------------------------------

        query = attempts_ref

        if subject:
            query = query.where(
                "subject",
                "==",
                subject,
            )

        if chapter:
            query = query.where(
                "chapter",
                "==",
                chapter,
            )

        query = query.order_by(
            "completedAt",
            direction=firestore.Query.DESCENDING,
        ).limit(20)

        # ----------------------------------------------
        # Read attempts
        # ----------------------------------------------

        docs = query.stream()

        attempts = []

        for doc in docs:

            data = doc.to_dict() or {}

            attempts.append({
                "attemptId":
                    data.get("attemptId"),

                "testId":
                    data.get("testId"),

                "subject":
                    data.get("subject"),

                "chapter":
                    data.get("chapter"),

                "standard":
                    data.get("standard"),

                "testNumber":
                    data.get("testNumber"),

                "level":
                    data.get("level"),

                "totalQuestions":
                    data.get("totalQuestions"),

                "correctCount":
                    data.get("correctCount"),

                "wrongCount":
                    data.get("wrongCount"),

                "unansweredCount":
                    data.get("unansweredCount"),

                "totalMarks":
                    data.get("totalMarks"),

                "obtainedMarks":
                    data.get("obtainedMarks"),

                "score":
                    data.get("score"),

                "topicPerformance":
                    data.get("topicPerformance", {}),

                "completedAt":
                    data.get("completedAt"),
            })

        # ----------------------------------------------
        # Response
        # ----------------------------------------------

        return {
            "status": "success",
            "totalAttempts": len(attempts),
            "attempts": attempts,
        }

    @app.get("/test-result/{attempt_id}")
    def get_test_result(
        attempt_id: str,
        authorization: str = Header(None),
    ):

        # ----------------------------------------------
        # Verify Firebase user
        # ----------------------------------------------

        decoded_token = verify_token(
            authorization
        )

        uid = decoded_token["uid"]

        # ----------------------------------------------
        # Get attempt
        # ----------------------------------------------

        attempt_ref = (
            db.collection("users")
            .document(uid)
            .collection("testAttempts")
            .document(attempt_id)
        )

        attempt_doc = attempt_ref.get()

        if not attempt_doc.exists:

            raise HTTPException(
                status_code=404,
                detail="Test result not found."
            )

        attempt_data = attempt_doc.to_dict() or {}

        # ----------------------------------------------
        # Return complete result
        # ----------------------------------------------

        return {
            "status": "success",

            "attemptId":
                attempt_data.get("attemptId"),

            "testId":
                attempt_data.get("testId"),

            "subject":
                attempt_data.get("subject"),

            "chapter":
                attempt_data.get("chapter"),

            "standard":
                attempt_data.get("standard"),

            "testNumber":
                attempt_data.get("testNumber"),

            "level":
                attempt_data.get("level"),

            "totalQuestions":
                attempt_data.get("totalQuestions"),

            "correctCount":
                attempt_data.get("correctCount"),

            "wrongCount":
                attempt_data.get("wrongCount"),

            "unansweredCount":
                attempt_data.get("unansweredCount"),

            "totalMarks":
                attempt_data.get("totalMarks"),

            "obtainedMarks":
                attempt_data.get("obtainedMarks"),

            "score":
                attempt_data.get("score"),

            "topicPerformance":
                attempt_data.get(
                    "topicPerformance",
                    {}
                ),

            "questions":
                attempt_data.get(
                    "questions",
                    []
                ),

            "completedAt":
                attempt_data.get("completedAt"),
        }

    @app.get("/test-progress")
    def get_test_progress(
        subject: str,
        chapter: str,
        authorization: str = Header(None),
    ):

        # ----------------------------------------------
        # Verify Firebase user
        # ----------------------------------------------

        decoded_token = verify_token(
            authorization
        )

        uid = decoded_token["uid"]

        # ----------------------------------------------
        # Get attempts
        # ----------------------------------------------

        attempts_ref = (
            db.collection("users")
            .document(uid)
            .collection("testAttempts")
        )

        query = (
            attempts_ref
            .where(
                "subject",
                "==",
                subject,
            )
            .where(
                "chapter",
                "==",
                chapter,
            )
            .order_by(
                "completedAt",
                direction=firestore.Query.DESCENDING,
            )
        )

        docs = query.stream()

        attempts = []

        for doc in docs:

            data = doc.to_dict() or {}

            attempts.append(data)

        # ----------------------------------------------
        # No tests attempted
        # ----------------------------------------------

        if not attempts:

            current_level = get_student_level(
                uid,
                subject,
            )

            return {
                "status": "success",
                "subject": subject,
                "chapter": chapter,
                "currentLevel": current_level,
                "totalTests": 0,
                "latestScore": None,
                "averageScore": None,
                "highestScore": None,
                "weakTopics": {},
            }

        # ----------------------------------------------
        # Scores
        # ----------------------------------------------

        scores = []

        for attempt in attempts:

            score = attempt.get("score")

            if score is not None:

                scores.append(
                    float(score)
                )

        latest_score = (
            scores[0]
            if scores
            else None
        )

        average_score = (
            round(
                sum(scores) / len(scores),
                2,
            )
            if scores
            else None
        )

        highest_score = (
            max(scores)
            if scores
            else None
        )

        # ----------------------------------------------
        # Weak topics
        # ----------------------------------------------

        weak_topics = {}

        for attempt in attempts:

            topic_performance = (
                attempt.get(
                    "topicPerformance",
                    {}
                )
            )

            for topic, performance in (
                topic_performance.items()
            ):

                accuracy = performance.get(
                    "accuracy",
                    0,
                )

                if accuracy < 60:

                    if topic not in weak_topics:

                        weak_topics[topic] = {
                            "attempts": 0,
                            "accuracySum": 0,
                        }

                    weak_topics[topic][
                        "attempts"
                    ] += 1

                    weak_topics[topic][
                        "accuracySum"
                    ] += accuracy

        # ----------------------------------------------
        # Calculate average topic accuracy
        # ----------------------------------------------

        for topic, data in weak_topics.items():

            attempts_count = data["attempts"]

            data["averageAccuracy"] = round(
                data["accuracySum"]
                / attempts_count,
                2,
            )

            del data["accuracySum"]

        # ----------------------------------------------
        # Current student level
        # ----------------------------------------------

        current_level = get_student_level(
            uid,
            subject,
        )

        # ----------------------------------------------
        # Response
        # ----------------------------------------------

        return {
            "status": "success",

            "subject": subject,

            "chapter": chapter,

            "currentLevel": current_level,

            "totalTests": len(attempts),

            "latestScore": latest_score,

            "averageScore": average_score,

            "highestScore": highest_score,

            "weakTopics": weak_topics,
        }