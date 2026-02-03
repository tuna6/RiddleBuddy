import os, httpx, time, requests
from uuid import uuid4
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import Response
from app.jokes import get_joke
from app.deepseek_client import generate_joke
import json
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from prometheus_fastapi_instrumentator import Instrumentator


FEEDBACK_SERVICE_URL = os.getenv(
    "FEEDBACK_SERVICE_URL",
    "http://localhost:8080"
)
TIMEOUT = 3.0

app = FastAPI(
    title="Joke & Riddle Buddy",
    description="Safe jokes and riddles for kids",
    version="0.1.0"
)
Instrumentator().instrument(app).expose(app)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory="app/frontend", html=True), name="frontend")

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
        joke_id = str(uuid4())

        return {
            "id": joke_id,
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
    
    FEEDBACK_SERVICE_URL = os.getenv(
    "FEEDBACK_SERVICE_URL",
    "http://feedback-service:8080"
)

client = httpx.AsyncClient(timeout=3.0)

@app.post("/feedback")
async def post_feedback(payload: dict):
    r = await client.post(
        f"{FEEDBACK_SERVICE_URL}/feedback",
        json=payload
    )
    return r.json() if r.content else {"ok": True}


@app.get("/feedback/{joke_id}")
async def get_feedback(joke_id: str):
    r = await client.get(
        f"{FEEDBACK_SERVICE_URL}/feedback/{joke_id}"
    )
    return r.json()

# ---- METRICS ----
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "path", "status"]
)

REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency",
    ["path"]
)

# ---- MIDDLEWARE ----
@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()

    response = await call_next(request)

    duration = time.time() - start_time

    path = request.url.path

    REQUEST_COUNT.labels(
        method=request.method,
        path=path,
        status=response.status_code
    ).inc()

    REQUEST_LATENCY.labels(path=path).observe(duration)

    return response


# ---- METRICS ENDPOINT ----
@app.get("/metrics")
def metrics():
    return Response(
        content=generate_latest(),
        media_type=CONTENT_TYPE_LATEST
    )

