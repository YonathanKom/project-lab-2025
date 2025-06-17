from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class HistoryItem(BaseModel):
    id: int
    item_name: str
    item_code: Optional[str]
    quantity: int
    price: Optional[float]
    purchased_at: datetime
    purchased_by: str
    shopping_list_name: str
    shopping_list_id: int
    store_name: Optional[str]
    chain_name: Optional[str]

    class Config:
        from_attributes = True


class HistoryStats(BaseModel):
    total_items: int
    total_spent: float
    avg_price: float
