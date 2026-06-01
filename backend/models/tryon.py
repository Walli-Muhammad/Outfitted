import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, func
from sqlalchemy.orm import relationship
from database import Base


class TryOnResult(Base):
    __tablename__ = "tryon_results"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    wardrobe_item_id = Column(String(36), ForeignKey("wardrobe_items.id", ondelete="CASCADE"), nullable=False, index=True)

    # Primary result URL returned by Replicate
    result_image_url = Column(String(1024), nullable=True)

    # Status: pending | completed | failed
    status = Column(String(50), default="pending", nullable=False)

    # Replicate prediction ID for debugging / status polling
    replicate_prediction_id = Column(String(255), nullable=True, index=True)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="tryon_results")
    wardrobe_item = relationship("WardrobeItem", back_populates="tryon_results")
