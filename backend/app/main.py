from fastapi import FastAPI, HTTPException
from app.jokes import get_joke
from app.deepseek_client import generate_joke
import json
import requests

app = FastAPI(
    title="Joke & Riddle Buddy",
    description="Safe jokes and riddles for kids",
    version="0.1.0"
)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/joke1")
def joke1(category: str | None = None, type: str | None = None):
    result = get_joke(category=category, type_=type)
    if not result:
        raise HTTPException(status_code=404, detail="No joke found")

    return result

@app.get("/joke")
def joke(category: str | None = None, joke_type: str | None = None):
    try:
        raw = generate_joke(category=category, joke_type=joke_type)

        # DeepSeek returns text → parse JSON
        data = json.loads(raw)

        return {
            "type": joke_type or "joke",
            "category": category or "random",
            "question": data["question"],
            "answer": data["answer"]
        }

    except Exception as e:
        print("ERROR:", repr(e))   # 👈 IMPORTANT
        raise HTTPException(
            status_code=503,
            detail=str(e)
        )
