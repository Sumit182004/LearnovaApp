from rag.embeddings import embed_text
from rag.qdrant_store import client, COLLECTION_NAME


MIN_SCORE = 0.70
MAX_SCORE_GAP = 0.12


def retrieve_chunks(
    question: str,
    top_k: int = 5,
):

    question = question.strip()

    if not question:
        return []

    query_vector = embed_text(question)

    response = client.query_points(
        collection_name=COLLECTION_NAME,
        query=query_vector,
        limit=top_k,
        with_payload=True,
    )

    results = response.points

    if not results:
        return []

    best_score = results[0].score

    print("Best RAG score:", best_score)

    if best_score < MIN_SCORE:

        print(
            "No sufficiently relevant textbook content found."
        )

        return []

    filtered_results = []

    minimum_allowed_score = best_score - MAX_SCORE_GAP

    for result in results:

        if result.score >= minimum_allowed_score:
            filtered_results.append(result)

    print(
        "Relevant chunks:",
        len(filtered_results)
    )

    return filtered_results