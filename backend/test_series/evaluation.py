import json

from fastapi import HTTPException


# ============================================================
# EVALUATE MCQ
# ============================================================

def evaluate_mcq(
    question,
    user_answer,
):
    """
    Evaluate one MCQ question.
    """

    correct_answer = question.get(
        "correctAnswer"
    )

    # --------------------------------------------------------
    # Unanswered
    # --------------------------------------------------------

    if (
        user_answer is None
        or user_answer == ""
    ):

        return {
            "isCorrect": False,
            "isUnanswered": True,
            "obtainedMarks": 0,
        }

    # --------------------------------------------------------
    # Convert answer to integer
    # --------------------------------------------------------

    try:

        user_answer_index = int(
            user_answer
        )

    except (ValueError, TypeError):

        return {
            "isCorrect": False,
            "isUnanswered": False,
            "obtainedMarks": 0,
        }

    # --------------------------------------------------------
    # Compare answer
    # --------------------------------------------------------

    is_correct = (
        user_answer_index
        == correct_answer
    )

    return {
        "isCorrect": is_correct,
        "isUnanswered": False,
        "obtainedMarks":
            1 if is_correct else 0,
    }


# ============================================================
# EVALUATE WRITTEN ANSWER
# ============================================================

def evaluate_written_answer(
    client,
    question,
    student_answer,
):

    question_text = question.get(
        "question",
        ""
    )

    model_answer = question.get(
        "modelAnswer",
        ""
    )

    max_marks = int(
        question.get(
            "marks",
            1
        )
    )

    word_limit = int(
        question.get(
            "wordLimit",
            80
        )
    )

    # ========================================================
    # GEMINI EVALUATION PROMPT
    # ========================================================

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
- Use only integer or decimal marks appropriate
  for the maximum marks.
- Do not exceed {max_marks}.
- Keep feedback short and student-friendly.
"""

    # ========================================================
    # CALL GEMINI
    # ========================================================

    try:

        response = client.models.generate_content(
            model="gemini-3.5-flash",
            contents=prompt,
        )

        if not response.text:

            raise ValueError(
                "Gemini returned an empty response."
            )

        # ----------------------------------------------------
        # Clean JSON response
        # ----------------------------------------------------

        raw_response = (
            response.text
            .replace("```json", "")
            .replace("```", "")
            .strip()
        )

        evaluation = json.loads(
            raw_response
        )

        # ----------------------------------------------------
        # Get marks
        # ----------------------------------------------------

        obtained_marks = float(
            evaluation.get(
                "obtainedMarks",
                0
            )
        )

        # ----------------------------------------------------
        # Safety validation
        #
        # Never allow Gemini to give more marks
        # than the question carries.
        # ----------------------------------------------------

        obtained_marks = max(
            0,
            min(
                obtained_marks,
                max_marks
            )
        )

        # ----------------------------------------------------
        # Return evaluation
        # ----------------------------------------------------

        return {

            "obtainedMarks":
                obtained_marks,

            "isCorrect":
                bool(
                    evaluation.get(
                        "isCorrect",
                        False
                    )
                ),

            "feedback":
                evaluation.get(
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