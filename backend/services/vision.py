import httpx
import json
import os
from dotenv import load_dotenv

# Load .env every time this module is imported so credentials are always fresh
load_dotenv()


async def tag_garment(image_url: str) -> dict:
    """
    Submits a secure garment image URL to OpenRouter running google/gemini-2.5-flash-lite.
    Returns parsed tagging properties (type, color, style, occasions, description).
    """
    # Read key lazily so it is always sourced after load_dotenv() has executed
    OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")

    prompt = """Analyze this clothing item and return ONLY a JSON object, no preamble, no markdown backticks:
{
  "type": "shirt",
  "color": "blue",
  "style": "smart casual",
  "occasions": ["work", "dinner"],
  "description": "Blue oxford cotton shirt with button-down collar"
}"""

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

    # Validation: Ensure it looks like a clothing item.
    # "unknown" means Gemini recognised the image but it is not clothing — reject it.
    # The unknown fallback is reserved for API-level failures, not successful non-clothing detection.
    from fastapi import HTTPException

    item_type = str(tags.get("type", "")).strip().lower()
    item_color = str(tags.get("color", "")).strip().lower()

    if item_type == "unknown" or item_color == "unknown":
        raise HTTPException(
            status_code=400,
            detail="This doesn't look like a clothing item. Please photograph a garment."
        )

    valid_types = [
        "shirt", "t-shirt", "pants", "jeans", "shorts", "jacket", "coat",
        "sweater", "dress", "skirt", "shoes", "hoodie", "suit", "blazer",
        "top", "blouse", "cardigan", "vest"
    ]
    if item_type not in valid_types:
        raise HTTPException(
            status_code=400,
            detail="This doesn't look like a clothing item. Please photograph a garment."
        )

    return tags

