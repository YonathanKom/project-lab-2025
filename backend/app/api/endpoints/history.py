from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
import json

from app.api import deps
from app.models import (
    User,
    ShoppingItem,
    ShoppingList,
    ShoppingListHistory,
)
from app.schemas import (
    ShoppingListHistory as ShoppingListHistorySchema,
    ShoppingListRestore,
)

router = APIRouter()


@router.get("", response_model=List[ShoppingListHistorySchema])
def get_purchase_history(
    *,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
    start_date: Optional[datetime] = Query(None),
    end_date: Optional[datetime] = Query(None),
    household_id: Optional[int] = Query(None),
    search: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, le=100),
):
    """Get shopping list history for the user's households"""

    # Base query
    query = db.query(ShoppingListHistory).join(
        User, ShoppingListHistory.completed_by_id == User.id
    )

    # Filter by user's households
    user_household_ids = [h.id for h in current_user.households]
    if household_id and household_id in user_household_ids:
        query = query.filter(ShoppingListHistory.household_id == household_id)
    else:
        query = query.filter(ShoppingListHistory.household_id.in_(user_household_ids))

    # Date filters
    if start_date:
        query = query.filter(ShoppingListHistory.completed_at >= start_date)
    if end_date:
        query = query.filter(ShoppingListHistory.completed_at <= end_date)

    # Search filter
    if search:
        query = query.filter(
            ShoppingListHistory.shopping_list_name.ilike(f"%{search}%")
        )

    # Order by completion date descending
    query = query.order_by(ShoppingListHistory.completed_at.desc())

    # Execute query
    history_records = query.offset(skip).limit(limit).all()

    # Convert to response model
    result = []
    for record in history_records:
        # Parse items data
        items_data = json.loads(record.items_data)

        # Get completed by username
        completed_by = db.query(User).filter(User.id == record.completed_by_id).first()
        completed_by_username = completed_by.username if completed_by else None

        history_item = ShoppingListHistorySchema(
            id=record.id,
            shopping_list_name=record.shopping_list_name,
            household_id=record.household_id,
            completed_at=record.completed_at,
            completed_by_id=record.completed_by_id,
            completed_by_username=completed_by_username,
            items=items_data,
        )

        result.append(history_item)

    return result


@router.post("/{history_id}/restore-item")
def restore_single_item(
    history_id: int,
    item_name: str = Query(..., description="Name of item to restore"),
    target_list_id: int = Query(..., description="Target shopping list ID"),
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
):
    """Restore a single item from history to a shopping list"""

    # Get history record
    history_record = (
        db.query(ShoppingListHistory)
        .filter(ShoppingListHistory.id == history_id)
        .first()
    )

    if not history_record:
        raise HTTPException(status_code=404, detail="History record not found")

    # Check if user has access to this household
    if history_record.household_id not in [h.id for h in current_user.households]:
        raise HTTPException(status_code=403, detail="Access denied")

    # Get target shopping list
    target_list = (
        db.query(ShoppingList).filter(ShoppingList.id == target_list_id).first()
    )

    if not target_list:
        raise HTTPException(status_code=404, detail="Target shopping list not found")

    if target_list.household_id not in [h.id for h in current_user.households]:
        raise HTTPException(status_code=403, detail="Access denied to target list")

    # Parse items and find the requested item
    items_data = json.loads(history_record.items_data)
    item_to_restore = None

    for item_data in items_data:
        if item_data["name"] == item_name:
            item_to_restore = item_data
            break

    if not item_to_restore:
        raise HTTPException(status_code=404, detail="Item not found in history")

    # Create new item
    new_item = ShoppingItem(
        shopping_list_id=target_list.id,
        name=item_to_restore["name"],
        description=item_to_restore.get("description"),
        quantity=item_to_restore["quantity"],
        item_code=item_to_restore.get("item_code"),
        price=item_to_restore.get("price"),
        is_purchased=False,  # Reset purchase status
        added_by_id=current_user.id,
    )

    db.add(new_item)
    db.commit()

    return {
        "message": f"Item '{item_name}' restored successfully",
        "target_list_id": target_list.id,
        "target_list_name": target_list.name,
    }


@router.post("/{history_id}/restore")
def restore_shopping_list(
    history_id: int,
    restore_data: ShoppingListRestore,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
):
    """Restore shopping list from history"""

    # Get history record
    history_record = (
        db.query(ShoppingListHistory)
        .filter(ShoppingListHistory.id == history_id)
        .first()
    )

    if not history_record:
        raise HTTPException(status_code=404, detail="History record not found")

    # Check if user has access to this household
    if history_record.household_id not in [h.id for h in current_user.households]:
        raise HTTPException(status_code=403, detail="Access denied")

    # Determine target shopping list
    if restore_data.target_list_id:
        # Add to existing list
        target_list = (
            db.query(ShoppingList)
            .filter(
                ShoppingList.id == restore_data.target_list_id,
                ShoppingList.completed_at is None,
            )
            .first()
        )

        if not target_list:
            raise HTTPException(
                status_code=404, detail="Target shopping list not found"
            )

        if target_list.household_id not in [h.id for h in current_user.households]:
            raise HTTPException(status_code=403, detail="Access denied to target list")

    else:
        # Create new list
        list_name = (
            restore_data.target_list_name
            or f"{history_record.shopping_list_name} (Restored)"
        )
        target_list = ShoppingList(
            name=list_name,
            owner_id=current_user.id,
            household_id=history_record.household_id,
        )
        db.add(target_list)
        db.flush()  # Get the ID

    # Parse and add items
    items_data = json.loads(history_record.items_data)
    added_items = []

    for item_data in items_data:
        new_item = ShoppingItem(
            shopping_list_id=target_list.id,
            name=item_data["name"],
            description=item_data.get("description"),
            quantity=item_data["quantity"],
            item_code=item_data.get("item_code"),
            price=item_data.get("price"),
            is_purchased=False,  # Reset purchase status
            added_by_id=current_user.id,
        )
        db.add(new_item)
        added_items.append(new_item)

    db.commit()

    return {
        "message": f"Successfully restored {len(added_items)} items",
        "target_list_id": target_list.id,
        "target_list_name": target_list.name,
        "items_added": len(added_items),
    }
