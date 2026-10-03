import hashlib
import time
from pathlib import Path

from qdrant_client.models import PointStruct

from chunker import load_json_file
from embeddings import embed_text
from qdrant_store import client, COLLECTION_NAME


MATHS_PATH = Path(
    r"D:\LearnovaFiles\Class10\MathsChapterFiles\Chapters(json)"
)

SCIENCE_PATH = Path(
    r"D:\LearnovaFiles\Class10\ScienceChapterFiles\Chapters(Json)"
)

BATCH_SIZE = 10
MAX_RETRIES = 5


def create_chunk_id(chunk):

    unique_text = (
        f"{chunk.get('class', '')}|"
        f"{chunk.get('subject', '')}|"
        f"{chunk.get('chapter_number', '')}|"
        f"{chunk.get('chapter', '')}|"
        f"{chunk.get('section', '')}|"
        f"{chunk.get('content_type', '')}|"
        f"{chunk.get('text', '')}"
    )

    hash_value = hashlib.sha256(
        unique_text.encode("utf-8")
    ).hexdigest()

    return int(hash_value[:15], 16)


def get_all_json_files():

    files = []

    for folder in [MATHS_PATH, SCIENCE_PATH]:

        if not folder.exists():
            print(f"Folder not found: {folder}")
            continue

        files.extend(sorted(folder.glob("*.json")))

    return files


def embed_with_retry(text):

    for attempt in range(MAX_RETRIES):

        try:

            return embed_text(text)

        except Exception as e:

            error = str(e)

            if "429" not in error and "RESOURCE_EXHAUSTED" not in error:
                raise

            wait_time = 10 * (attempt + 1)

            print()
            print(
                f"Gemini rate limit reached. "
                f"Waiting {wait_time} seconds..."
            )

            time.sleep(wait_time)

    raise RuntimeError(
        "Embedding failed after maximum retries."
    )


def upload_batch(points):

    if not points:
        return 0

    client.upsert(
        collection_name=COLLECTION_NAME,
        points=points,
        wait=True,
    )

    return len(points)


def ingest():

    json_files = get_all_json_files()

    print(f"JSON files found: {len(json_files)}")

    total_uploaded = 0
    failed_files = []

    for file_path in json_files:

        print()
        print("=" * 60)
        print(f"Processing: {file_path.name}")

        try:

            chunks = load_json_file(file_path)

            print(f"Chunks: {len(chunks)}")

            batch = []
            file_uploaded = 0

            for index, chunk in enumerate(chunks):

                text = chunk["text"].strip()

                if not text:
                    continue

                chunk["source_file"] = file_path.name

                print(
                    f"Embedding {index + 1}/{len(chunks)}",
                    end="\r",
                    flush=True,
                )

                vector = embed_with_retry(text)

                point = PointStruct(
                    id=create_chunk_id(chunk),
                    vector=vector,
                    payload=chunk,
                )

                batch.append(point)

                # Upload progressively
                if len(batch) >= BATCH_SIZE:

                    uploaded = upload_batch(batch)

                    file_uploaded += uploaded
                    total_uploaded += uploaded

                    batch = []

                    # Small pause to reduce pressure
                    time.sleep(1)

            # Upload remaining points
            if batch:

                uploaded = upload_batch(batch)

                file_uploaded += uploaded
                total_uploaded += uploaded

            print()
            print(
                f"✓ Finished {file_path.name}: "
                f"{file_uploaded} chunks"
            )

        except Exception as e:

            print()
            print(
                f"✗ ERROR {file_path.name}: {e}"
            )

            failed_files.append(file_path.name)

    print()
    print("=" * 60)
    print("INGESTION FINISHED")
    print("=" * 60)

    print(
        f"Chunks processed/uploaded this run: "
        f"{total_uploaded}"
    )

    if failed_files:

        print("\nFiles with errors:")

        for file in failed_files:
            print("-", file)

    else:

        print("All files processed successfully.")


if __name__ == "__main__":
    ingest()