import os
import json
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from google import genai

import firebase_admin
from firebase_admin import credentials
from firebase_admin import auth
from firebase_admin import firestore

from explanation_engine import register_explanation_routes
from assessment_engine import register_assessment_routes
from assistant_engine import (
    register_assistant_routes,
)
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

class ExplanationRequest(BaseModel):
    standard: str
    subject: str
    chapter: str
    topic: str
    content: str






register_explanation_routes(
    app,
    db,
    client,
    ExplanationRequest,
)

register_assessment_routes(
    app,
    db,
    client,
    verify_firebase_token,
    AssessmentRequest,
    AssessmentSubmission,
)

register_assistant_routes(
    app,
    db,
    client,
)