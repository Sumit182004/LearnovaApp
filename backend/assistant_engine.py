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

    Rules:
    1. Answer ONLY from the NCERT syllabus of {standard}.
    2. Teach exactly like a school teacher.
    3. Keep explanations simple.
    4. Give examples whenever useful.
    5. Never invent facts.
    6. If the question is outside the syllabus, politely say:
    "I can only help with your {standard} syllabus."
    7. Never answer harmful or inappropriate questions.
    8. Keep responses concise and student-friendly.
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