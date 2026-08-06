import json
from google import genai
from fastapi import HTTPException
from firebase_admin import firestore
from typing import List, Dict


db = None
client = None

BLOCK_PRIORITY = [
    "formula",
    "proof",
    "activity",
    "example",
    "exercise",
    "theory",
    "summary",
]
def build_cache_key(
        standard: str,
        subject: str,
        chapter: str,
        topic: str,
) -> str:

    return "_".join(
        [
            standard.lower(),
            subject.lower(),
            chapter.lower(),
            topic.lower(),
        ]
    ).replace(" ", "_")

# FIRESTORE CACHE
def get_cached_explanation(cache_key: str):
    doc = db.collection("explanations").document(cache_key).get()
    if doc.exists:
        return doc.to_dict()
    return None


def save_explanation(
    cache_key: str,
    explanation: dict,
):
    firestore_doc = explanation.copy()
    firestore_doc["createdAt"] = firestore.SERVER_TIMESTAMP
    db.collection("explanations").document(
        cache_key
    ).set(firestore_doc)

def normalize_subject(subject: str) -> str:
    """
    Convert subject name into standard format.
    """

    if not subject:
        return "general"

    s = subject.lower().strip()

    mapping = {
        "math": "maths",
        "mathematics": "maths",
        "maths": "maths",

        "phy": "physics",
        "physics": "physics",

        "chem": "chemistry",
        "chemistry": "chemistry",

        "bio": "biology",
        "biology": "biology",
    }

    return mapping.get(s, s)


def has_image(blocks: List[Dict]) -> bool:
    """
    Detect image block.
    """

    return any(
        block.get("type") == "image"
        for block in blocks
    )


def extract_block_types(blocks: List[Dict]) -> List[str]:

    block_types = []

    for block in blocks:

        t = block.get("type", "").lower()

        if t and t not in block_types:
            block_types.append(t)

    return block_types
def detect_topic_type(blocks: List[Dict]) -> str:
    """
    Decide what kind of topic this is.

    Formula
    Proof
    Activity
    Exercise
    Theory
    """
    block_types = extract_block_types(blocks)
    for block in BLOCK_PRIORITY:
        if block in block_types:
            return block
    return "theory"
def extract_formula(blocks: List[Dict]) -> str:
    """
    If formula exists,
    return it.
    """
    for block in blocks:
        if block.get("type") == "formula":
            return block.get("text", "")
    return ""

def extract_learning_points(blocks: List[Dict]) -> List[str]:
    """
    Collect all theory text.
    Used while building prompt.
    """
    points = []

    for block in blocks:
        if block.get("type") in [
            "theory",
            "definition",
            "formula",
            "proof",
            "activity",
            "example",
        ]:

            txt = block.get("text", "").strip()
            if txt:
                points.append(txt)

    return points

# PROMPT ENGINE V2
def build_explanation_prompt(standard: str,subject: str,chapter: str,topic: str,blocks: list,) -> str:
    subject = normalize_subject(subject)
    topic_type = detect_topic_type(blocks)
    has_diagram = has_image(blocks)
    formula = extract_formula(blocks)
    lesson = "\n\n".join(
        extract_learning_points(blocks)
    )

    common_rules = f"""
    You are Learnova AI Teacher.
    Your responsibility is to teach exactly like an excellent school teacher.
    STRICT RULES
    1. Explain ONLY using the supplied textbook.
    2. Never invent facts.
    3. Never introduce topics outside syllabus.
    4. Explain exactly like a school teacher.
    5. Start simple.
    6. Build concepts gradually.
    7. If definition exists,
    explain definition first.
    8. If theorem exists,
    explain theorem before proof.
    9. If proof exists,
    explain reasoning of every step.
    10. If formula exists,
    explain every variable.
    11. If activity exists,
    explain observation and conclusion.
    12. If image exists,
    refer student to observe image.
    13. Never say
    "As an AI"
    14. Never say
    "Based on provided content"
    15. Speak directly to student.
    16. Use simple English.
    17. Do not use markdown.
    18. Return ONLY JSON.
    19. Never wrap JSON.
    20. Keep explanation classroom friendly.
    21. If mathematical symbols exist,
    preserve them correctly.
    22. If scientific terminology appears,
    explain it before using it.
    23. Never skip intermediate reasoning.
    24. Never answer questions outside chapter.
    """

    if subject == "maths":
        subject_prompt = f"""
        You are an expert Mathematics teacher.
        Whenever teaching Maths:
        Explain intuition first.
        Then explain concept.
        Then explain formula.
        Then solve ONE example.
        Then give solving strategy.
        Then give common mistakes.
        Never jump directly into calculations.
        """

    elif subject == "physics":
        subject_prompt = f"""
        You are an expert Physics teacher.
        Always explain
        Concept
        ↓
        Reason
        ↓
        Real Life
        ↓
        Formula
        ↓
        Example
        ↓
        Applications

        Never memorization.
        """

    elif subject == "chemistry":
        subject_prompt = f"""
        You are an expert Chemistry teacher.
        Always explain
        Concept
        ↓
        Reaction
        ↓
        Observation
        ↓
        Example
        ↓
        Memory Trick
        ↓
        Applications
        """

    elif subject == "biology":
        subject_prompt = f"""
        You are an expert Biology teacher.
        Always explain
        Definition
        ↓
        Structure
        ↓
        Function
        ↓
        Example
        ↓
        Real Life Importance
        """
    else:
        subject_prompt = ""

    if topic_type == "formula":
        style = """
        Explain every symbol.
        Why formula works.
        Where formula is used.
        One solved example.
        Common mistakes.
        """
    elif topic_type == "proof":
        style = """
        Explain proof step-by-step.
        Never skip reasoning.
        Every step should have explanation.
        End with final conclusion.
        """
    elif topic_type == "activity":
        style = """
        Explain
        Aim
        Procedure
        Observation
        Conclusion
        Learning Outcome
        """

    elif topic_type == "exercise":
        style = """
        Do NOT solve all questions.
        Teach approach.
        Solve one sample.
        Let student solve remaining.
            """

    else:
        style = """
        Explain concept naturally.
        Give one example.
        End with summary.
        """
    image_instruction = ""
    if has_diagram:
        image_instruction = """
        This topic contains image(s).
        Whenever explanation references
        diagram,
        tell student
        "Observe the diagram carefully."
        Explain what should be observed.
        """
    return f"""
    {common_rules}
    {subject_prompt}
    {style}
    {image_instruction}
    CLASS
    {standard}
    SUBJECT
    {subject}
    CHAPTER
    {chapter}
    TOPIC
    {topic}
    TEXTBOOK CONTENT
    {lesson}
    FORMULA
    {formula}
    Return JSON only.
    {{
    "introduction": "",
    "concept_explanation": "",
    "key_points": [],
    "worked_example": "",
    "common_mistakes": [],
    "summary": "",
    "practice_questions": [],
    "related_concepts": [],
    "difficulty": "",
    "reading_time": 0,
    "image_required": false,
    "image_prompt": ""
    }}
    """





def clean_gemini_response(text: str) -> str:
    """
    Remove markdown wrappers if Gemini returns them.
    """
    text = text.strip()
    if text.startswith("```json"):
        text = text.replace("```json", "", 1)
    if text.startswith("```"):
        text = text.replace("```", "", 1)
    if text.endswith("```"):
        text = text[:-3]
    return text.strip()

def validate_explanation(data: dict) -> dict:
    """
    Ensure required fields exist.
    """
    defaults = {
    "introduction": "",
    "concept_explanation": "",
    "key_points": [],
    "worked_example": "",
    "common_mistakes": [],
    "summary": "",
    "practice_questions": [],
    "related_concepts": [],
    "difficulty": "",
    "reading_time": 0,
    "image_required": False,
    "image_prompt": "",
    }
    for key, value in defaults.items():
        if key not in data:
            data[key] = value
    return data

def generate_explanation(
    standard,
    subject,
    chapter,
    topic,
    blocks,
):
    """
    Generate explanation using Gemini.
    """
    prompt = build_explanation_prompt(
        standard,
        subject,
        chapter,
        topic,
        blocks,
    )
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
    )
    if not response.text:
        raise HTTPException(
            status_code=500,
            detail="Gemini returned an empty response.",
    )
    text = clean_gemini_response(
        response.text
    )
    try:
        result = json.loads(text)
    except Exception:
        raise HTTPException(

            status_code=500,
            detail="Gemini returned invalid JSON."
        )

    result = validate_explanation(result)
    return result


# GENERATE EXPLANATION API

def register_explanation_routes(
    app,
    firestore_db,
    gemini_client,
    ExplanationRequest,
):
    global db
    global client

    db = firestore_db
    client = gemini_client
    @app.post("/generate-explanation")
    def generate_explanation_api(request: ExplanationRequest):

        try:
            cache_key = build_cache_key(
                request.standard,
                request.subject,
                request.chapter,
                request.topic,
            )

            # CACHE CHECK

            cached = get_cached_explanation(
                cache_key
            )
            if cached:
                cached.pop("createdAt", None)
                return {
                    "status": "cached",
                    "data": cached,
                }

            # GENERATE NEW
            section = json.loads(request.content)

            blocks = section.get("blocks", [])

            explanation = generate_explanation(
                standard=request.standard,
                subject=request.subject,
                chapter=request.chapter,
                topic=request.topic,
                blocks=blocks,
            )
            save_explanation(
                cache_key,
                explanation,
            )
            return {
                "status": "generated",
                "data": explanation,
            }
        except HTTPException:
            raise
        except Exception as e:
            print(e)
            raise HTTPException(
                status_code=500,
                detail=str(e),
            )

