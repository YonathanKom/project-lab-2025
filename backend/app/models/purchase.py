from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from datetime import datetime

from app.core.database import Base


class PurchaseHistory(Base):
    __tablename__ = "purchase_history"
    id = Column(Integer, primary_key=True, index=True)
    household_id = Column(Integer, ForeignKey("households.id"))
    item_name = Column(String, index=True)
    purchase_date = Column(DateTime, default=datetime.utcnow)
    frequency = Column(Integer, default=1)  # How often purchased
