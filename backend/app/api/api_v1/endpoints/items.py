import json
from typing import Any, List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.models import User, ShoppingList, ShoppingItem, ShoppingListHistory
from app.schemas.schemas import ShoppingItem as ShoppingItemSchema, ShoppingItemCreate, ShoppingItemUpdate

router = APIRouter()

@router.post("/{list_id}/items/", response_model=ShoppingItemSchema)
def add_shopping_item(
    list_id: int,
    item_in: ShoppingItemCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Add item to shopping list
    """
    shopping_list = db.query(ShoppingList).filter(ShoppingList.id == list_id).first()
    if not shopping_list:
        raise HTTPException(status_code=404, detail="Shopping list not found")
    if shopping_list.household_id != current_user.household_id:
        raise HTTPException(status_code=403, detail="Not authorized to modify this shopping list")
    
    db_item = ShoppingItem(
        name=item_in.name,
        quantity=item_in.quantity,
        unit=item_in.unit,
        shopping_list_id=list_id
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    
    # Record history
    history_entry = ShoppingListHistory(
        shopping_list_id=list_id,
        action="add",
        item_data=json.dumps({"name": item_in.name, "quantity": item_in.quantity, "unit": item_in.unit}),
        user_id=current_user.id
    )
    db.add(history_entry)
    db.commit()
    
    return db_item

@router.put("/{list_id}/items/{item_id}", response_model=ShoppingItemSchema)
def update_shopping_item(
    list_id: int,
    item_id: int,
    item_in: ShoppingItemUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Update shopping item
    """
    shopping_list = db.query(ShoppingList).filter(ShoppingList.id == list_id).first()
    if not shopping_list or shopping_list.household_id != current_user.household_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    db_item = db.query(ShoppingItem).filter(ShoppingItem.id == item_id, ShoppingItem.shopping_list_id == list_id).first()
    if not db_item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    # Store old data for history
    old_data = {"name": db_item.name, "quantity": db_item.quantity, "unit": db_item.unit, "is_purchased": db_item.is_purchased}
    
    # Update item
    for key, value in item_in.dict(exclude_unset=True).items():
        setattr(db_item, key, value)
    
    # Record history
    history_entry = ShoppingListHistory(
        shopping_list_id=list_id,
        action="update",
        item_data=json.dumps({
            "old": old_data, 
            "new": {k: v for k, v in item_in.dict(exclude_unset=True).items()}
        }),
        user_id=current_user.id
    )
    db.add(history_entry)
    
    db.commit()
    db.refresh(db_item)
    return db_item

@router.delete("/{list_id}/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_shopping_item(
    list_id: int,
    item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    """
    Delete shopping item
    """
    shopping_list = db.query(ShoppingList).filter(ShoppingList.id == list_id).first()
    if not shopping_list or shopping_list.household_id != current_user.household_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    db_item = db.query(ShoppingItem).filter(ShoppingItem.id == item_id, ShoppingItem.shopping_list_id == list_id).first()
    if not db_item:
        raise HTTPException(status_code=404, detail="Item not found")
    
    # Record history before deleting
    history_entry = ShoppingListHistory(
        shopping_list_id=list_id,
        action="delete",
        item_data=json.dumps({
            "name": db_item.name, 
            "quantity": db_item.quantity, 
            "unit": db_item.unit,
            "is_purchased": db_item.is_purchased
        }),
        user_id=current_user.id
    )
    db.add(history_entry)
    
    # Delete the item
    db.delete(db_item)
    db.commit()