
import json
from google import genai
from fastapi import HTTPException
from firebase_admin import firestore
from typing import List, Dict

db = None
client = None

# FIRESTORE CACHE

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

# SUBJECT NORMALIZATION

def normalize_subject(subject: str) -> str:

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

# BLOCK HELPERS

def has_image(blocks: List[Dict]) -> bool:

    return any(
        block.get("type") == "image"
        for block in blocks
        if isinstance(block, dict)
    )

def extract_block_types(blocks: List[Dict]) -> List[str]:

    block_types = []

    for block in blocks:

        if not isinstance(block, dict):
            continue

        t = block.get("type", "").lower()

        if t and t not in block_types:
            block_types.append(t)

    return block_types

def extract_formula(blocks: List[Dict]) -> str:

    for block in blocks:

        if not isinstance(block, dict):
            continue

        if block.get("type") == "formula":

            return block.get("text", "")

    return ""

def extract_learning_points(blocks: List[Dict]) -> List[str]:

    points = []

    allowed_types = [
        "theory",
        "definition",
        "formula",
        "proof",
        "activity",
        "example",
        "reaction",
        "observation",
        "process",
        "structure",
    ]

    for block in blocks:

        if not isinstance(block, dict):
            continue

        if block.get("type") in allowed_types:

            txt = block.get("text", "").strip()

            if txt:
                points.append(txt)

    return points

# TOPIC TYPE

def detect_topic_type(blocks: List[Dict]) -> str:

    block_types = extract_block_types(blocks)

    priority = [
        "activity",
        "reaction",
        "formula",
        "proof",
        "process",
        "structure",
        "example",
        "exercise",
        "theory",
    ]

    for block in priority:

        if block in block_types:
            return block

    return "theory"

# PROMPT ENGINE

def build_explanation_prompt(
        standard: str,
        subject: str,
        chapter: str,
        topic: str,
        blocks: list,
) -> str:
    subject = normalize_subject(subject)
    topic_type = detect_topic_type(blocks)
    has_diagram = has_image(blocks)
    formula = extract_formula(blocks)
    lesson = "\n\n".join(extract_learning_points(blocks))

    common_rules = """
You are Learnova AI Teacher.
Teach exactly like an experienced Class 10 school teacher.
The supplied textbook content is your ONLY source.
Do not add outside concepts, facts, formulas, reactions, examples, applications, or information.
Do not invent examples.
If an example is present, explain that example.
If an example is not present, leave the example field empty.
Keep the explanation proportional to the supplied content.
Use simple English.
Return ONLY valid JSON.
"""

    if subject == "maths":
        subject_prompt = """
Teach Mathematics clearly.
For normal concepts explain the concept, formula if present, textbook example if present, and important points.
For an exercise, do NOT give an introduction or generic concept explanation. Directly solve the supplied question step-by-step.
"""
    elif subject == "physics":
        subject_prompt = """
Teach Physics clearly.
Explain the concept, reason, formula, observation, or application only when the supplied content contains them.
For an exercise, do NOT give an introduction or generic concept explanation. Directly solve the supplied question step-by-step.
"""
    elif subject == "chemistry":
        subject_prompt = """
Teach Chemistry clearly.
Explain the concept, reaction, observation, or example only when the supplied content contains them.
For an exercise, do NOT give an introduction or generic concept explanation. Directly solve the supplied question step-by-step.
"""
    elif subject == "biology":
        subject_prompt = """
Teach Biology clearly.
Explain the definition, structure, process, function, or example only when the supplied content contains them.
For an exercise, do NOT give an introduction or generic concept explanation. Directly solve the supplied question step-by-step.
"""
    else:
        subject_prompt = "Explain the supplied textbook content naturally."

    if topic_type == "introduction":
        style = """
This is an Introduction block.
ONLY provide a short introduction based on the supplied content.
Do not provide concept explanation, examples, key points, practice questions, or an additional summary.
All other explanation fields must be empty.
"""
    elif topic_type == "exercise":
        style = """
This is an Exercise block.
Do NOT write an introduction.
Do NOT repeat the topic explanation.
Do NOT give generic key points.
Directly solve the supplied exercise/question step-by-step using only the supplied content.
Show the required working and final answer.
Do not create a different question.
Do not solve additional questions.
The solution should be the main content of the response.
"""
    elif topic_type == "formula":
        style = """
This is a Formula block.
Explain the formula, meaning of its symbols, and how it is used only when supported by the supplied content.
Use a textbook example only if present.
"""
    elif topic_type == "reaction":
        style = """
This is a Reaction block.
Explain the supplied reaction, reactants, products, observation, and reason only when present in the supplied content.
Do not invent chemical equations or observations.
"""
    elif topic_type == "activity":
        style = """
This is an Activity or Experiment block.
Explain the aim, materials, procedure, observation, conclusion, and learning outcome only when supplied.
"""
    elif topic_type == "proof":
        style = """
This is a Proof block.
Explain the statement and solve the proof step-by-step with the reason for each important step.
"""
    elif topic_type == "process":
        style = """
This is a Process block.
Explain the process step-by-step using only the supplied content.
"""
    elif topic_type == "structure":
        style = """
This is a Structure block.
Explain the main parts and their functions only when supplied.
"""
    else:
        style = """
Explain the topic naturally and step-by-step.
Do not force an introduction, example, application, formula, reaction, or summary when it is not appropriate.
"""

    image_instruction = ""
    if has_diagram:
        image_instruction = """
This topic contains image(s).
If a diagram is referenced, tell the student what to observe.
Do not invent labels or information.
"""

    base = f"""
{common_rules}
{subject_prompt}
{style}
{image_instruction}
CLASS:
{standard}
SUBJECT:
{subject}
CHAPTER:
{chapter}
TOPIC:
{topic}
TEXTBOOK CONTENT:
{lesson}
FORMULA:
{formula}
"""

    if topic_type == "introduction":
        return base + """
Generate ONLY this JSON:
{
    "introduction": "",
    "concept_explanation": "",
    "key_points": [],
    "worked_example": "",
    "summary": "",
    "practice_questions": [],
    "difficulty": "",
    "reading_time": 0,
    "image_required": false,
    "image_prompt": ""
}
Rules:
- Put only the short introduction in "introduction".
- Keep all other learning-content fields empty.
- Do not repeat the introduction in concept_explanation or summary.
"""

    if topic_type == "exercise":
        if subject == "maths":
            return base + """
Generate ONLY this JSON:
{
    "introduction": "",
    "concept_explanation": "",
    "key_points": [],
    "worked_example": "",
    "summary": "",
    "practice_questions": [],
    "difficulty": "",
    "reading_time": 0,
    "image_required": false,
    "image_prompt": ""
}
Rules:
- Put the complete step-by-step solution in "worked_example".
- Do not put the solution in introduction or concept_explanation.
- Do not create another example.
- Do not create practice questions.
- summary must be empty.
"""
        elif subject == "physics":
            return base + """
Generate ONLY this JSON:
{
    "introduction": "",
    "concept_explanation": "",
    "formula": "",
    "key_points": [],
    "observation": "",
    "example_or_application": "",
    "summary": "",
    "practice_questions": [],
    "difficulty": "",
    "reading_time": 0,
    "image_required": false,
    "image_prompt": ""
}
Rules:
- Put the complete step-by-step solution in "example_or_application".
- Do not put the solution in introduction or concept_explanation.
- Do not create another question.
- summary must be empty.
"""
        elif subject == "chemistry":
            return base + """
Generate ONLY this JSON:
{
    "introduction": "",
    "concept_explanation": "",
    "reactions": [],
    "observations": [],
    "key_points": [],
    "example": "",
    "summary": "",
    "practice_questions": [],
    "difficulty": "",
    "reading_time": 0,
    "image_required": false,
    "image_prompt": ""
}
Rules:
- Put the complete step-by-step solution in "example".
- Do not put the solution in introduction or concept_explanation.
- Do not create another question.
- summary must be empty.
"""
        elif subject == "biology":
            return base + """
Generate ONLY this JSON:
{
    "introduction": "",
    "concept_explanation": "",
    "structure_or_process": "",
    "functions_or_explanation": "",
    "key_points": [],
    "example": "",
    "summary": "",
    "practice_questions": [],
    "difficulty": "",
    "reading_time": 0,
    "image_required": false,
    "image_prompt": ""
}
Rules:
- Put the complete step-by-step solution in "example".
- Do not put the solution in introduction or concept_explanation.
- Do not create another question.
- summary must be empty.
"""
        else:
            return base + """
Generate ONLY valid JSON.
Put the direct step-by-step solution in the most appropriate existing answer field.
Keep introduction, generic explanation, and summary empty.
"""

    if subject == "maths":
        return base + """
Generate ONLY this JSON:
{
    "introduction": "",
    "concept_explanation": "",
    "key_points": [],
    "worked_example": "",
    "summary": "",
    "practice_questions": [],
    "difficulty": "",
    "reading_time": 0,
    "image_required": false,
    "image_prompt": ""
}
Rules:
- worked_example contains a textbook example only if present.
- If no textbook example exists, return "".
- Do not invent an example.
- summary must summarize only the supplied content.
"""
    elif subject == "physics":
        return base + """
Generate ONLY this JSON:
{
    "introduction": "",
    "concept_explanation": "",
    "formula": "",
    "key_points": [],
    "observation": "",
    "example_or_application": "",
    "summary": "",
    "practice_questions": [],
    "difficulty": "",
    "reading_time": 0,
    "image_required": false,
    "image_prompt": ""
}
Rules:
- formula must be empty if no formula is supplied.
- observation must be empty if no observation is supplied.
- example_or_application must be empty if neither is supplied.
- summary must summarize only the supplied content.
"""
    elif subject == "chemistry":
        return base + """
Generate ONLY this JSON:
{
    "introduction": "",
    "concept_explanation": "",
    "reactions": [],
    "observations": [],
    "key_points": [],
    "example": "",
    "summary": "",
    "practice_questions": [],
    "difficulty": "",
    "reading_time": 0,
    "image_required": false,
    "image_prompt": ""
}
Rules:
- reactions and observations must contain only supplied information.
- example must be empty if no textbook example exists.
- summary must summarize only the supplied content.
"""
    elif subject == "biology":
        return base + """
Generate ONLY this JSON:
{
    "introduction": "",
    "concept_explanation": "",
    "structure_or_process": "",
    "functions_or_explanation": "",
    "key_points": [],
    "example": "",
    "summary": "",
    "practice_questions": [],
    "difficulty": "",
    "reading_time": 0,
    "image_required": false,
    "image_prompt": ""
}
Rules:
- structure_or_process and functions_or_explanation must contain only supplied information.
- example must be empty if no textbook example exists.
- summary must summarize only the supplied content.
"""
    else:
        return base + """
Generate ONLY valid JSON.
Do not force fields that are not relevant to the supplied content.
"""

# GEMINI RESPONSE CLEANING

def clean_gemini_response(text: str) -> str:

    text = text.strip()

    if text.startswith("```json"):
        text = text.replace("```json", "", 1)

    if text.startswith("```"):
        text = text.replace("```", "", 1)

    if text.endswith("```"):
        text = text[:-3]

    return text.strip()

# VALIDATION

def validate_explanation(data: dict) -> dict:

    # Do NOT add a common fixed schema here.
    # The Gemini response is allowed to be subject-specific.

    if not isinstance(data, dict):
        raise HTTPException(
            status_code=500,
            detail="Gemini returned an invalid explanation structure."
        )

    return data

# GEMINI GENERATION

def generate_explanation(
        standard,
        subject,
        chapter,
        topic,
        blocks,
):

    prompt = build_explanation_prompt(
        standard,
        subject,
        chapter,
        topic,
        blocks,
    )

    response = client.models.generate_content(
        model="gemini-3.5-flash",
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
    def generate_explanation_api(
            request: ExplanationRequest
    ):

        try:

            # CACHE KEY

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

            # READ CONTENT

            section = json.loads(
                request.content
            )

            blocks = section.get(
                "blocks",
                []
            )

            # GENERATE

            explanation = generate_explanation(
                standard=request.standard,
                subject=request.subject,
                chapter=request.chapter,
                topic=request.topic,
                blocks=blocks,
            )

            # SAVE CACHE

            save_explanation(
                cache_key,
                explanation,
            )

            # RESPONSE

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

