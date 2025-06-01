from sqlalchemy import Column, Integer, Float, String, ForeignKey, Table, DateTime, Boolean, func
from sqlalchemy.orm import relationship
from datetime import datetime

from app.core.database import Base

user_households = Table(
    'user_households',
    Base.metadata,
    Column('id', Integer, primary_key=True),
    Column('user_id', Integer, ForeignKey('users.id'), nullable=False),
    Column('household_id', Integer, ForeignKey('households.id'), nullable=False),
    Column('joined_at', DateTime, default=datetime.utcnow),
    Column('role', String, default='member')  # 'admin', 'member'
)

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    
    # Many-to-many relationship with households
    households = relationship(
        "Household", 
        secondary=user_households, 
        back_populates="members"
    )
    shopping_lists = relationship("ShoppingList", back_populates="owner")

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
    name = Column(String, index=True)
    quantity = Column(Float)
    unit = Column(String)
    is_purchased = Column(Boolean, default=False)
    shopping_list_id = Column(Integer, ForeignKey("shopping_lists.id"))
    
    shopping_list = relationship("ShoppingList", back_populates="items")
    price_data = relationship("ItemPrice", back_populates="item")

class ShoppingListHistory(Base):
    __tablename__ = "shopping_list_history"
    id = Column(Integer, primary_key=True, index=True)
    shopping_list_id = Column(Integer, ForeignKey("shopping_lists.id"))
    action = Column(String)  # "add", "update", "delete"
    item_data = Column(String)  # JSON string of item data
    user_id = Column(Integer, ForeignKey("users.id"))
    timestamp = Column(DateTime, default=datetime.utcnow)
    
    shopping_list = relationship("ShoppingList", back_populates="history")

class Store(Base):
    __tablename__ = "stores"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    location = Column(String)  # Could be GPS coordinates or address
    
    prices = relationship("ItemPrice", back_populates="store")

class ItemPrice(Base):
    __tablename__ = "item_prices"
    id = Column(Integer, primary_key=True, index=True)
    item_id = Column(Integer, ForeignKey("shopping_items.id"))
    store_id = Column(Integer, ForeignKey("stores.id"))
    price = Column(Float)
    last_updated = Column(DateTime, default=datetime.utcnow)
    
    item = relationship("ShoppingItem", back_populates="price_data")
    store = relationship("Store", back_populates="prices")

class PurchaseHistory(Base):
    __tablename__ = "purchase_history"
    id = Column(Integer, primary_key=True, index=True)
    household_id = Column(Integer, ForeignKey("households.id"))
    item_name = Column(String, index=True)
    purchase_date = Column(DateTime, default=datetime.utcnow)
    frequency = Column(Integer, default=1)  # How often purchased