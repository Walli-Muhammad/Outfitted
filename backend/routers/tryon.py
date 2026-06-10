from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db
from models import WardrobeItem, TryOnResult
from models.user import User
from services.cloudinary_service import upload_image
from services.tryon import run_tryon

router = APIRouter(prefix="/tryon", tags=["Virtual Try-On"])


# ── Pydantic schemas ──────────────────────────────────────────────────────────

class TryOnRequest(BaseModel):
    user_id: str = "dev-user-1"
    item_id: str


# ── Helpers ───────────────────────────────────────────────────────────────────

def _upsert_user(db: Session, user_id: str) -> User:
    """Creates dev user if not already present."""
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


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("/model-photo")
async def upload_model_photo(
    user_id: str = Form("dev-user-1"),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """
    Accepts multipart/form-data with user_id and file (full-body photo).
    Uploads photo to Cloudinary, saves URL to User.model_photo_url.
    Creates the user row if it doesn't exist yet (upsert).
    """
    # Upload to Cloudinary
    try:
        photo_url = await upload_image(file)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Photo upload failed: {str(e)}")

    # Upsert user and persist model photo URL
    user = _upsert_user(db, user_id)
    user.full_body_photo_url = photo_url
    db.commit()
    db.refresh(user)

    return {"model_photo_url": photo_url}


@router.post("/generate")
async def generate_tryon(body: TryOnRequest, db: Session = Depends(get_db)):
    """
    Runs IDM-VTON virtual try-on using the user's model photo + a wardrobe item image.
    Saves result as a TryOnResult row.
    """
    # 1. Fetch user — require model photo
    user = db.query(User).filter(User.id == body.user_id).first()
    if not user or not user.full_body_photo_url:
        raise HTTPException(
            status_code=400,
            detail="Please upload your model photo first",
        )

    # 2. Fetch wardrobe item
    item = db.query(WardrobeItem).filter(WardrobeItem.id == body.item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Wardrobe item not found")

    # 3. Create a pending TryOnResult row
    result_row = TryOnResult(
        user_id=body.user_id,
        wardrobe_item_id=body.item_id,
        status="pending",
    )
    db.add(result_row)
    db.commit()
    db.refresh(result_row)

    # 4. Call Replicate — may take 15–30 seconds
    try:
        result_url = await run_tryon(
            human_image_url=user.full_body_photo_url,
            garment_image_url=item.image_url,
            garment_description=item.description or item.type or "garment",
        )
        result_row.result_image_url = result_url
        result_row.status = "completed"
        db.commit()
        db.refresh(result_row)

        return {
            "id": result_row.id,
            "result_image_url": result_url,
            "item_id": body.item_id,
            "status": "completed",
        }

    except Exception as e:
        result_row.status = "failed"
        db.commit()
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/history/{user_id}")
def get_history(user_id: str, db: Session = Depends(get_db)):
    """
    Returns all TryOnResult rows for a user ordered by created_at descending.
    """
    results = (
        db.query(TryOnResult)
        .filter(TryOnResult.user_id == user_id)
        .order_by(TryOnResult.created_at.desc())
        .all()
    )

    return [
        {
            "id": r.id,
            "result_image_url": r.result_image_url,
            "item_id": r.wardrobe_item_id,
            "status": r.status,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        }
        for r in results
    ]
