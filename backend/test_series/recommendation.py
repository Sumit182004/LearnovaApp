from typing import Any

from firebase_admin import firestore
# ============================================================
# LEVEL MAPPING
# ============================================================

LEVEL_MAP = {
    "beginner": 0,
    "intermediate": 1,
    "advanced": 2,
}

# ============================================================
# GET STUDENT ATTEMPTS FOR RECOMMENDATION
# ============================================================

def get_recommendation_data(
    db,
    uid: str,
    subject: str,
    chapter: str,
):
    """
    Fetch previous Test Series attempts for the
    given student, subject and chapter.
    """

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
        .limit(5)
    )

    docs = query.stream()

    attempts = []

    for doc in docs:
        data = doc.to_dict() or {}
        attempts.append(data)

    return attempts

# ============================================================
# BUILD STUDENT FEATURES
# ============================================================

def build_student_features(
    attempts: list[dict[str, Any]],
    current_level: str,
) -> dict[str, Any]:

    if not attempts:
        return {
            "number_of_tests": 0,
            "latest_score": None,
            "average_score": None,
            "score_trend": 0,
            "average_accuracy": 0,
            "weakest_topic": None,
            "weakest_topic_accuracy": 0,
            "wrong_rate": 0,
            "unanswered_rate": 0,
            "current_level": LEVEL_MAP.get(
                current_level.lower(),
                0
            ),
        }

    # ---------------------------------------------
    # Overall performance
    # ---------------------------------------------

    scores = [
        float(a.get("score", 0))
        for a in attempts
        if a.get("score") is not None
    ]

    latest_score = scores[0] if scores else None

    average_score = (
        round(sum(scores) / len(scores), 2)
        if scores
        else 0
    )

    # ---------------------------------------------
    # Score trend
    # attempts are newest → oldest
    # ---------------------------------------------

    if len(scores) >= 2:
        score_trend = scores[0] - scores[-1]
    else:
        score_trend = 0

    # ---------------------------------------------
    # Topic performance
    # ---------------------------------------------

    topic_data = {}

    for attempt in attempts:

        topic_performance = attempt.get(
            "topicPerformance",
            {}
        )

        for topic, performance in topic_performance.items():

            attempted = int(
                performance.get("attempted", 0)
            )

            correct = int(
                performance.get("correct", 0)
            )

            if attempted <= 0:
                continue

            if topic not in topic_data:
                topic_data[topic] = {
                    "attempted": 0,
                    "correct": 0,
                }

            topic_data[topic]["attempted"] += attempted
            topic_data[topic]["correct"] += correct

    # ---------------------------------------------
    # Calculate topic accuracy
    # ---------------------------------------------

    weakest_topic = None
    weakest_topic_accuracy = 100

    for topic, data in topic_data.items():

        attempted = data["attempted"]
        correct = data["correct"]

        accuracy = round(
            (correct / attempted) * 100,
            2
        )

        if accuracy < weakest_topic_accuracy:
            weakest_topic = topic
            weakest_topic_accuracy = accuracy

    # ---------------------------------------------
    # Overall question statistics
    # ---------------------------------------------

    total_questions = sum(
        int(a.get("totalQuestions", 0))
        for a in attempts
    )

    total_wrong = sum(
        int(a.get("wrongCount", 0))
        for a in attempts
    )

    total_unanswered = sum(
        int(a.get("unansweredCount", 0))
        for a in attempts
    )

    wrong_rate = (
        round(
            (total_wrong / total_questions) * 100,
            2
        )
        if total_questions
        else 0
    )

    unanswered_rate = (
        round(
            (total_unanswered / total_questions) * 100,
            2
        )
        if total_questions
        else 0
    )

    # ---------------------------------------------
    # Average accuracy
    # ---------------------------------------------

    total_correct = sum(
        int(a.get("correctCount", 0))
        for a in attempts
    )

    average_accuracy = (
        round(
            (total_correct / total_questions) * 100,
            2
        )
        if total_questions
        else 0
    )

    return {
        "number_of_tests": len(attempts),
        "latest_score": latest_score,
        "average_score": average_score,
        "score_trend": score_trend,
        "average_accuracy": average_accuracy,
        "weakest_topic": weakest_topic,
        "weakest_topic_accuracy": (
            weakest_topic_accuracy
            if weakest_topic
            else 0
        ),
        "wrong_rate": wrong_rate,
        "unanswered_rate": unanswered_rate,
        "current_level": LEVEL_MAP.get(
            current_level.lower(),
            0
        ),
    }

# ============================================================
# BUILD TRAINING DATASET
# ============================================================

def build_training_dataset(
    student_records: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """
    Convert historical student performance records
    into ML training rows.

    Each record should contain:

        {
            "attempts": [...],
            "current_level": "beginner"
        }

    The function creates one feature row for each
    student/chapter history.
    """

    training_data = []

    for record in student_records:

        attempts = record.get(
            "attempts",
            [],
        )

        current_level = record.get(
            "current_level",
            "beginner",
        )

        # --------------------------------------------
        # Skip students with no test history
        # --------------------------------------------

        if not attempts:
            continue

        # --------------------------------------------
        # Build features
        # --------------------------------------------

        features = build_student_features(
            attempts=attempts,
            current_level=current_level,
        )

        # --------------------------------------------
        # Add metadata
        # --------------------------------------------

        subject = record.get(
            "subject"
        )

        chapter = record.get(
            "chapter"
        )

        # --------------------------------------------
        # Training row
        # --------------------------------------------

        row = {
            "subject": subject,
            "chapter": chapter,

            "number_of_tests":
                features["number_of_tests"],

            "latest_score":
                features["latest_score"],

            "average_score":
                features["average_score"],

            "score_trend":
                features["score_trend"],

            "average_accuracy":
                features["average_accuracy"],

            "weakest_topic_accuracy":
                features["weakest_topic_accuracy"],

            "wrong_rate":
                features["wrong_rate"],

            "unanswered_rate":
                features["unanswered_rate"],

            "current_level":
                features["current_level"],

            "weakest_topic":
                features["weakest_topic"],
        }

        training_data.append(row)

    return training_data

# ============================================================
# GENERATE INITIAL RECOMMENDATION
# ============================================================

def generate_recommendation(
    features: dict[str, Any],
    subject: str,
    chapter: str,
) -> dict[str, Any]:

    weakest_topic = features.get(
        "weakest_topic"
    )

    weakest_topic_accuracy = features.get(
        "weakest_topic_accuracy",
        0
    )

    latest_score = features.get(
        "latest_score"
    )

    score_trend = features.get(
        "score_trend",
        0
    )

    average_score = features.get(
        "average_score",
        0
    )

    current_level = features.get(
        "current_level",
        0
    )

    # ---------------------------------------------
    # Weak topic
    # ---------------------------------------------

    if (
        weakest_topic
        and weakest_topic_accuracy < 60
    ):
        return {
            "subject": subject,
            "chapter": chapter,
            "recommendedAction": "practice_weak_topic",
            "recommendedTopic": weakest_topic,
            "recommendedLevel": (
                "beginner"
                if current_level == 0
                else "intermediate"
                if current_level == 1
                else "advanced"
            ),
            "reason": (
                f"Student has low accuracy "
                f"({weakest_topic_accuracy}%) "
                f"in {weakest_topic}."
            ),
        }

    # ---------------------------------------------
    # Low overall performance
    # ---------------------------------------------

    if (
        latest_score is not None
        and latest_score < 40
    ):
        return {
            "subject": subject,
            "chapter": chapter,
            "recommendedAction": "repeat_current_level",
            "recommendedTopic": weakest_topic,
            "recommendedLevel": (
                "beginner"
                if current_level == 0
                else "intermediate"
                if current_level == 1
                else "advanced"
            ),
            "reason": (
                f"Latest score is {latest_score}%. "
                "Student should continue practicing "
                "at the current level."
            ),
        }

    # ---------------------------------------------
    # Improvement
    # ---------------------------------------------

    if (
        score_trend > 10
        and average_score >= 70
    ):
        next_level = (
            "intermediate"
            if current_level == 0
            else "advanced"
            if current_level == 1
            else "advanced"
        )

        return {
            "subject": subject,
            "chapter": chapter,
            "recommendedAction": "progress_to_next_level",
            "recommendedTopic": None,
            "recommendedLevel": next_level,
            "reason": (
                "Student is showing consistent "
                "improvement and good overall performance."
            ),
        }

    # ---------------------------------------------
    # Default
    # ---------------------------------------------

    return {
        "subject": subject,
        "chapter": chapter,
        "recommendedAction": "practice_current_chapter",
        "recommendedTopic": weakest_topic,
        "recommendedLevel": (
            "beginner"
            if current_level == 0
            else "intermediate"
            if current_level == 1
            else "advanced"
        ),
        "reason": (
            "Continue practicing the current "
            "chapter and level."
        ),
    }

# ============================================================
# BUILD STUDENT RECOMMENDATION
# ============================================================

def build_student_recommendation(
    db,
    uid: str,
    subject: str,
    chapter: str,
    current_level: str,
):
    """
    Fetch student history, build features and
    generate the recommendation.
    """

    attempts = get_recommendation_data(
        db=db,
        uid=uid,
        subject=subject,
        chapter=chapter,
    )

    features = build_student_features(
        attempts=attempts,
        current_level=current_level,
    )

    recommendation = generate_recommendation(
        features=features,
        subject=subject,
        chapter=chapter,
    )

    return {
        "features": features,
        "recommendation": recommendation,
    }