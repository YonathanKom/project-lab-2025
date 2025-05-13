from datetime import datetime, timedelta
from typing import Any, Dict, List

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.models import User, PurchaseHistory
from app.schemas.schemas import ItemPrediction

router = APIRouter()

@router.get("/", response_model=List[ItemPrediction])
def get_predicted_items(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Get predicted items for shopping based on purchase history
    """
    # In a real-world scenario, you would implement machine learning models
    # For this example, we'll use frequency-based prediction from purchase history
    
    # Get purchase history for the household
    purchase_history = db.query(PurchaseHistory).filter(
        PurchaseHistory.household_id == current_user.household_id
    ).order_by(PurchaseHistory.frequency.desc()).limit(10).all()
    
    # If no history, return some default predictions
    if not purchase_history:
        return [
            {"name": "Milk", "confidence": 0.95, "last_purchased": datetime.utcnow() - timedelta(days=6)},
            {"name": "Bread", "confidence": 0.88, "last_purchased": datetime.utcnow() - timedelta(days=4)},
            {"name": "Eggs", "confidence": 0.75, "last_purchased": datetime.utcnow() - timedelta(days=8)},
            {"name": "Apples", "confidence": 0.65, "last_purchased": datetime.utcnow() - timedelta(days=10)},
            {"name": "Coffee", "confidence": 0.60, "last_purchased": datetime.utcnow() - timedelta(days=12)}
        ]
    
    # Convert history to predictions
    predictions = []
    for item in purchase_history:
        # Simple algorithm: higher frequency means higher confidence
        confidence = min(item.frequency / 10, 0.95)  # Cap at 0.95
        predictions.append({
            "name": item.item_name,
            "confidence": confidence,
            "last_purchased": item.purchase_date
        })
    
    return predictions