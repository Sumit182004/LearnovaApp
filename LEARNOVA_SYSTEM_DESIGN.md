# Learnova --- System Design and Adaptive Assessment Specification

## 1. Project Overview

Learnova is an adaptive educational application for Standard 10 and
Standard 12 students. It includes chapter-based learning content, an
AI-generated diagnostic assessment, subject-wise proficiency
classification, an adaptive Test Series, and progress tracking.

The assessment assigns **Beginner, Intermediate, or Advanced**
proficiency per subject. The earlier Level 1--10 model is not used.

## 2. Supported Standards and Subjects

### Standard 10

-   Mathematics
-   Science
-   English

### Standard 12

-   Mathematics
-   Physics
-   Chemistry
-   English

Biology is currently outside the Standard 12 scope.

## 3. Learning Content Structure

Learnova stores syllabus content in separate chapter-wise JSON files,
not one subject-wise JSON file. The initial assessment evaluates broad
subject-level concepts. Later, chapter-wise JSON content can ground Test
Series question generation for the chapter selected by the student.

## 4. Initial Assessment Flow

    Registration
        ↓
    Email Verification
        ↓
    Login
        ↓
    Check assessmentCompleted
        ↓
    Initial Assessment (if false)
        ↓
    Generate exactly 15 questions
        ↓
    Submit answers
        ↓
    Evaluate subjects separately
        ↓
    Assign Beginner / Intermediate / Advanced
        ↓
    Save subject-wise proficiency
        ↓
    Set assessmentCompleted = true
        ↓
    Home Page

Questions are dynamically generated with Gemini. Different students can
receive different questions, while the backend keeps the assessment
structure consistent.

## 5. Standard 10 Assessment

  Subject         Beginner   Intermediate   Advanced    Total
  ------------- ---------- -------------- ---------- --------
  Mathematics            2              2          1        5
  Science                2              2          1        5
  English                2              2          1        5
  **Total**          **6**          **6**      **3**   **15**

### Mathematics coverage

Number systems and arithmetic, algebra, geometry, mensuration,
statistics and probability.

### Science coverage

Physics fundamentals, chemistry fundamentals, life processes and
biology, scientific reasoning, and application of scientific concepts.

### English coverage

Grammar, vocabulary, sentence usage, reading comprehension, and
inference/language application.

## 6. Standard 12 Assessment

  Subject         Beginner   Intermediate   Advanced    Total
  ------------- ---------- -------------- ---------- --------
  Mathematics            2              1          1        4
  Physics                2              1          1        4
  Chemistry              2              1          1        4
  English                1              1          1        3
  **Total**          **7**          **4**      **4**   **15**

### Mathematics coverage

Relations and functions, algebra, calculus, vectors and 3D geometry,
probability and mathematical applications.

### Physics coverage

Electricity, magnetism, optics, modern physics, and numerical/conceptual
applications.

### Chemistry coverage

Physical chemistry, organic chemistry, inorganic chemistry, and chemical
reasoning/applications.

### English coverage

Grammar and language usage, reading comprehension, and
inference/interpretation.

## 7. AI Question Generation Rules

The backend validates the standard as `10` or `12`, selects the
corresponding configuration, and asks Gemini to generate exactly 15
MCQs.

Every question must have: - A supported subject - A valid difficulty:
beginner, intermediate, or advanced - Exactly four options - Exactly one
correct answer - Content appropriate to the selected standard

The backend validates the exact subject and difficulty counts. Invalid
AI output is rejected instead of being sent to the student. Questions
are shuffled before display.

Current development model: `gemini-3.5-flash`.

The Gemini API key is stored in `backend/.env` and must never be
committed to GitHub or placed directly in Flutter code.

## 8. Preliminary Scoring and Classification

For Standard 10, the proposed weights are:

  Difficulty       Correct-answer points
  -------------- -----------------------
  Beginner                             2
  Intermediate                         3
  Advanced                             5
  Wrong                                0

Maximum per subject is 15 points.

Weighted score may be stored for analytics, but proficiency should also
depend on the pattern of correct answers.

### Preliminary Standard 10 rule

**Advanced** - Advanced question correct - At least one Intermediate
question correct - At least three total questions correct

**Intermediate** - At least one Intermediate question correct - At least
two total questions correct

**Beginner** - All other patterns

The exact Standard 12 classification algorithm is still to be finalized
because each subject has only 3--4 questions.

## 9. Response Time

Response time may be recorded for future analytics, but it will not
initially reduce assessment scores. Reading speed, device performance,
language ability, and thinking style can affect response time.

## 10. Subject-Wise Proficiency

Proficiency is independent for every subject. For example:

    Mathematics → Beginner
    Science → Intermediate
    English → Advanced

A conceptual Firestore structure is:

    assessmentCompleted: true
    subjectLevels:
        Mathematics: beginner
        Science: intermediate
        English: advanced

The final Firestore schema will be designed before implementation.

## 11. Adaptive Test Series

The Test Series uses the student's current proficiency in the selected
subject.

For a 10-question test:

  -----------------------------------------------------------------------
  Current        Beginner questions       Intermediate Advanced questions
  proficiency                                questions 
  -------------- ------------------ ------------------ ------------------
  Beginner                        6                  3                  1

  Intermediate                    2                  6                  2

  Advanced                        1                  3                  6
  -----------------------------------------------------------------------

The student selects a subject and chapter. The chapter-wise JSON can be
used as grounding content, while the student's subject proficiency
determines the question difficulty distribution.

## 12. Future Proficiency Adjustment

Proficiency should not change because of one test. The preliminary
approach evaluates the last three tests for that subject:

-   80% or above in at least 2 of the last 3 tests → move up one
    category.
-   Below 40% in at least 2 of the last 3 tests → move down one
    category.
-   Otherwise → maintain the current category.

These thresholds are preliminary and will be finalized before Test
Series implementation.

## 13. Backend Architecture

    backend/
    ├── app.py
    ├── requirements.txt
    └── .env

Technologies currently used: - Python - FastAPI - Uvicorn - Gemini API -
python-dotenv

Current flow:

    Flutter
        ↓
    FastAPI Backend
        ↓
    Gemini API
        ↓
    Structured assessment JSON
        ↓
    Backend validation
        ↓
    Flutter

The backend currently runs locally during development and can later be
deployed to Render or another suitable cloud platform.

## 14. Current Backend Implementation

Implemented and tested: - FastAPI setup - Environment-based Gemini API
key loading - Gemini connection - Standard 10/12 validation - Separate
assessment configurations - Dynamic prompt generation - Exactly 15
generated questions - Subject and difficulty distribution validation -
Four-option validation - Correct-answer index validation - Question
shuffling

Current endpoint:

    POST /generate-assessment

Example request:

    {"standard": "10"}

or:

    {"standard": "12"}

## 15. Next Development Steps

1.  Finalize classification rules for both standards.
2.  Build `/submit-assessment`.
3.  Calculate subject-wise results.
4.  Design and store results in Firestore.
5.  Connect the Flutter assessment UI.
6.  Build the adaptive Test Series later.

## 16. Mentor Explanation

> Learnova uses an AI-generated diagnostic assessment to estimate a
> student's proficiency separately for each supported subject. Students
> are classified as Beginner, Intermediate, or Advanced rather than
> being assigned arbitrary numerical levels. The backend controls the
> question count, subjects, difficulty distribution, and academic level
> while Gemini dynamically generates different questions. The generated
> output is validated before being shown to the student. The resulting
> subject-wise proficiency is used by the adaptive Test Series to
> personalize future tests, and proficiency can later change based on
> consistent recent performance.

## 17. Finalized Decisions

-   Exactly 15 initial assessment questions.
-   Standards 10 and 12 are supported.
-   Standard 10: Mathematics, Science, English.
-   Standard 12: Mathematics, Physics, Chemistry, English.
-   Biology is excluded from the current Standard 12 scope.
-   Proficiency categories are Beginner, Intermediate, and Advanced.
-   Level 1--10 is not used.
-   Questions are dynamically generated and backend-validated.
-   Educational content remains chapter-wise JSON.
-   Subject proficiency is independent.
-   Response time may be recorded but does not currently penalize
    scoring.
-   API secrets remain in backend environment variables.

*Last updated: July 2026*
