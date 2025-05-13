from datetime import datetime
from typing import Any, List

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.models import User, ShoppingItem, Store, ItemPrice
from app.schemas.schemas import ItemPrice as ItemPriceSchema

router = APIRouter()

@router.get("/items/{item_name}", response_model=List[ItemPriceSchema])
def get_item_prices(
    item_name: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Get price comparison for a specific item
    """
    # In a real-world scenario, you would integrate with store APIs or web scraping
    # For this example, we'll use mock data from our database
    
    prices = []
    items = db.query(ShoppingItem).filter(ShoppingItem.name.ilike(f"%{item_name}%")).all()
    
    for item in items:
        price_data = db.query(ItemPrice).filter(ItemPrice.item_id == item.id).all()
        for price in price_data:
            store = db.query(Store).filter(Store.id == price.store_id).first()
            if store:
                prices.append({
                    "store_name": store.name,
                    "price": price.price,
                    "last_updated": price.last_updated
                })
    
    # If no prices found, return mock data
    if not prices:
        prices = [
            {"store_name": "Grocery Store A", "price": 2.99, "last_updated": datetime.utcnow()},
            {"store_name": "Supermarket B", "price": 3.49, "last_updated": datetime.utcnow()},
            {"store_name": "Local Market C", "price": 2.75, "last_updated": datetime.utcnow()}
        ]
    
    return prices