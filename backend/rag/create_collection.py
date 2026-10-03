from qdrant_client.models import Distance, VectorParams

from qdrant_store import client, COLLECTION_NAME


def create_collection():

    existing_collections = client.get_collections()

    names = [
        collection.name
        for collection in existing_collections.collections
    ]

    if COLLECTION_NAME in names:

        print(f"Collection already exists: {COLLECTION_NAME}")
        return

    client.create_collection(
        collection_name=COLLECTION_NAME,
        vectors_config=VectorParams(
            size=768,
            distance=Distance.COSINE,
        ),
    )

    print(f"Collection created: {COLLECTION_NAME}")


if __name__ == "__main__":
    create_collection()