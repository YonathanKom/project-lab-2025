from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime

from app.core.database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    household_id = Column(Integer, ForeignKey("households.id"))
    
    household = relationship("Household", back_populates="members")
    shopping_lists = relationship("ShoppingList", back_populates="owner")

class Household(Base):
    __tablename__ = "households"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    
    members = relationship("User", back_populates="household")
    shopping_lists = relationship("ShoppingList", back_populates="household")

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