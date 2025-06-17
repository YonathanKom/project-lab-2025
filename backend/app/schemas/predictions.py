from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum


class PredictionReason(str, Enum):
    FREQUENTLY_BOUGHT = "frequently_bought"
    HOUSEHOLD_FAVORITE = "household_favorite"
    RECENTLY_PURCHASED = "recently_purchased"
    SEASONAL = "seasonal"
    COMPLEMENTARY = "complementary"


class ItemPrediction(BaseModel):
    item_code: Optional[str]
    item_name: str
    confidence_score: float
    reason: PredictionReason
    reason_detail: str
    last_purchased: Optional[datetime]
    purchase_count: int
    avg_quantity: float
    suggested_quantity: int
    current_price: Optional[float]
    store_name: Optional[str]
    chain_name: Optional[str]

    class Config:
        from_attributes = True


class PredictionsResponse(BaseModel):
    shopping_list_id: Optional[int]
    predictions: List[ItemPrediction]
    generated_at: datetime
