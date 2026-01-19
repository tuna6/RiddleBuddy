import os
import requests
import random

DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY")
DEEPSEEK_URL = "https://api.deepseek.com/v1/chat/completions"

if not DEEPSEEK_API_KEY:
    raise RuntimeError("DEEPSEEK_API_KEY not set")

def generate_joke(category=None, joke_type=None):
    # Build a VERY strict, kid-safe prompt
    prompt = (
        "You are a kid-safe joke generator.\n"
        "Rules:\n"
        "- Audience: children under 12\n"
        "- Clean, friendly, non-scary\n"
        "- One joke or riddle only\n"
        "- Avoid common jokes\n"
        "- Short\n"
        "- Emojis allowed\n\n"
    )

    if joke_type == "riddle":
        prompt += "Tell one easy riddle with its answer.\n"
    else:
        prompt += "Tell one funny joke.\n"

    if category:
        prompt += f"Theme: {category}\n"

    prompt += "\nDo NOT use the 'gummy bear' joke or the 'chicken cross the road' joke."
    prompt += (
        f"Return JSON ONLY in this format:\n"
        f"Random hint number: {random.randint(1, 100000)}"
        "{\n"
        '  "question": "...",\n'
        '  "answer": "..."\n'
        "}\n"
    )


    payload = {
        "model": "deepseek-chat",
        "messages": [
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.9
    }

    headers = {
        "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
        "Content-Type": "application/json"
    }

    response = requests.post(DEEPSEEK_URL, json=payload, headers=headers, timeout=10)
    response.raise_for_status()

    if response.status_code != 200:
        return {"joke": "Try again 😂"}
    print(f"Response code = {response.status_code}")
    print(f"Response json = {response.json()}")

    content = response.json()["choices"][0]["message"]["content"]
    content = content.strip()
    if content.startswith("```"):
        content = content.replace("```json", "").replace("```", "").strip()
    return content;
   # return content.replace("```json", "").replace("```", "").strip()

