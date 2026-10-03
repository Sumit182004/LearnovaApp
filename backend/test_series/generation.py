import json
import uuid

from fastapi import HTTPException
from firebase_admin import firestore

from rag.retriever import retrieve_chunks
from rag.context_builder import build_rag_context
from .recommendation import build_student_recommendation
from .performance import (
    get_student_level,
    get_previous_attempts,
    build_performance_context,
)
from .utils import calculate_time_limit

# ============================================================
# BUILD TEST PROMPT
# ============================================================

def build_test_prompt(
    standard: str,
    subject: str,
    chapter: str,
    level: str,
    performance_context: dict,
    rag_context: str,
    recommendation: dict,
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
    recommendation_instruction = json.dumps(
    recommendation,
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

PERSONALIZED RECOMMENDATION:

The following recommendation was generated from
the student's performance:

{recommendation_instruction}

Use this recommendation when designing the test.

If a weak topic is specified:
- Give appropriate attention to that topic.
- Do not make every question about the weak topic.
- Keep the test balanced.
- Do not repeat previous questions.
- Keep questions within the student's current level.
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


# ============================================================
# VALIDATE GENERATED TEST
# ============================================================

def validate_test(
    questions,
    subject,
):

    # Must contain exactly 10 questions

    if not isinstance(
        questions,
        list
    ):
        return False

    if len(questions) != 10:
        return False

    # ========================================================
    # SCIENCE
    # ========================================================

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

    # ========================================================
    # OTHER SUBJECTS
    # ========================================================

    else:

        for question in questions:

            if question.get("type") != "mcq":

                return False

    # ========================================================
    # INDIVIDUAL QUESTION VALIDATION
    # ========================================================

    for question in questions:

        if not question.get("question"):

            return False

        if not question.get("topic"):

            return False

        question_type = question.get(
            "type"
        )

        # ----------------------------------------------------
        # MCQ
        # ----------------------------------------------------

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

        # ----------------------------------------------------
        # WRITTEN
        # ----------------------------------------------------

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


# ============================================================
# GENERATE TEST
# ============================================================

def generate_test(
    db,
    client,
    uid: str,
    standard: str,
    subject: str,
    chapter: str,
):

    # ========================================================
    # CURRENT STUDENT LEVEL
    # ========================================================

    current_level = get_student_level(
        db,
        uid,
        subject,
    )
    # --------------------------------------------------
    # Get personalized recommendation
    # --------------------------------------------------

    recommendation_data = build_student_recommendation(
        db=db,
        uid=uid,
        subject=subject,
        chapter=chapter,
        current_level=current_level,
    )

    recommendation = recommendation_data[
        "recommendation"
    ]

    # ========================================================
    # PREVIOUS ATTEMPTS
    # ========================================================

    try:

        previous_attempts = (
            get_previous_attempts(
                db,
                uid,
                subject,
                chapter,
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

    # ========================================================
    # RAG
    # ========================================================

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

    # ========================================================
    # BUILD PROMPT
    # ========================================================

    prompt = build_test_prompt(
    standard=standard,
    subject=subject,
    chapter=chapter,
    level=current_level,
    performance_context=performance_context,
    rag_context=rag_context,
    recommendation=recommendation,
    )

    # ========================================================
    # GEMINI
    # ========================================================

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

    # ========================================================
    # VALIDATE
    # ========================================================

    if not validate_test(
        questions,
        subject,
    ):

        raise HTTPException(
            status_code=500,
            detail=(
                "Generated test did not "
                "match the required structure."
            )
        )
    # ========================================================
    # TIME LIMIT
    # ========================================================

    time_limit_minutes = calculate_time_limit(
        subject,
        len(questions),
    )

    # ========================================================
    # TEST ID
    # ========================================================

    test_id = str(
        uuid.uuid4()
    )

    # ========================================================
    # QUESTION IDs
    # ========================================================

    for index, question in enumerate(
        questions,
        start=1
    ):

        question["questionId"] = (
            f"{test_id}_{index}"
        )

    # ========================================================
    # SAVE GENERATED TEST
    # ========================================================

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
            "recommendation": recommendation,
            "questions": questions,
            "totalQuestions": 10,
            "createdAt":
                firestore.SERVER_TIMESTAMP,
            "status": "generated",
        }
    )

    # ========================================================
    # SAFE QUESTIONS
    #
    # Do NOT send correctAnswer/modelAnswer
    # to Flutter.
    # ========================================================

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
        "testId": test_id,
        "standard": standard,
        "subject": subject,
        "chapter": chapter,
        "level": current_level,
        "totalQuestions": 10,
        "time_limit_minutes": time_limit_minutes,
        "questions": safe_questions,
    }
