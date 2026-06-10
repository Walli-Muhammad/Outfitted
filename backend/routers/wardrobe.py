from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import WardrobeItem, User
from services import upload_image, tag_garment

router = APIRouter(prefix="/wardrobe", tags=["Wardrobe Catalog"])

def ensure_user_exists(db: Session, user_id: str):
    """
    Ensures that a user with the given user_id exists in the database
    to prevent foreign key constraint violations on WardrobeItem insert.
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        # Create a placeholder dev user
        user = User(
            id=user_id,
            firebase_uid=user_id,
            email=f"{user_id}@example.com",
            is_premium=False
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    return user

@router.post("/items")
async def create_wardrobe_item(
    user_id: str = Form("dev-user-1"),
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """
    Accepts multipart/form-data with fields: user_id (str), file (image).
    1. Uploads file to Cloudinary.
    2. Calls vision.tag_garment(image_url) to get AI tags (with fallback on error).
    3. Saves new WardrobeItem row to Postgres/SQLite.
    4. Returns the full item as JSON.
    """
    # 1. Upload to Cloudinary
    try:
        image_url = await upload_image(file)
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=f"Cloudinary upload failed: {str(e)}"
        )

    # 2. Get AI Tags with robust fallback logic
    try:
        tags = await tag_garment(image_url)
    except HTTPException:
        raise
    except Exception as e:
        print(f"AI Vision Tagging Error (falling back to defaults): {e}")
        tags = {
            "type": "unknown",
            "color": "unknown",
            "style": "unknown",
            "occasions": [],
            "description": "Auto-tagging failed. Please edit manually."
        }

    # 3. Ensure dev user exists in database to bypass foreign key restriction
    ensure_user_exists(db, user_id)

    # 4. Save to Database
    db_item = WardrobeItem(
        user_id=user_id,
        image_url=image_url,
        type=tags.get("type", "unknown"),
        color=tags.get("color", "unknown"),
        style=tags.get("style", "unknown"),
        occasions=tags.get("occasions", []),
        description=tags.get("description", "")
    )
    
    db.add(db_item)
    db.commit()
    db.refresh(db_item)

    return db_item

@router.get("/items/{user_id}")
def get_user_wardrobe(user_id: str, db: Session = Depends(get_db)):
    """
    Returns all wardrobe items for a user as a JSON array, ordered by created_at descending.
    """
    ensure_user_exists(db, user_id)
    
    items = db.query(WardrobeItem)\
              .filter(WardrobeItem.user_id == user_id)\
              .order_by(WardrobeItem.created_at.desc())\
              .all()
              
    return items


from pydantic import BaseModel

class WardrobeItemUpdate(BaseModel):
    type: str | None = None
    color: str | None = None
    style: str | None = None


@router.patch("/items/{item_id}")
def update_wardrobe_item(item_id: str, body: WardrobeItemUpdate, db: Session = Depends(get_db)):
    """
    Updates the type, color, and/or style fields of a specific wardrobe item.
    """
    db_item = db.query(WardrobeItem).filter(WardrobeItem.id == item_id).first()
    if not db_item:
        raise HTTPException(status_code=404, detail="Wardrobe item not found")
        
    if body.type is not None:
        db_item.type = body.type
    if body.color is not None:
        db_item.color = body.color
    if body.style is not None:
        db_item.style = body.style
        
    db.commit()
    db.refresh(db_item)
    return db_item


@router.delete("/items/{item_id}")
def delete_wardrobe_item(item_id: str, db: Session = Depends(get_db)):
    """
    Deletes a specific wardrobe item from the database.
    """
    db_item = db.query(WardrobeItem).filter(WardrobeItem.id == item_id).first()
    if not db_item:
        raise HTTPException(status_code=404, detail="Wardrobe item not found")
        
    db.delete(db_item)
    db.commit()
    return {"deleted": True}


