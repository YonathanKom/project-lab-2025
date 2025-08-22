from sqlalchemy import (
    Column,
    Integer,
    Float,
    String,
    ForeignKey,
    DateTime,
    Boolean,
    func,
    Text,
)
from sqlalchemy.orm import relationship
from datetime import datetime

from app.core.database import Base


class ShoppingList(Base):
    __tablename__ = "shopping_lists"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    owner_id = Column(Integer, ForeignKey("users.id"))
    household_id = Column(Integer, ForeignKey("households.id"))

    owner = relationship("User", back_populates="shopping_lists")
    household = relationship("Household", back_populates="shopping_lists")
    items = relationship("ShoppingItem", back_populates="shopping_list")
    history = relationship("ShoppingListHistory", back_populates="shopping_list")


class ShoppingItem(Base):
    __tablename__ = "shopping_items"

    id = Column(Integer, primary_key=True, index=True)
    shopping_list_id = Column(
        Integer, ForeignKey("shopping_lists.id", ondelete="CASCADE"), nullable=False
    )
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    quantity = Column(Float, nullable=False, default=1)
    is_purchased = Column(Boolean, default=False, nullable=False)
    item_code = Column(
        String(50), ForeignKey("items.item_code"), nullable=True, index=True
    )  # Government item code
    price = Column(Float, nullable=True)  # Price per item

    # Tracking fields
    added_by_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    purchased_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    purchased_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    shopping_list = relationship("ShoppingList", back_populates="items")
    added_by = relationship("User", foreign_keys=[added_by_id])
    purchased_by = relationship("User", foreign_keys=[purchased_by_id])
    item = relationship(
        "Item", back_populates="shopping_items", foreign_keys=[item_code]
    )

    def __repr__(self):
        return f"<ShoppingItem(id={self.id}, name='{self.name}', quantity={self.quantity})>"


class ShoppingListHistory(Base):
    __tablename__ = "shopping_list_history"
    id = Column(Integer, primary_key=True, index=True)
    shopping_list_id = Column(Integer, ForeignKey("shopping_lists.id"))
    action = Column(String)  # "add", "update", "delete"
    item_data = Column(String)  # JSON string of item data
    user_id = Column(Integer, ForeignKey("users.id"))
    timestamp = Column(DateTime, default=datetime.utcnow)

    shopping_list = relationship("ShoppingList", back_populates="history")
