from typing import Optional, Any, List

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models import User, ShoppingList, ShoppingItem
from app.schemas import (
    ShoppingList as ShoppingListSchema,
    ShoppingListCreate,
    ShoppingListUpdate,
)
from app.models import ShoppingListHistory
import json

router = APIRouter()


@router.post("", response_model=ShoppingListSchema)
def create_shopping_list(
    shopping_list_in: ShoppingListCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Create new shopping list
    """
    if shopping_list_in.household_id not in [
        household.id for household in current_user.households
    ]:
        raise HTTPException(
            status_code=403, detail="Not authorized to create list for this household"
        )

    db_shopping_list = ShoppingList(
        name=shopping_list_in.name,
        owner_id=current_user.id,
        household_id=shopping_list_in.household_id,
    )
    db.add(db_shopping_list)
    db.commit()
    db.refresh(db_shopping_list)
    return db_shopping_list


@router.get("", response_model=List[ShoppingListSchema])
def get_shopping_lists(
    household_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Get shopping lists for specified household or all user's households
    """
    if household_id:
        # Verify user has access to this household
        if household_id not in [h.id for h in current_user.households]:
            raise HTTPException(
                status_code=403, detail="Access denied to this household"
            )
        return (
            db.query(ShoppingList)
            .filter(ShoppingList.household_id == household_id)
            .all()
        )
    else:
        return (
            db.query(ShoppingList)
            .filter(
                ShoppingList.household_id.in_([h.id for h in current_user.households])
            )
            .all()
        )


@router.get("/{list_id}", response_model=ShoppingListSchema)
def get_shopping_list(
    list_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get a single shopping list with items."""
    # Get the shopping list
    shopping_list = db.query(ShoppingList).filter(ShoppingList.id == list_id).first()

    if not shopping_list:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Shopping list not found"
        )

    # Check if user is member of the household
    if not any(h.id == shopping_list.household_id for h in current_user.households):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this list",
        )

    # Get items with username information
    items = (
        db.query(ShoppingItem)
        .filter(ShoppingItem.shopping_list_id == list_id)
        .order_by(ShoppingItem.is_purchased, ShoppingItem.created_at.desc())
        .all()
    )

    # Enhance items with username information
    enhanced_items = []
    for item in items:
        # Get usernames for added_by and purchased_by
        added_by_username = None
        purchased_by_username = None

        if item.added_by_id:
            added_by = db.query(User).filter(User.id == item.added_by_id).first()
            if added_by:
                added_by_username = added_by.username

        if item.purchased_by_id:
            purchased_by = (
                db.query(User).filter(User.id == item.purchased_by_id).first()
            )
            if purchased_by:
                purchased_by_username = purchased_by.username

        # Create enhanced item dict
        item_dict = {
            "id": item.id,
            "name": item.name,
            "description": item.description,
            "quantity": item.quantity,
            "is_purchased": item.is_purchased,
            "shopping_list_id": item.shopping_list_id,
            "added_by_id": item.added_by_id,
            "purchased_by_id": item.purchased_by_id,
            "created_at": item.created_at,
            "updated_at": item.updated_at,
            "purchased_at": item.purchased_at,
            "item_code": item.item_code,
            "price": item.price,
            "added_by_username": added_by_username,
            "purchased_by_username": purchased_by_username,
        }
        enhanced_items.append(item_dict)

    # Create response dict
    shopping_list_dict = {
        "id": shopping_list.id,
        "name": shopping_list.name,
        "household_id": shopping_list.household_id,
        "owner_id": shopping_list.owner_id,
        "created_at": shopping_list.created_at,
        "items": enhanced_items,
    }

    return ShoppingListSchema(**shopping_list_dict)


@router.put("/{list_id}", response_model=ShoppingListSchema)
def update_shopping_list(
    list_id: int,
    shopping_list_in: ShoppingListUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Update shopping list
    """
    db_shopping_list = db.query(ShoppingList).filter(ShoppingList.id == list_id).first()
    if not db_shopping_list:
        raise HTTPException(status_code=404, detail="Shopping list not found")
    if shopping_list_in.household_id not in [
        household.id for household in current_user.households
    ]:
        raise HTTPException(
            status_code=403, detail="Not authorized to modify this shopping list"
        )

    for key, value in shopping_list_in.dict(exclude_unset=True).items():
        setattr(db_shopping_list, key, value)

    db.commit()
    db.refresh(db_shopping_list)
    return db_shopping_list


@router.delete("/{list_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_shopping_list(
    list_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    """
    Delete shopping list
    """
    db_shopping_list = db.query(ShoppingList).filter(ShoppingList.id == list_id).first()
    if not db_shopping_list:
        raise HTTPException(status_code=404, detail="Shopping list not found")
    if db_shopping_list.household_id not in [
        household.id for household in current_user.households
    ]:
        raise HTTPException(
            status_code=403, detail="Not authorized to delete this shopping list"
        )

    db.delete(db_shopping_list)
    db.commit()


@router.post("/{list_id}/complete")
def complete_shopping_list(
    list_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict:
    """
    Complete shopping list and move to history
    """
    # Get the shopping list
    shopping_list = db.query(ShoppingList).filter(ShoppingList.id == list_id).first()

    if not shopping_list:
        raise HTTPException(status_code=404, detail="Shopping list not found")

    # Check if user is member of the household
    if not any(h.id == shopping_list.household_id for h in current_user.households):
        raise HTTPException(
            status_code=403, detail="Not authorized to complete this list"
        )

    # Get all items
    items = (
        db.query(ShoppingItem).filter(ShoppingItem.shopping_list_id == list_id).all()
    )

    if not items:
        raise HTTPException(
            status_code=400, detail="Cannot complete empty shopping list"
        )

    # Create items data for history
    items_data = []
    for item in items:
        items_data.append(
            {
                "name": item.name,
                "description": item.description,
                "quantity": item.quantity,
                "item_code": item.item_code,
                "price": item.price,
                "is_purchased": True,
            }
        )

    # Create history record
    history_record = ShoppingListHistory(
        shopping_list_id=shopping_list.id,
        shopping_list_name=shopping_list.name,
        household_id=shopping_list.household_id,
        items_data=json.dumps(items_data),
        completed_by_id=current_user.id,
    )

    # Remove all items from the shopping list (keep the list itself)
    for item in items:
        db.delete(item)

    # Save changes
    db.add(history_record)
    db.commit()

    return {
        "message": "Shopping list completed successfully",
        "items_moved_to_history": len(items),
    }
