import json
import random
from pathlib import Path

DATA_FILE = Path(__file__).parent / "data" / "jokes.json"

with open(DATA_FILE, "r", encoding="utf-8") as f:
    JOKES = json.load(f)

def get_joke(category: str | None = None, type_: str | None = None):
    filtered = JOKES

    if category:
        filtered = [j for j in filtered if j["category"] == category]

    if type_:
        filtered = [j for j in filtered if j["type"] == type_]

    if not filtered:
        return None

    return random.choice(filtered)
