from fastapi import FastAPI, HTTPException
from app.jokes import get_joke

app = FastAPI(
    title="Joke & Riddle Buddy",
    description="Safe jokes and riddles for kids",
    version="0.1.0"
)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/joke")
def joke(category: str | None = None, type: str | None = None):
    result = get_joke(category=category, type_=type)
    if not result:
        raise HTTPException(status_code=404, detail="No joke found")

    return result
