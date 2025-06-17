from sqlalchemy import Column, Integer, Float, String, ForeignKey, DateTime, Boolean, func, Text, Index
from sqlalchemy.orm import relationship

from app.core.database import Base

class Chain(Base):
    __tablename__ = "chains"
    
    id = Column(Integer, primary_key=True, index=True)
    chain_id = Column(String(50), unique=True, index=True, nullable=False)  # Government chain ID
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
    
    # Relationships
    chain = relationship("Chain", back_populates="stores")
    item_prices = relationship("ItemPrice", back_populates="store")
    
    # Composite unique constraint for chain_id + store_id
    __table_args__ = (
        Index('idx_chain_store', 'chain_id', 'store_id'),
    )

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
        Index('idx_item_store', 'item_code', 'store_id'),
        Index('idx_price_update_date', 'price_update_date'),
        Index('idx_item_status', 'item_status'),
    )