from sqlalchemy.orm import Session
from sqlalchemy import func, desc, and_
from datetime import datetime, timedelta
from typing import List, Optional
import math
from collections import defaultdict

from ..models.models import ShoppingItem, ShoppingList, User, ItemPrice, Item, Store, Chain
from ..schemas.predictions import ItemPrediction, PredictionReason, PredictionsResponse

class PredictionService:
    def __init__(self, db: Session):
        self.db = db
    
    def get_predictions(
        self, 
        user: User, 
        shopping_list_id: Optional[int] = None,
        limit: int = 10
    ) -> PredictionsResponse:
        """Generate item predictions for a user"""
        predictions = []
        
        # Get all household IDs for the user
        household_ids = [h.id for h in user.households]
        
        # Get existing items in shopping list to avoid duplicates
        existing_items = set()
        if shopping_list_id:
            shopping_list = self.db.query(ShoppingList).filter(
                ShoppingList.id == shopping_list_id
            ).first()
            if shopping_list:
                existing_items = {item.name.lower() for item in shopping_list.items if not item.is_purchased}
        
        # 1. Frequently bought items by user
        frequent_items = self._get_frequently_bought_items(user.id, household_ids, existing_items)
        predictions.extend(frequent_items[:limit // 2])
        
        # 2. Household favorites
        household_favorites = self._get_household_favorites(household_ids, user.id, existing_items)
        predictions.extend(household_favorites[:limit // 3])
        
        # 3. Recently purchased that might need replenishment
        replenishment_items = self._get_replenishment_predictions(user.id, household_ids, existing_items)
        predictions.extend(replenishment_items[:limit // 4])
        
        # Sort by confidence score and limit
        predictions.sort(key=lambda x: x.confidence_score, reverse=True)
        predictions = predictions[:limit]
        
        # Add current price information
        for prediction in predictions:
            if prediction.item_code:
                price_info = self._get_best_price(prediction.item_code)
                if price_info:
                    prediction.current_price = price_info['price']
                    prediction.store_name = price_info['store_name']
                    prediction.chain_name = price_info['chain_name']
        
        return PredictionsResponse(
            shopping_list_id=shopping_list_id,
            predictions=predictions,
            generated_at=datetime.utcnow()
        )
    
    def _get_frequently_bought_items(
        self, 
        user_id: int, 
        household_ids: List[int], 
        existing_items: set
    ) -> List[ItemPrediction]:
        """Get frequently purchased items by the user"""
        # Query purchase history for the last 90 days
        since_date = datetime.utcnow() - timedelta(days=90)
        
        frequent_items = self.db.query(
            ShoppingItem.name,
            ShoppingItem.item_code,
            func.count(ShoppingItem.id).label('purchase_count'),
            func.avg(ShoppingItem.quantity).label('avg_quantity'),
            func.max(ShoppingItem.purchased_at).label('last_purchased')
        ).join(
            ShoppingList
        ).filter(
            and_(
                ShoppingList.household_id.in_(household_ids),
                ShoppingItem.purchased_by_id == user_id,
                ShoppingItem.purchased_at >= since_date,
                ShoppingItem.is_purchased == True
            )
        ).group_by(
            ShoppingItem.name,
            ShoppingItem.item_code
        ).having(
            func.count(ShoppingItem.id) >= 2  # Bought at least twice
        ).order_by(
            desc('purchase_count')
        ).limit(20).all()
        
        predictions = []
        for item in frequent_items:
            if item.name.lower() not in existing_items:
                # Calculate confidence based on purchase frequency
                confidence = min(0.9, 0.5 + (item.purchase_count * 0.1))
                
                predictions.append(ItemPrediction(
                    item_code=item.item_code,
                    item_name=item.name,
                    confidence_score=confidence,
                    reason=PredictionReason.FREQUENTLY_BOUGHT,
                    reason_detail=f"You've bought this {item.purchase_count} times in the last 90 days",
                    last_purchased=item.last_purchased,
                    purchase_count=item.purchase_count,
                    avg_quantity=float(item.avg_quantity),
                    suggested_quantity=math.ceil(item.avg_quantity)
                ))
        
        return predictions
    
    def _get_household_favorites(
        self, 
        household_ids: List[int], 
        user_id: int,
        existing_items: set
    ) -> List[ItemPrediction]:
        """Get items frequently bought by household members"""
        since_date = datetime.utcnow() - timedelta(days=60)
        
        household_items = self.db.query(
            ShoppingItem.name,
            ShoppingItem.item_code,
            func.count(ShoppingItem.id).label('purchase_count'),
            func.avg(ShoppingItem.quantity).label('avg_quantity'),
            func.count(func.distinct(ShoppingItem.purchased_by_id)).label('unique_buyers')
        ).join(
            ShoppingList
        ).filter(
            and_(
                ShoppingList.household_id.in_(household_ids),
                ShoppingItem.purchased_by_id != user_id,  # Not by current user
                ShoppingItem.purchased_at >= since_date,
                ShoppingItem.is_purchased == True
            )
        ).group_by(
            ShoppingItem.name,
            ShoppingItem.item_code
        ).having(
            func.count(func.distinct(ShoppingItem.purchased_by_id)) >= 2  # Multiple household members
        ).order_by(
            desc('purchase_count')
        ).limit(10).all()
        
        predictions = []
        for item in household_items:
            if item.name.lower() not in existing_items:
                # Higher confidence if more household members buy it
                confidence = min(0.85, 0.4 + (item.unique_buyers * 0.15))
                
                predictions.append(ItemPrediction(
                    item_code=item.item_code,
                    item_name=item.name,
                    confidence_score=confidence,
                    reason=PredictionReason.HOUSEHOLD_FAVORITE,
                    reason_detail=f"{item.unique_buyers} household members regularly buy this",
                    last_purchased=None,
                    purchase_count=item.purchase_count,
                    avg_quantity=float(item.avg_quantity),
                    suggested_quantity=math.ceil(item.avg_quantity)
                ))
        
        return predictions
    
    def _get_replenishment_predictions(
        self, 
        user_id: int, 
        household_ids: List[int],
        existing_items: set
    ) -> List[ItemPrediction]:
        """Predict items that might need replenishment based on purchase patterns"""
        # Get items with regular purchase patterns
        regular_items = self.db.query(
            ShoppingItem.name,
            ShoppingItem.item_code,
            func.count(ShoppingItem.id).label('purchase_count'),
            func.avg(ShoppingItem.quantity).label('avg_quantity'),
            func.max(ShoppingItem.purchased_at).label('last_purchased')
        ).join(
            ShoppingList
        ).filter(
            and_(
                ShoppingList.household_id.in_(household_ids),
                ShoppingItem.is_purchased == True,
                ShoppingItem.purchased_at >= datetime.utcnow() - timedelta(days=180)
            )
        ).group_by(
            ShoppingItem.name,
            ShoppingItem.item_code
        ).having(
            func.count(ShoppingItem.id) >= 3  # Bought at least 3 times
        ).all()
        
        predictions = []
        now = datetime.utcnow()
        
        for item in regular_items:
            if item.name.lower() not in existing_items and item.purchase_count > 2:
                # Calculate average days between purchases
                purchase_dates = self.db.query(
                    ShoppingItem.purchased_at
                ).join(
                    ShoppingList
                ).filter(
                    and_(
                        ShoppingList.household_id.in_(household_ids),
                        ShoppingItem.name == item.name,
                        ShoppingItem.is_purchased == True
                    )
                ).order_by(
                    ShoppingItem.purchased_at.desc()
                ).limit(5).all()
                
                if len(purchase_dates) >= 2:
                    # Calculate average interval
                    intervals = []
                    for i in range(len(purchase_dates) - 1):
                        interval = (purchase_dates[i][0] - purchase_dates[i+1][0]).days
                        if interval > 0:
                            intervals.append(interval)
                    
                    if intervals:
                        avg_interval = sum(intervals) / len(intervals)
                        days_since_last = (now - item.last_purchased).days
                        
                        # Predict if it's about time to buy again
                        if days_since_last >= avg_interval * 0.8:
                            confidence = min(0.8, 0.5 + (days_since_last / avg_interval) * 0.3)
                            
                            predictions.append(ItemPrediction(
                                item_code=item.item_code,
                                item_name=item.name,
                                confidence_score=confidence,
                                reason=PredictionReason.RECENTLY_PURCHASED,
                                reason_detail=f"Usually bought every {int(avg_interval)} days, last bought {days_since_last} days ago",
                                last_purchased=item.last_purchased,
                                purchase_count=item.purchase_count,
                                avg_quantity=float(item.avg_quantity),
                                suggested_quantity=math.ceil(item.avg_quantity)
                            ))
        
        return predictions
    
    def _get_best_price(self, item_code: str) -> Optional[dict]:
        """Get the best current price for an item"""
        best_price = self.db.query(
            ItemPrice.price,
            Store.name.label('store_name'),
            Chain.name.label('chain_name')
        ).join(
            Store, ItemPrice.store_id == Store.id
        ).join(
            Chain, Store.chain_id == Chain.chain_id
        ).filter(
            and_(
                ItemPrice.item_code == item_code,
                ItemPrice.item_status == 1
            )
        ).order_by(
            ItemPrice.price.asc()
        ).first()
        
        if best_price:
            return {
                'price': best_price.price,
                'store_name': best_price.store_name,
                'chain_name': best_price.chain_name
            }
        return None