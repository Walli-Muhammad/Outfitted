import uuid
from datetime import date
from sqlalchemy import Column, String, DateTime, ForeignKey, Table, Text, Integer, Date, JSON, func
from sqlalchemy.orm import relationship
from database import Base

# Junction table representing the many-to-many relationship between Outfits and WardrobeItems
outfit_items = Table(
    "outfit_items",
    Base.metadata,
    Column("outfit_id", String(36), ForeignKey("outfits.id", ondelete="CASCADE"), primary_key=True),
    Column("wardrobe_item_id", String(36), ForeignKey("wardrobe_items.id", ondelete="CASCADE"), primary_key=True)
)

class Outfit(Base):
    __tablename__ = "outfits"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    # AI-generated suggestion fields
    outfit_name = Column(String(255), nullable=True)
    item_ids = Column(JSON, nullable=True)        # list of wardrobe item UUIDs
    reasoning = Column(Text, nullable=True)
    style_score = Column(Integer, nullable=True)  # 0–100

    # Context fields
    occasion = Column(String(100), nullable=True)
    suggested_date = Column(Date, nullable=True, default=date.today, index=True)

    # Legacy / general fields
    name = Column(String(255), nullable=True)
    description = Column(Text, nullable=True)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="outfits")
    items = relationship("WardrobeItem", secondary=outfit_items, back_populates="outfits")
    history_entries = relationship("OutfitHistory", back_populates="outfit", cascade="all, delete-orphan")
