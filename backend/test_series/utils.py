# ============================================================
# TEST SERIES CONFIGURATION
# ============================================================

SUPPORTED_SUBJECTS = {
    "Mathematics",
    "Science",
    "English",
    "Physics",
    "Chemistry",
}


# ============================================================
# LEVEL ORDER
# ============================================================

LEVEL_ORDER = {
    "beginner": 0,
    "intermediate": 1,
    "advanced": 2,
}


# ============================================================
# NORMALIZE LEVEL
# ============================================================

def normalize_level(level: str) -> str:

    if not level:
        return "beginner"

    level = level.lower().strip()

    if level not in LEVEL_ORDER:
        return "beginner"

    return level

def calculate_time_limit(
    subject: str,
    num_questions: int,
) -> int:

    subject_type = subject.lower().strip()

    if subject_type in {
        "mathematics",
        "maths",
    }:
        return num_questions * 2

    return num_questions * 6