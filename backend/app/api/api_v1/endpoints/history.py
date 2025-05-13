import json
from typing import Any, Dict, List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.models import User, ShoppingList, ShoppingItem, ShoppingListHistory
from app.schemas.schemas import HistoryEntry, ShoppingItem as ShoppingItemSchema

router = APIRouter()

@router.get("/shopping-lists/{list_id}", response_model=List[HistoryEntry])
def get_shopping_list_history(
    list_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Get history of a shopping list
    """
    shopping_list = db.query(ShoppingList).filter(ShoppingList.id == list_id).first()
    if not shopping_list or shopping_list.household_id != current_user.household_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    history = db.query(ShoppingListHistory).filter(ShoppingListHistory.shopping_list_id == list_id).order_by(ShoppingListHistory.timestamp.desc()).all()
    
    result = []
    for entry in history:
        user = db.query(User).filter(User.id == entry.user_id).first()
        result.append({
            "id": entry.id,
            "action": entry.action,
            "data": json.loads(entry.item_data),
            "user": user.username if user else "Unknown",
            "timestamp": entry.timestamp
        })
    
    return result

@router.post("/shopping-lists/{list_id}/undo/{history_id}", response_model=ShoppingItemSchema)
def undo_action(
    list_id: int,
    history_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Undo a specific action based on history entry
    """
    shopping_list = db.query(ShoppingList).filter(ShoppingList.id == list_id).first()
    if not shopping_list or shopping_list.household_id != current_user.household_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    history_entry = db.query(ShoppingListHistory).filter(ShoppingListHistory.id == history_id).first()
    if not history_entry or history_entry.shopping_list_id != list_id:
        raise HTTPException(status_code=404, detail="History entry not found")
    
    data = json.loads(history_entry.item_data)
    
    if history_entry.action == "add":
        # Find the item that was added and delete it
        db_item = db.query(ShoppingItem).filter(
            ShoppingItem.shopping_list_id == list_id,
            ShoppingItem.name == data["name"]
        ).first()
        if db_item:
            db.delete(db_item)
            db.commit()
            return None
    
    elif history_entry.action == "update":
        # Find the item and restore to previous state
        db_item = db.query(ShoppingItem).filter(
            ShoppingItem.shopping_list_id == list_id,
            ShoppingItem.name == data["new"]["name"]
        ).first()
        if db_item:
            for key, value in data["old"].items():
                setattr(db_item, key, value)
            db.commit()
            db.refresh(db_item)
            return db_item
    
    elif history_entry.action == "delete":
        # Recreate the deleted item
        db_item = ShoppingItem(
            name=data["name"],
            quantity=data["quantity"],
            unit=data["unit"],
            is_purchased=data.get("is_purchased", False),
            shopping_list_id=list_id
        )
        db.add(db_item)
        db.commit()
        db.refresh(db_item)
        return db_item
    
    raise HTTPException(status_code=400, detail="Could not undo this action")