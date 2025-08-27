from sqlalchemy import Column, Integer, String, Table, DateTime, ForeignKey, func
from sqlalchemy.orm import relationship

from app.core.database import Base

user_households = Table(
    "user_households",
    Base.metadata,
    Column("id", Integer, primary_key=True),
    Column("user_id", Integer, ForeignKey("users.id"), nullable=False),
    Column("household_id", Integer, ForeignKey("households.id"), nullable=False),
    Column("joined_at", DateTime, default=func.now()),
    Column("role", String, default="member"),  # 'admin', 'member'
)


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)

    # Many-to-many relationship with households
    households = relationship(
        "Household", secondary=user_households, back_populates="members"
    )
    shopping_lists = relationship("ShoppingList", back_populates="owner")
