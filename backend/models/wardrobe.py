import uuid
from sqlalchemy import Column, String, Text, DateTime, ForeignKey, JSON, func
from sqlalchemy.orm import relationship
from database import Base

class WardrobeItem(Base):
    __tablename__ = "wardrobe_items"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Cloudinary image hosting URL
    image_url = Column(String(1024), nullable=False)
    
    # AI Autotags & Descriptions
    type = Column(String(100), nullable=True, index=True) # shirt, pants, dress, etc.
    color = Column(String(100), nullable=True, index=True)
    style = Column(String(100), nullable=True, index=True) # smart casual, formal, etc.
    occasions = Column(JSON, nullable=True) # ["work", "dinner"]
    description = Column(Text, nullable=True)
    
    # General-purpose custom tags dictionary for user overrides
    custom_tags = Column(JSON, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="wardrobe_items")
    tryon_results = relationship("TryOnResult", back_populates="wardrobe_item", cascade="all, delete-orphan")
    
    # Outfit relationship through the junction table (defined inside outfit.py)
    outfits = relationship("Outfit", secondary="outfit_items", back_populates="items")
