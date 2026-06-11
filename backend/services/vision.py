import httpx
import json
import os
from dotenv import load_dotenv
from fastapi import HTTPException

# Load .env every time this module is imported so credentials are always fresh
load_dotenv()


async def tag_garment(image_url: str) -> dict:
    """
    Submits a secure garment image URL to OpenRouter running google/gemini-2.5-flash-lite.
    Returns parsed tagging properties (type, color, style, occasions, description).
    """
    # Read key lazily so it is always sourced after load_dotenv() has executed
    OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")

    prompt = """You are a clothing recognition system. Your ONLY job is to analyze clothing items.

If the image does NOT show a clothing item (e.g. it shows a screenshot, text, a person's face, furniture, electronics, food, or anything that is not a garment), you MUST return exactly this JSON and nothing else:
{"type": "unknown", "color": "unknown", "style": "unknown", "occasions": [], "description": "not a clothing item"}

If the image DOES show a clothing item, return ONLY a JSON object like this example, no preamble, no markdown:
{"type": "shirt", "color": "blue", "style": "smart casual", "occasions": ["work", "dinner"], "description": "Blue oxford cotton shirt with button-down collar"}"""

    # If the key is not set or is a placeholder, return mock tagged item for easy local dev
    if not OPENROUTER_API_KEY or "your-" in OPENROUTER_API_KEY or OPENROUTER_API_KEY == "":
        print("OpenRouter API key not configured. Returning pre-populated mock garment tags.")
        return {
            "type": "shirt",
            "color": "blue",
            "style": "smart casual",
            "occasions": ["work", "dinner"],
            "description": "Blue oxford cotton shirt with button-down collar"
        }

    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {OPENROUTER_API_KEY}",
                "Content-Type": "application/json"
            },
            json={
                "model": "google/gemini-2.5-flash-lite",
                "messages": [
                    {
                        "role": "user",
                        "content": [
                            {"type": "image_url", "image_url": {"url": image_url}},
                            {"type": "text", "text": prompt}
                        ]
                    }
                ]
            },
            timeout=30.0
        )

    # Throw error if non-200 to trigger robust fallback
    response.raise_for_status()
    
    result = response.json()
    text = result["choices"][0]["message"]["content"]
    
    # Extract clean JSON
    clean = text.replace("```json", "").replace("```", "").strip()
    tags = json.loads(clean)

    # Reject non-clothing images
    item_type = tags.get("type", "unknown").lower().strip()
    item_color = tags.get("color", "unknown").lower().strip()

    VALID_TYPES = [
        "shirt", "t-shirt", "pants", "jeans", "shorts", "jacket",
        "coat", "sweater", "dress", "skirt", "shoes", "hoodie",
        "suit", "blazer", "top", "blouse", "cardigan", "vest"
    ]

    if item_type == "unknown" or item_color == "unknown":
        raise HTTPException(status_code=400, detail="This doesn't look like a clothing item. Please photograph a garment.")

    if item_type not in VALID_TYPES:
        raise HTTPException(status_code=400, detail="This doesn't look like a clothing item. Please photograph a garment.")

    return tags
