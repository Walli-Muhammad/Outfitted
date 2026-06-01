import os
import re
import json
import httpx
from dotenv import load_dotenv

load_dotenv()

_OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
_MODEL = "google/gemini-2.5-flash-lite"


def _build_prompt(wardrobe_items: list, weather: dict, occasion: str) -> str:
    """Constructs the structured LLM prompt."""
    wardrobe_json = json.dumps(
        [
            {
                "id": item["id"],
                "type": item.get("type", "unknown"),
                "color": item.get("color", "unknown"),
                "style": item.get("style", "unknown"),
                "occasions": item.get("occasions", []),
                "description": item.get("description", ""),
            }
            for item in wardrobe_items
        ],
        indent=2,
    )

    return f"""You are a professional fashion stylist AI.

The user's wardrobe contains these items:
{wardrobe_json}

Today's weather in {weather.get("city", "the city")}:
- Temperature: {weather.get("temp_c", 25)}°C
- Condition: {weather.get("condition", "clear")}
- Humidity: {weather.get("humidity", 60)}%

The occasion is: {occasion}

Return ONLY a JSON array of exactly 3 outfit suggestions. No preamble, no markdown fences, no explanation — just the JSON array.

Each suggestion must follow this exact schema:
{{
  "outfit_name": "A creative outfit name",
  "item_ids": ["<uuid of item 1>", "<uuid of item 2>"],
  "reasoning": "A short sentence explaining why this outfit suits the weather and occasion",
  "style_score": <integer 0-100 representing how well the outfit matches the occasion and weather>
}}

Use only item IDs that exist in the wardrobe list above. Choose 2-4 items per outfit."""


async def suggest_outfits(wardrobe_items: list, weather: dict, occasion: str) -> list:
    """
    Calls OpenRouter (Gemini 2.5 Flash Lite) to generate 3 outfit suggestions.
    Reads OPENROUTER_API_KEY lazily. On any failure returns an empty list — never raises.
    """
    api_key = os.getenv("OPENROUTER_API_KEY", "")

    if not api_key or api_key.startswith("your-"):
        print("OpenRouter API key not configured — returning empty outfit suggestions.")
        return []

    prompt = _build_prompt(wardrobe_items, weather, occasion)

    try:
        async with httpx.AsyncClient(timeout=45.0) as client:
            resp = await client.post(
                _OPENROUTER_URL,
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": _MODEL,
                    "messages": [{"role": "user", "content": prompt}],
                },
            )
            resp.raise_for_status()

        result = resp.json()
        raw_text = result["choices"][0]["message"]["content"]

        # Robustly extract the JSON array — strip any markdown fences the model may add
        # Try to find a JSON array anywhere in the response
        match = re.search(r'\[.*\]', raw_text, re.DOTALL)
        if match:
            clean = match.group(0)
        else:
            # Fall back to stripping fences manually
            clean = re.sub(r'```(?:json)?', '', raw_text).replace('```', '').strip()

        suggestions = json.loads(clean)
        if not isinstance(suggestions, list):
            suggestions = [suggestions]

        return suggestions

    except Exception as exc:
        print(f"Outfit suggestion failed: {exc}")
        return []
