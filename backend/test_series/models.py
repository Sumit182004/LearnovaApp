from pydantic import BaseModel


# ============================================================
# TEST GENERATION REQUEST
# ============================================================

class TestGenerationRequest(BaseModel):
    standard: str
    subject: str
    chapter: str


# ============================================================
# TEST ANSWER
# ============================================================

class TestAnswer(BaseModel):
    questionId: str
    answer: str | None = None


# ============================================================
# TEST SUBMISSION REQUEST
# ============================================================

class TestSubmissionRequest(BaseModel):
    testId: str
    answers: list[TestAnswer]