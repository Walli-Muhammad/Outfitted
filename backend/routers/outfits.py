from datetime import date, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db
from models import WardrobeItem, Outfit
from models.user import User
from services.weather import get_weather
from services.outfit_suggestion import suggest_outfits

router = APIRouter(prefix="/outfits", tags=["Daily Suggestions"])


# ── Pydantic schemas ──────────────────────────────────────────────────────────

class SuggestRequest(BaseModel):
    user_id: str = "dev-user-1"
    occasion: str = "casual"
    city: str = "Karachi"


# ── Helper ────────────────────────────────────────────────────────────────────

def _ensure_user_exists(db: Session, user_id: str) -> User:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        user = User(
            id=user_id,
            firebase_uid=user_id,
            email=f"{user_id}@example.com",
            is_premium=False,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    return user


def _item_to_dict(item: WardrobeItem) -> dict:
    return {
        "id": item.id,
        "type": item.type,
        "color": item.color,
        "style": item.style,
        "occasions": item.occasions or [],
        "description": item.description or "",
        "image_url": item.image_url,
    }


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("/suggest")
async def suggest(body: SuggestRequest, db: Session = Depends(get_db)):
    """
    Generates 3 AI outfit suggestions based on the user's wardrobe, weather, and occasion.
    Persists each suggestion as an Outfit row keyed to today's date.
    """
    _ensure_user_exists(db, body.user_id)

    # 1. Fetch wardrobe
    items = (
        db.query(WardrobeItem)
        .filter(WardrobeItem.user_id == body.user_id)
        .order_by(WardrobeItem.created_at.desc())
        .all()
    )

    if len(items) < 3:
        return {
            "suggestions": [],
            "weather": {},
            "message": "Add more items to your wardrobe first",
        }

    wardrobe_dicts = [_item_to_dict(i) for i in items]

    # 2. Get weather (never raises)
    weather = await get_weather(body.city)

    # 3. Ask AI for outfit suggestions (never raises)
    suggestions = await suggest_outfits(wardrobe_dicts, weather, body.occasion)

    # 4. Persist each suggestion as an Outfit row
    today = date.today()
    for s in suggestions:
        outfit = Outfit(
            user_id=body.user_id,
            outfit_name=s.get("outfit_name"),
            item_ids=s.get("item_ids", []),
            reasoning=s.get("reasoning"),
            style_score=s.get("style_score"),
            occasion=body.occasion,
            suggested_date=today,
        )
        db.add(outfit)
    db.commit()

    return {
        "weather": weather,
        "suggestions": suggestions,
    }


@router.get("/history/{user_id}")
def get_history(user_id: str, db: Session = Depends(get_db)):
    """
    Returns the last 30 days of outfit suggestions for a user,
    ordered by suggested_date descending.
    """
    cutoff = date.today() - timedelta(days=30)

    outfits = (
        db.query(Outfit)
        .filter(
            Outfit.user_id == user_id,
            Outfit.suggested_date >= cutoff,
        )
        .order_by(Outfit.suggested_date.desc(), Outfit.created_at.desc())
        .all()
    )

    return [
        {
            "id": o.id,
            "outfit_name": o.outfit_name,
            "item_ids": o.item_ids,
            "reasoning": o.reasoning,
            "style_score": o.style_score,
            "occasion": o.occasion,
            "suggested_date": str(o.suggested_date),
        }
        for o in outfits
    ]
