import os
import json
import random
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel
from google import genai
import uuid
import copy

import firebase_admin
from firebase_admin import credentials
from firebase_admin import auth
from firebase_admin import firestore
# ENVIRONMENT

load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise ValueError(
        "GEMINI_API_KEY is not set in the .env file"
    )
# GEMINI CLIENT

client = genai.Client(
    api_key=GEMINI_API_KEY,
)

# FIREBASE ADMIN

firebase_credentials = os.getenv(
    "FIREBASE_SERVICE_ACCOUNT"
)

if firebase_credentials:
    # Production / deployed backend
    service_account_info = json.loads(
        firebase_credentials
    )

    cred = credentials.Certificate(
        service_account_info
    )

else:
    # Local development
    cred = credentials.Certificate(
        "serviceAccountKey.json"
    )

firebase_admin.initialize_app(cred)

db = firestore.client()
# FASTAPI

app = FastAPI(
    title="Learnova Backend",
)

def verify_firebase_token(authorization: str):

    if not authorization:
        raise HTTPException(
            status_code=401,
            detail="Authorization token is missing.",
        )

    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Invalid authorization format.",
        )

    token = authorization.replace(
        "Bearer ",
        "",
        1,
    ).strip()

    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token

    except Exception as e:
        print("Firebase Token Error:", str(e))

        raise HTTPException(
            status_code=401,
            detail="Invalid or expired authentication token.",
        )
@app.get("/")
def health_check():
    return {
        "status": "ok",
        "service": "Learnova Backend",
    }

# REQUEST MODEL

class AssessmentRequest(BaseModel):
    standard: str

class AnswerItem(BaseModel):
    questionId: int
    selectedAnswer: int

class AssessmentSubmission(BaseModel):
    assessmentId: str
    answers: list[AnswerItem]
# ASSESSMENT CONFIGURATION

ASSESSMENT_CONFIG = {

    "10": {
        "Mathematics": {
            "beginner": 2,
            "intermediate": 2,
            "advanced": 1,
            "topics": [
                "Number systems and arithmetic",
                "Algebra",
                "Geometry",
                "Mensuration",
                "Statistics and probability",
            ],
        },

        "Science": {
            "beginner": 2,
            "intermediate": 2,
            "advanced": 1,
            "topics": [
                "Physics fundamentals",
                "Chemistry fundamentals",
                "Life processes and biology",
                "Scientific reasoning",
                "Application of scientific concepts",
            ],
        },

        "English": {
            "beginner": 2,
            "intermediate": 2,
            "advanced": 1,
            "topics": [
                "Grammar",
                "Vocabulary",
                "Sentence usage",
                "Reading comprehension",
                "Inference and language application",
            ],
        },
    },


    "12": {
        "Mathematics": {
            "beginner": 2,
            "intermediate": 1,
            "advanced": 1,
            "topics": [
                "Relations and functions",
                "Algebra",
                "Calculus",
                "Vectors and three-dimensional geometry",
                "Probability and mathematical application",
            ],
        },

        "Physics": {
            "beginner": 2,
            "intermediate": 1,
            "advanced": 1,
            "topics": [
                "Electricity",
                "Magnetism",
                "Optics",
                "Modern physics",
                "Numerical and conceptual applications",
            ],
        },

        "Chemistry": {
            "beginner": 2,
            "intermediate": 1,
            "advanced": 1,
            "topics": [
                "Physical chemistry",
                "Organic chemistry",
                "Inorganic chemistry",
                "Chemical reasoning and applications",
            ],
        },

        "English": {
            "beginner": 1,
            "intermediate": 1,
            "advanced": 1,
            "topics": [
                "Grammar and language usage",
                "Reading comprehension",
                "Inference and interpretation",
            ],
        },
    },
}
ACTIVE_ASSESSMENTS = {}
# GENERATE PROMPT

def create_assessment_prompt(
        standard: str,
        config: dict,
):

    subject_instructions = ""

    for subject, details in config.items():

        topics = ", ".join(
            details["topics"]
        )

        subject_instructions += f"""

{subject}

Number of questions:
- Beginner: {details["beginner"]}
- Intermediate: {details["intermediate"]}
- Advanced: {details["advanced"]}

Concept areas:
{topics}

"""

    return f"""
You are an expert educational assessment designer.

Create an initial diagnostic assessment for an Indian
Class {standard} student.

The purpose of this assessment is to estimate the student's
starting proficiency in each subject as:

- Beginner
- Intermediate
- Advanced


ASSESSMENT STRUCTURE

Generate exactly 15 questions.

{subject_instructions}


IMPORTANT RULES

1. Generate exactly the required number of questions.

2. Questions must be appropriate for Class {standard}.

3. Do not generate questions above the expected Class
   {standard} academic level.

4. Questions should test conceptual understanding,
   reasoning and application.

5. Avoid extremely obscure facts.

6. Every question must have exactly four options.

7. Exactly one option must be correct.

8. Do not repeat the same question or concept unnecessarily.

9. Mathematics calculations must be accurate.

10. Science, Physics and Chemistry facts must be accurate.

11. Difficulty labels must accurately represent:
    beginner, intermediate or advanced.

12. Return ONLY valid JSON.

13. Do not include Markdown formatting.

14. Do not include explanations before or after the JSON.


RETURN EXACTLY THIS FORMAT

{{
    "questions": [
        {{
            "subject": "Mathematics",
            "difficulty": "beginner",
            "question": "Question text",
            "options": [
                "Option A",
                "Option B",
                "Option C",
                "Option D"
            ],
            "correctAnswer": 0
        }}
    ]
}}


correctAnswer must be the zero-based index of the
correct option:

0 = first option
1 = second option
2 = third option
3 = fourth option
"""
# VALIDATE GENERATED ASSESSMENT

def validate_assessment(
        questions: list,
        config: dict,
):

    # Must contain exactly 15 questions
    if len(questions) != 15:
        return False

    # Build expected counts
    expected = {}

    for subject, details in config.items():
        expected[subject] = {
            "beginner": details["beginner"],
            "intermediate":
                details["intermediate"],
            "advanced": details["advanced"],
        }

    # Actual generated counts
    actual = {}

    for subject in expected:
        actual[subject] = {
            "beginner": 0,
            "intermediate": 0,
            "advanced": 0,
        }

    for question in questions:
        subject = question.get("subject")
        difficulty = str(
            question.get(
                "difficulty",
                "",
            )
        ).lower()

        # Validate subject
        if subject not in expected:
            return False

        # Validate difficulty
        if difficulty not in [
            "beginner",
            "intermediate",
            "advanced",
        ]:
            return False

        # Validate question text
        if not question.get("question"):
            return False

        # Validate options
        options = question.get("options")

        if (
                not isinstance(options, list)
                or len(options) != 4
        ):
            return False

        # Validate correct answer
        correct_answer = question.get(
            "correctAnswer"
        )

        if (
                not isinstance(correct_answer, int)
                or correct_answer < 0
                or correct_answer > 3
        ):
            return False
        actual[subject][difficulty] += 1
    # Check exact distribution
    return actual == expected

# GENERATE ASSESSMENT API
@app.post("/generate-assessment")
def generate_assessment(
        data: AssessmentRequest,
):

    # Clean standard value
    standard = (
        data.standard
        .lower()
        .replace("class", "")
        .replace("standard", "")
        .replace("th", "")
        .strip()
    )

    # Only Class 10 and Class 12 supported
    if standard not in ASSESSMENT_CONFIG:

        raise HTTPException(
            status_code=400,
            detail=(
                "Learnova currently supports "
                "only Standard 10 and Standard 12."
            ),
        )

    config = ASSESSMENT_CONFIG[
        standard
    ]

    prompt = create_assessment_prompt(
        standard,
        config,
    )

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
                ),
            )

        raw_response = (
            response.text
            .replace("```json", "")
            .replace("```", "")
            .strip()
        )

        assessment = json.loads(
            raw_response
        )

        questions = assessment.get(
            "questions",
            []
        )

        # Validate Gemini output
        if not validate_assessment(
                questions,
                config,
        ):

            raise HTTPException(
                status_code=500,
                detail=(
                    "Generated assessment did not "
                    "match the required structure."
                ),
            )

        # Randomize question order
        random.shuffle(questions)

        # Add IDs after shuffling
        for index, question in enumerate(questions, start=1):

            question["id"] = index

        # Create unique assessment ID
        assessment_id = str(uuid.uuid4())

        # Store complete assessment including correct answers
        ACTIVE_ASSESSMENTS[assessment_id] = {
        "standard": standard,
        "questions": copy.deepcopy(questions),
        }

        # Create safe questions for Flutter
        safe_questions = []

        for question in questions:
            safe_question = {
                "id": question["id"],
                "subject": question["subject"],
                "difficulty": question["difficulty"],
                "question": question["question"],
                "options": question["options"],
            }
            safe_questions.append(safe_question)

        return {

            "status": "success",
            "assessmentId": assessment_id,
            "standard": standard,
            "totalQuestions": len(safe_questions),
            "questions": safe_questions,
        }

    except json.JSONDecodeError:

        raise HTTPException(
            status_code=500,
            detail=(
                "Gemini returned invalid JSON."
            ),
        )

    except HTTPException:

        raise

    except Exception as e:
        print(
            "Assessment Generation Error:",
            str(e),
        )

        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to generate assessment."
            ),
        )

@app.post("/submit-assessment")
def submit_assessment(
        data: AssessmentSubmission,
        authorization: str = Header(None),
):

    decoded_token = verify_firebase_token(
        authorization
    )

    uid = decoded_token["uid"]

    print(
        "Assessment submitted by user:",
        uid
    )
    # Check whether assessment exists
    if data.assessmentId not in ACTIVE_ASSESSMENTS:
        raise HTTPException(
            status_code=404,
            detail=(
                "Assessment not found or expired."
            ),
        )
    assessment = ACTIVE_ASSESSMENTS[
        data.assessmentId
    ]

    standard = assessment["standard"]
    questions = assessment["questions"]

    # Convert submitted answers into:
    # questionId -> selectedAnswer
    submitted_answers = {
        answer.questionId: answer.selectedAnswer
        for answer in data.answers
    }

    # Require answers for all questions
    if len(submitted_answers) != len(questions):
        raise HTTPException(
            status_code=400,
            detail=(
                "Please answer all assessment questions."
            ),
        )
    subject_results = {}

    # Create subject result structure
    for subject in ASSESSMENT_CONFIG[standard]:

        subject_results[subject] = {
            "totalQuestions": 0,
            "correctAnswers": 0,

            "beginner": {
                "total": 0,
                "correct": 0,
            },

            "intermediate": {
                "total": 0,
                "correct": 0,
            },

            "advanced": {
                "total": 0,
                "correct": 0,
            },
        }

    # Check every answer
    for question in questions:

        question_id = question["id"]

        # Validate that this question was answered
        if question_id not in submitted_answers:
            raise HTTPException(
                status_code=400,
                detail=(
                    f"Answer missing for question "
                    f"{question_id}."
                ),
            )
        selected_answer = submitted_answers[
            question_id
        ]
        # Validate answer index
        if selected_answer not in [0, 1, 2, 3]:
            raise HTTPException(
                status_code=400,
                detail=(
                    f"Invalid answer for question "
                    f"{question_id}."
                ),
            )


        subject = question["subject"]
        difficulty = (
            question["difficulty"]
            .lower()
        )
        correct_answer = question[
            "correctAnswer"
        ]
        result = subject_results[
            subject
        ]
        result["totalQuestions"] += 1
        result[difficulty]["total"] += 1

        if selected_answer == correct_answer:
            result["correctAnswers"] += 1
            result[difficulty]["correct"] += 1

    # CLASSIFY PROFICIENCY


    for subject, result in subject_results.items():

        total_correct = result[
            "correctAnswers"
        ]
        beginner_correct = result[
            "beginner"
        ]["correct"]
        intermediate_correct = result[
            "intermediate"
        ]["correct"]

        advanced_correct = result[
            "advanced"
        ]["correct"]


        # STANDARD 10

        if standard == "10":

            if (
                    advanced_correct >= 1
                    and intermediate_correct >= 1
                    and total_correct >= 3
            ):
                proficiency = "advanced"

            elif (
                    intermediate_correct >= 1
                    and total_correct >= 2
            ):
                proficiency = "intermediate"

            else:
                proficiency = "beginner"

        # STANDARD 12

        else:

            # English has only 3 questions
            if subject == "English":

                if (
                        advanced_correct >= 1
                        and intermediate_correct >= 1
                ):
                    proficiency = "advanced"

                elif (
                        intermediate_correct >= 1
                        or total_correct >= 2
                ):
                    proficiency = "intermediate"

                else:
                    proficiency = "beginner"


            # Maths, Physics and Chemistry
            else:

                if (
                        advanced_correct >= 1
                        and intermediate_correct >= 1
                        and total_correct >= 3
                ):
                    proficiency = "advanced"

                elif (
                        intermediate_correct >= 1
                        and total_correct >= 2
                ):
                    proficiency = "intermediate"

                else:
                    proficiency = "beginner"

        result["proficiency"] = proficiency

        result["percentage"] = round(
            (
                    result["correctAnswers"]
                    / result["totalQuestions"]
            ) * 100,
            2,
            )

    # SAVE ASSESSMENT RESULT TO FIRESTORE


    try:
        # Create subject -> proficiency map
        subject_levels = {
            subject: result["proficiency"]
            for subject, result in subject_results.items()
        }

        # Reference to logged-in user's Firestore document
        user_ref = (
            db.collection("users")
            .document(uid)
        )

        # Update user document
        user_ref.set(
            {
                "assessmentCompleted": True,
                "subjectLevels": subject_levels,
            },
            merge=True,
        )

        # Save detailed assessment result separately
        assessment_result_ref = (
            db.collection("assessmentResults")
            .document(data.assessmentId)
        )

        assessment_result_ref.set(
            {
                "userId": uid,
                "standard": standard,
                "subjectResults": subject_results,
                "completedAt": firestore.SERVER_TIMESTAMP,
            }
        )

    except Exception as e:
        print(
            "Firestore Save Error:",
            str(e),
        )

        raise HTTPException(
            status_code=500,
            detail=(
                "Assessment was evaluated, "
                "but the result could not be saved."
            ),
        )

# Firestore has saved successfully
    del ACTIVE_ASSESSMENTS[
        data.assessmentId
    ]

    return {
        "status": "success",
        "message": "Assessment completed successfully.",
        "standard": standard,
        "subjectResults": subject_results,
    }