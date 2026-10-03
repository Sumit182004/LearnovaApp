from fastapi import HTTPException
from firebase_admin import firestore

from .utils import normalize_level


# ============================================================
# GET STUDENT LEVEL
# ============================================================

def get_student_level(
    db,
    uid: str,
    subject: str,
) -> str:

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


# ============================================================
# GET PREVIOUS ATTEMPTS
# ============================================================

def get_previous_attempts(
    db,
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


# ============================================================
# BUILD PERFORMANCE CONTEXT
# ============================================================

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


# ============================================================
# GET RECENT SCORES
# ============================================================

def get_recent_scores(
    db,
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


# ============================================================
# CALCULATE NEW LEVEL
# ============================================================

def calculate_new_level(
    current_level: str,
    recent_scores: list[float],
) -> str:

    current_level = normalize_level(
        current_level
    )

    if not recent_scores:
        return current_level

    # Use latest 3 tests
    scores = recent_scores[:3]

    average_score = (
        sum(scores) / len(scores)
    )

    # --------------------------------------------------------
    # BEGINNER
    # --------------------------------------------------------

    if current_level == "beginner":

        if (
            len(scores) >= 2
            and average_score >= 75
        ):
            return "intermediate"

        return "beginner"

    # --------------------------------------------------------
    # INTERMEDIATE
    # --------------------------------------------------------

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

    # --------------------------------------------------------
    # ADVANCED
    # --------------------------------------------------------

    if current_level == "advanced":

        if (
            len(scores) >= 3
            and average_score < 40
        ):
            return "intermediate"

        return "advanced"

    return current_level