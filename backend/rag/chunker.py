import json
from pathlib import Path


def clean_text(text):
    if text is None:
        return ""

    if isinstance(text, str):
        return text.strip()

    if isinstance(text, list):
        return "\n".join(
            clean_text(item)
            for item in text
            if clean_text(item)
        )

    if isinstance(text, dict):
        return "\n".join(
            f"{key}: {clean_text(value)}"
            for key, value in text.items()
            if clean_text(value)
        )

    return str(text)


def block_to_text(block):
    """
    Convert a JSON block into searchable text.
    """

    parts = []

    block_type = block.get("type", "")

    if block_type:
        parts.append(f"Type: {block_type}")

    for key, value in block.items():

        if key in {"type", "id"}:
            continue

        text = clean_text(value)

        if text:
            parts.append(text)

    return "\n".join(parts).strip()


def extract_blocks(data):
    """
    Extract blocks from different Learnova JSON structures.
    """

    chunks = []

    class_name = data.get("class", "")
    subject = data.get("subject", "")
    chapter = data.get("chapter", "")
    chapter_number = data.get("chapter_number", "")

    # --------------------------------------------------
    # Structure 1:
    # sections -> blocks
    # --------------------------------------------------

    for section in data.get("sections", []):

        section_title = section.get(
            "title",
            section.get("name", "")
        )

        for block in section.get("blocks", []):

            text = block_to_text(block)

            if not text:
                continue

            chunks.append({
                "class": class_name,
                "subject": subject,
                "chapter_number": chapter_number,
                "chapter": chapter,
                "section": section_title,
                "content_type": block.get("type", "unknown"),
                "text": text,
            })

    # --------------------------------------------------
    # Structure 2:
    # topics -> blocks
    # --------------------------------------------------

    for topic in data.get("topics", []):

        topic_title = topic.get(
            "title",
            topic.get("name", "")
        )

        for block in topic.get("blocks", []):

            text = block_to_text(block)

            if not text:
                continue

            chunks.append({
                "class": class_name,
                "subject": subject,
                "chapter_number": chapter_number,
                "chapter": chapter,
                "section": topic_title,
                "content_type": block.get("type", "unknown"),
                "text": text,
            })

    return chunks


def load_json_file(file_path):
    """
    Load one Learnova JSON file and convert it into chunks.
    """

    path = Path(file_path)

    with open(path, "r", encoding="utf-8") as file:
        data = json.load(file)

    return extract_blocks(data)