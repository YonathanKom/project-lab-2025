from sqlalchemy import Column, Integer, Float, DateTime, Text, Index
from sqlalchemy.sql import func
from app.core.database import Base


class AssociationRule(Base):
    __tablename__ = "association_rules"

    id = Column(Integer, primary_key=True, index=True)
    antecedent = Column(Text, nullable=False)  # JSON array of item codes
    consequent = Column(Text, nullable=False)  # JSON array of item codes
    support = Column(Float, nullable=False)
    confidence = Column(Float, nullable=False)
    lift = Column(Float, nullable=False)
    household_id = Column(Integer, nullable=True)  # NULL for global rules
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Indexes for efficient querying
    __table_args__ = (
        Index("idx_rules_confidence", "confidence"),
        Index("idx_rules_household", "household_id"),
        Index("idx_rules_created", "created_at"),
    )
