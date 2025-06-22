from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional

from fastapi import HTTPException
from app.api import deps
from app.services.prediction_service import PredictionService
from app.schemas import PredictionsResponse
from app.models import ShoppingList

router = APIRouter()


@router.get("", response_model=PredictionsResponse)
def get_predictions(
    shopping_list_id: Optional[int] = Query(
        None, description="Shopping list to get predictions for"
    ),
    limit: int = Query(10, ge=1, le=20, description="Maximum number of predictions"),
    current_user=Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
):
    """Get item predictions for the current user"""
    # If shopping_list_id provided, verify access
    if shopping_list_id:
        shopping_list = (
            db.query(ShoppingList).filter(ShoppingList.id == shopping_list_id).first()
        )

        if not shopping_list:
            raise HTTPException(status_code=404, detail="Shopping list not found")

        if not any(h.id == shopping_list.household_id for h in current_user.households):
            raise HTTPException(status_code=403, detail="Access denied")

    prediction_service = PredictionService(db)
    return prediction_service.get_predictions(
        user=current_user, shopping_list_id=shopping_list_id, limit=limit
    )
