from sqlalchemy import (
    Column,
    Integer,
    Float,
    String,
    ForeignKey,
    Table,
    DateTime,
    Boolean,
    func,
    Text,
    Index,
)
from sqlalchemy.orm import relationship
from datetime import datetime

from app.core.database import Base

user_households = Table(
    "user_households",
    Base.metadata,
    Column("id", Integer, primary_key=True),
    Column("user_id", Integer, ForeignKey("users.id"), nullable=False),
    Column("household_id", Integer, ForeignKey("households.id"), nullable=False),
    Column("joined_at", DateTime, default=datetime.utcnow),
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


class Household(Base):
    __tablename__ = "households"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Many-to-many relationship with users
    members = relationship(
        "User", secondary=user_households, back_populates="households"
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
            {"household_id": self.id},
        ).fetchall()

        return [
            {
                "id": row[0],
                "username": row[1],
                "email": row[2],
                "role": row[3],
                "joined_at": row[4],
            }
            for row in result
        ]


class HouseholdInvitation(Base):
    __tablename__ = "household_invitations"

    id = Column(Integer, primary_key=True, index=True)
    household_id = Column(Integer, ForeignKey("households.id"), nullable=False)
    invited_by_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    invited_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(
        String(20), default="pending"
    )  # pending, accepted, rejected, cancelled
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    responded_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    household = relationship("Household", back_populates="invitations")
    invited_by = relationship("User", foreign_keys=[invited_by_id])
    invited_user = relationship("User", foreign_keys=[invited_user_id])


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
    quantity = Column(Integer, nullable=False, default=1)
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


class Chain(Base):
    __tablename__ = "chains"

    id = Column(Integer, primary_key=True, index=True)
    chain_id = Column(
        String(50), unique=True, index=True, nullable=False
    )  # Government chain ID
    name = Column(String(255), nullable=False)
    sub_chain_id = Column(String(50), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    stores = relationship("Store", back_populates="chain")


class Store(Base):
    __tablename__ = "stores"

    id = Column(Integer, primary_key=True, index=True)
    store_id = Column(String(50), index=True, nullable=False)  # Government store ID
    chain_id = Column(String(50), ForeignKey("chains.chain_id"), nullable=False)
    name = Column(String(255), nullable=True)
    address = Column(Text, nullable=True)
    city = Column(String(100), nullable=True)
    bikoret_no = Column(String(50), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)

    # Relationships
    chain = relationship("Chain", back_populates="stores")
    item_prices = relationship("ItemPrice", back_populates="store")

    # Composite unique constraint for chain_id + store_id
    __table_args__ = (Index("idx_chain_store", "chain_id", "store_id"),)


class Item(Base):
    __tablename__ = "items"

    id = Column(Integer, primary_key=True, index=True)
    item_code = Column(String(50), unique=True, index=True, nullable=False)
    item_type = Column(Integer, nullable=False)
    name = Column(String(255), nullable=False)
    manufacturer_name = Column(String(255), nullable=True)
    manufacture_country = Column(String(10), nullable=True)
    manufacturer_description = Column(Text, nullable=True)
    unit_qty = Column(String(50), nullable=True)  # e.g., "גרם"
    quantity = Column(Float, nullable=True)
    unit_of_measure = Column(String(100), nullable=True)  # e.g., "100 גרם"
    is_weighted = Column(Boolean, default=False)
    qty_in_package = Column(Float, nullable=True)
    allow_discount = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    shopping_items = relationship("ShoppingItem", back_populates="item")
    prices = relationship("ItemPrice", back_populates="item")


class ItemPrice(Base):
    __tablename__ = "item_prices"

    id = Column(Integer, primary_key=True, index=True)
    item_code = Column(String(50), ForeignKey("items.item_code"), nullable=False)
    store_id = Column(Integer, ForeignKey("stores.id"), nullable=False)
    price = Column(Float, nullable=False)
    unit_price = Column(Float, nullable=True)
    item_status = Column(Integer, default=1)  # 1 = active, 0 = inactive
    price_update_date = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    item = relationship("Item", back_populates="prices")
    store = relationship("Store", back_populates="item_prices")

    # Indexes for efficient queries
    __table_args__ = (
        Index("idx_item_store", "item_code", "store_id"),
        Index("idx_price_update_date", "price_update_date"),
        Index("idx_item_status", "item_status"),
    )


class PurchaseHistory(Base):
    __tablename__ = "purchase_history"
    id = Column(Integer, primary_key=True, index=True)
    household_id = Column(Integer, ForeignKey("households.id"))
    item_name = Column(String, index=True)
    purchase_date = Column(DateTime, default=datetime.utcnow)
    frequency = Column(Integer, default=1)  # How often purchased
