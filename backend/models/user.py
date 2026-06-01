import uuid
from sqlalchemy import Column, String, Boolean, DateTime, func
from sqlalchemy.orm import relationship
from database import Base

class User(Base):
    __tablename__ = "users"

    # String-based UUID primary key for maximum database engine portability
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    
    # Unique Firebase User Identifier
    firebase_uid = Column(String(255), unique=True, nullable=False, index=True)
    
    email = Column(String(255), unique=True, nullable=False, index=True)
    
    # Cloudinary URL for full body avatar/model photo used in virtual try-ons
    full_body_photo_url = Column(String(1024), nullable=True)
    
    # Premium gate status tracking
    is_premium = Column(Boolean, default=False, nullable=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    wardrobe_items = relationship("WardrobeItem", back_populates="user", cascade="all, delete-orphan")
    outfits = relationship("Outfit", back_populates="user", cascade="all, delete-orphan")
    tryon_results = relationship("TryOnResult", back_populates="user", cascade="all, delete-orphan")
    history_entries = relationship("OutfitHistory", back_populates="user", cascade="all, delete-orphan")
