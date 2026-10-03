from rag.embeddings import embed_text
from rag.qdrant_store import client, COLLECTION_NAME


MIN_SCORE = 0.70
MAX_SCORE_GAP = 0.12


def build_search_query(
    question: str,
    chat_history: list,
) -> str:
    """
    Build a search query using the current question
    and recent conversation context.

    This helps with follow-up questions such as:
    "Can you explain an example on this?"
    """

    question = question.strip()

    if not chat_history:
        return question

    recent_messages = chat_history[-6:]

    conversation_parts = []

    for message in recent_messages:

        role = message.get("role", "")
        content = message.get("content", "").strip()

        if not content:
            continue

        if role == "assistant":
            conversation_parts.append(
                f"Assistant: {content}"
            )
        else:
            conversation_parts.append(
                f"Student: {content}"
            )

    if not conversation_parts:
        return question

    conversation = "\n".join(conversation_parts)

    return f"""
Previous conversation:

{conversation}

Current student question:

{question}

Use the previous conversation to understand
what the current question refers to.
""".strip()


def retrieve_chunks(
    question: str,
    chat_history: list | None = None,
    top_k: int = 5,
):

    if chat_history is None:
        chat_history = []

    question = question.strip()

    if not question:
        return []

    # Build contextual search query

    search_query = build_search_query(
        question,
        chat_history,
    )

    print()
    print("RAG SEARCH QUERY:")
    print(search_query)

    # Create embedding

    query_vector = embed_text(search_query)

    # Search Qdrant

    response = client.query_points(
        collection_name=COLLECTION_NAME,
        query=query_vector,
        limit=top_k,
        with_payload=True,
    )

    results = response.points

    if not results:
        print("No RAG results found.")
        return []
 
    # Best similarity score

    best_score = results[0].score

    print()
    print("Best RAG score:", best_score)

    # Relevance check


    if best_score < MIN_SCORE:

        print(
            "No sufficiently relevant textbook "
            "content found."
        )

        return []

    # Keep results close to best result

    filtered_results = []

    minimum_allowed_score = (
        best_score - MAX_SCORE_GAP
    )

    for result in results:

        if result.score >= minimum_allowed_score:
            filtered_results.append(result)

    print(
        "Relevant chunks:",
        len(filtered_results)
    )

    return filtered_results