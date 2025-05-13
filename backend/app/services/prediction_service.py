from datetime import datetime, timedelta
from typing import List, Dict, Any

from sqlalchemy.orm import Session

from app.models.models import PurchaseHistory

class PredictionService:
    """
    Service for predicting shopping items based on household purchase history
    """
    
    @staticmethod
    def predict_items(db: Session, household_id: int, limit: int = 10) -> List[Dict[str, Any]]:
        """
        Predict items that a household might need based on purchase history
        
        In a real implementation, this would use machine learning models.
        This simplified version uses frequency and recency.
        """
        # Get purchase history for the household
        history = db.query(PurchaseHistory).filter(
            PurchaseHistory.household_id == household_id
        ).order_by(PurchaseHistory.frequency.desc()).limit(limit * 2).all()
        
        if not history:
            # Return default predictions if no history available
            return [
                {"name": "Milk", "confidence": 0.95, "last_purchased": datetime.utcnow() - timedelta(days=6)},
                {"name": "Bread", "confidence": 0.88, "last_purchased": datetime.utcnow() - timedelta(days=4)},
                {"name": "Eggs", "confidence": 0.75, "last_purchased": datetime.utcnow() - timedelta(days=8)},
                {"name": "Apples", "confidence": 0.65, "last_purchased": datetime.utcnow() - timedelta(days=10)},
                {"name": "Coffee", "confidence": 0.60, "last_purchased": datetime.utcnow() - timedelta(days=12)}
            ][:limit]
        
        # Process history to generate predictions
        predictions = []
        for item in history:
            # Calculate days since last purchase
            days_since_purchase = (datetime.utcnow() - item.purchase_date).days
            
            # Simple formula: higher frequency and more recent purchases get higher confidence
            # This is simplified and would be more sophisticated in a real ML model
            recency_factor = max(0, 1 - (days_since_purchase / 30))  # Scale based on 30 days
            frequency_factor = min(item.frequency / 10, 1)  # Scale based on frequency
            
            confidence = (recency_factor * 0.7) + (frequency_factor * 0.3)  # Weight factors
            confidence = min(confidence, 0.95)  # Cap at 0.95
            
            predictions.append({
                "name": item.item_name,
                "confidence": round(confidence, 2),
                "last_purchased": item.purchase_date
            })
        
        # Sort by confidence and limit results
        predictions.sort(key=lambda x: x["confidence"], reverse=True)
        return predictions[:limit]