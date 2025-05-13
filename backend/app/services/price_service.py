from datetime import datetime
from typing import List, Dict, Any
import random

from sqlalchemy.orm import Session

from app.models.models import ItemPrice, Store, ShoppingItem

class PriceService:
    """
    Service for retrieving and comparing prices from different stores
    """
    
    @staticmethod
    def get_price_comparison(db: Session, item_name: str) -> List[Dict[str, Any]]:
        """
        Get price comparison for a specific item across different stores
        
        In a real implementation, this would integrate with store APIs or web scraping.
        """
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
            prices = PriceService._generate_mock_prices(item_name)
        
        # Sort by price (lowest first)
        prices.sort(key=lambda x: x["price"])
        return prices
    
    @staticmethod
    def _generate_mock_prices(item_name: str) -> List[Dict[str, Any]]:
        """
        Generate mock price data for demonstration purposes
        """
        store_names = ["Grocery Store A", "Supermarket B", "Local Market C", "Discount Store D", "Online Shop E"]
        base_price = round(random.uniform(1.5, 5.99), 2)
        
        mock_prices = []
        now = datetime.utcnow()
        
        for store in store_names:
            # Vary price by store, with some random fluctuation
            price_factor = random.uniform(0.8, 1.2)
            price = round(base_price * price_factor, 2)
            
            # Vary the last updated time
            days_ago = random.randint(0, 10)
            last_updated = now - timedelta(days=days_ago)
            
            mock_prices.append({
                "store_name": store,
                "price": price,
                "last_updated": last_updated
            })
        
        return mock_prices