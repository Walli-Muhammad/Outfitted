import os
import httpx
from dotenv import load_dotenv

load_dotenv()

# Map OWM condition codes to friendly strings
_CONDITION_MAP = {
    "Clear": "sunny",
    "Clouds": "cloudy",
    "Rain": "rainy",
    "Drizzle": "drizzle",
    "Thunderstorm": "stormy",
    "Snow": "snowy",
    "Mist": "misty",
    "Fog": "foggy",
    "Haze": "hazy",
}

_FALLBACK = {
    "city": "Unknown",
    "temp_c": 25,
    "condition": "clear",
    "humidity": 60,
}


async def get_weather(city: str) -> dict:
    """
    Fetches current weather for a city via OpenWeatherMap free-tier API.
    Reads OPENWEATHERMAP_API_KEY lazily so load_dotenv() is always called first.
    Returns a normalised dict. On any failure returns a safe default — never raises.
    """
    api_key = os.getenv("OPENWEATHERMAP_API_KEY", "")

    if not api_key or api_key.startswith("your-"):
        print("OpenWeatherMap API key not configured — returning default weather.")
        return {**_FALLBACK, "city": city}

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(
                "https://api.openweathermap.org/data/2.5/weather",
                params={
                    "q": city,
                    "appid": api_key,
                    "units": "metric",
                },
            )
            print(f"DEBUG: OpenWeatherMap API response for '{city}': {resp.status_code} - {resp.text}")
            resp.raise_for_status()
            data = resp.json()

        main = data.get("main", {})
        weather_list = data.get("weather", [{}])
        owm_condition = weather_list[0].get("main", "Clear")

        return {
            "city": data.get("name", city),
            "temp_c": round(main.get("temp", 25)),
            "condition": _CONDITION_MAP.get(owm_condition, owm_condition.lower()),
            "humidity": main.get("humidity", 60),
        }

    except Exception as exc:
        print(f"Weather fetch failed for '{city}': {exc} — using fallback.")
        return {**_FALLBACK, "city": city}
