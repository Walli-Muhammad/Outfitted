import uuid
from sqlalchemy import Column, String, DateTime, Date, ForeignKey, func
from sqlalchemy.orm import relationship
from database import Base

class OutfitHistory(Base):
    __tablename__ = "outfit_history"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    outfit_id = Column(String(36), ForeignKey("outfits.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Specific date the outfit was worn
    worn_on = Column(Date, nullable=False, server_default=func.current_date(), index=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="history_entries")
    outfit = relationship("Outfit", back_populates="history_entries")
