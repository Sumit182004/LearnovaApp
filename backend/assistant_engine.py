from fastapi import HTTPException
from pydantic import BaseModel

client = None
db = None

class ChatRequest(BaseModel):
    message: str
    standard: str
    language: str = "english"
    chat_history: list = []


def build_chat_prompt(
    standard,
    language,
):
    language_instruction = (
        "Reply only in Hindi."
        if language.lower() == "hindi"
        else "Reply only in English."
    )

    return f"""
    You are Learnova AI Assistant.

    {language_instruction}

    Your purpose is to help students understand their {standard} syllabus clearly and accurately.

    RULES

    1. Answer ONLY from the NCERT syllabus of {standard}.
    2. Start directly with the explanation.
    3. Speak naturally and conversationally.
    4. Do not introduce yourself.
    5. Do not say:
    - According to your textbook
    - According to your syllabus
    - As per NCERT
    - Your chapter says
    - Your book says
    - I am your teacher
    - As a teacher
    6. Never mention where the information comes from.
    7. Explain concepts step by step.
    8. Use simple language suitable for {standard} students.
    9. Keep paragraphs short and easy to read.
    10. Give examples only when they help understanding.
    11. If an equation is needed, write it in plain text.
    12. Never use LaTeX.
    13. Never use $$...$$ notation.
    14. Never invent facts.
    15. If the student asks a follow-up question, continue naturally without repeating the whole explanation.
    16. If the question is outside the {standard} syllabus, politely reply:
    "I can only help with your {standard} syllabus."
    17. Never answer harmful or inappropriate questions.
    18. Keep responses concise, clear, and student-friendly.
    """

def register_assistant_routes(
    app,
    firestore_db,
    gemini_client,
):
    global db
    global client

    db = firestore_db
    client = gemini_client

    @app.post("/chat")
    def chat(request: ChatRequest):

        try:

            system_prompt = build_chat_prompt(
                request.standard,
                request.language,
            )

            contents = []

            contents.append({
                "role": "user",
                "parts": [
                    {
                        "text": system_prompt,
                    }
                ],
            })

            for msg in request.chat_history[-10:]:

                role = (
                    "model"
                    if msg.get("role") == "assistant"
                    else "user"
                )

                contents.append({
                    "role": role,
                    "parts": [
                        {
                            "text": msg.get(
                                "content",
                                "",
                            )
                        }
                    ],
                })

            contents.append({
                "role": "user",
                "parts": [
                    {
                        "text": request.message,
                    }
                ],
            })

            response = client.models.generate_content(
                model="gemini-3.5-flash",
                contents=contents,
            )

            if not response.text:
                raise HTTPException(
                    status_code=500,
                    detail="Gemini returned an empty response.",
                )

            return {
                "reply": response.text.strip(),
            }

        except Exception as e:

            print(e)

            raise HTTPException(
                status_code=500,
                detail=str(e),
            )