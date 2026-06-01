from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register")
def register_user(db: Session = Depends(get_db)):
    """
    Placeholder endpoint for user registration & Firebase ID token validation.
    """
    return {"message": "User registration endpoint stub"}

@router.get("/me")
def get_current_user(db: Session = Depends(get_db)):
    """
    Placeholder endpoint to retrieve current authenticated user details.
    """
    return {"message": "Get current user endpoint stub"}
