from fastapi import HTTPException
from pydantic import BaseModel

from rag.retriever import retrieve_chunks
from rag.context_builder import build_rag_context


client = None
db = None


class ChatRequest(BaseModel):
    message: str
    standard: str
    language: str = "english"
    chat_history: list = []


def get_language_instruction(language):

    language = language.lower().strip()

    if language == "hindi":

        return """
        Reply only in Hindi.
        Use simple Hindi suitable for school students.
        Keep important scientific and technical terms in English
        when that makes them easier to understand.
        """

    elif language == "hinglish":

        return """
        Reply in natural Hinglish.
        Use a natural combination of Hindi and English,
        like students commonly use while speaking.
        Do not reply in pure Hindi.
        Keep scientific and technical terms in English.
        """

    elif language == "marathi":

        return """
        Reply only in Marathi.
        Use simple Marathi suitable for school students.
        Keep important scientific and technical terms in English
        when that makes them easier to understand.
        """

    else:

        return """
        Reply only in English.
        Use simple English suitable for school students.
        """


def build_chat_prompt(
    standard,
    language,
    rag_context,
):

    language_instruction = get_language_instruction(language)

    if rag_context:

        knowledge_instruction = f"""
        Use the retrieved Learnova knowledge below
        to answer the student's question.

        Base the factual content of your answer on this
        retrieved knowledge.

        Do not add unrelated outside information.

        Do not mention:
        - RAG
        - Qdrant
        - embeddings
        - vector database
        - retrieved chunks
        - knowledge base
        - retrieval

        RETRIEVED KNOWLEDGE:

        {rag_context}
        """

    else:

        knowledge_instruction = """
        No sufficiently relevant Learnova knowledge was found
        for this question.

        Do NOT answer the question using general knowledge.

        If the question requires syllabus knowledge, reply:

        "I can only help with your Class 10 syllabus."
        """

    return f"""
    You are Learnova AI Assistant.

    {language_instruction}

    Your purpose is to help students understand their
    {standard} syllabus clearly and accurately.

    {knowledge_instruction}

    RULES

    1. Answer only using relevant retrieved knowledge when it is available.
    2. Never invent textbook-specific facts.
    3. Start directly with the explanation.
    4. Speak naturally and conversationally.
    5. Do not introduce yourself.
    6. Do not say:
       - According to your textbook
       - According to your syllabus
       - As per NCERT
       - Your chapter says
       - Your book says
       - I am your teacher
       - As a teacher
    7. Never mention where the information comes from.
    8. Explain concepts step by step.
    9. Use simple language suitable for {standard} students.
    10. Keep paragraphs short and easy to read.
    11. Give examples only when they help understanding.
    12. If an equation is needed, write it in plain text.
    13. Never use LaTeX.
    14. Never use $$...$$ notation.
    15. If the student asks a follow-up question, continue naturally.
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
            # 1. Retrieve textbook knowledge

            retrieved_chunks = retrieve_chunks(
                request.message,
                top_k=5,
            )

            # 2. Build textbook context

            rag_context = build_rag_context(
                retrieved_chunks
            )
            # 3. Build prompt
        
            system_prompt = build_chat_prompt(
                request.standard,
                request.language,
                rag_context,
            )

            # 4. Conversation history

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

            # 5. Current question

            contents.append({
                "role": "user",
                "parts": [
                    {
                        "text": request.message,
                    }
                ],
            })

            # 6. Gemini

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

            print("Assistant Error:", e)

            raise HTTPException(
                status_code=500,
                detail=str(e),
            )