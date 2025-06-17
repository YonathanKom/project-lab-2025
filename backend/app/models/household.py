from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from datetime import datetime

from app.core.database import Base
from .user import user_households

class Household(Base):
    __tablename__ = "households"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Many-to-many relationship with users
    members = relationship(
        "User", 
        secondary=user_households, 
        back_populates="households"
    )

    invitations = relationship("HouseholdInvitation", back_populates="household")
    shopping_lists = relationship("ShoppingList", back_populates="household")

    def get_members_with_roles(self, db_session):
        from sqlalchemy import text
        result = db_session.execute(
            text("""
                SELECT u.id, u.username, u.email, uh.role, uh.joined_at
                FROM users u 
                JOIN user_households uh ON u.id = uh.user_id 
                WHERE uh.household_id = :household_id
            """),
            {"household_id": self.id}
        ).fetchall()
        
        return [
            {
                "id": row[0],
                "username": row[1], 
                "email": row[2],
                "role": row[3],
                "joined_at": row[4]
            }
            for row in result
        ]

class HouseholdInvitation(Base):
    __tablename__ = "household_invitations"
    
    id = Column(Integer, primary_key=True, index=True)
    household_id = Column(Integer, ForeignKey("households.id"), nullable=False)
    invited_by_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    invited_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(String(20), default="pending")  # pending, accepted, rejected, cancelled
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    responded_at = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    household = relationship("Household", back_populates="invitations")
    invited_by = relationship("User", foreign_keys=[invited_by_id])
    invited_user = relationship("User", foreign_keys=[invited_user_id])