def build_rag_context(results):

    if not results:
        return ""

    context_parts = []

    for index, result in enumerate(results, start=1):

        payload = result.payload or {}

        chapter = payload.get("chapter", "")
        section = payload.get("section", "")
        content_type = payload.get("content_type", "")
        text = payload.get("text", "")

        if not text:
            continue

        context_parts.append(
            f"""
Knowledge Chunk {index}

Chapter: {chapter}
Section: {section}
Content Type: {content_type}

{text}
""".strip()
        )

    return "\n\n".join(context_parts)