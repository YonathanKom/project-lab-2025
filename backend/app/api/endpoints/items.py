from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, aliased
from sqlalchemy import func

from app import models
from app import schemas
from app.api import deps
from app.api.deps import get_current_user

from app.models import User, ShoppingItem, ShoppingList

router = APIRouter()


@router.post("/{list_id}", response_model=schemas.ShoppingItemInDB)
def create_shopping_item(
    list_id: int,
    item_in: schemas.ShoppingItemCreate,
    db: Session = Depends(deps.get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Create new shopping item in a list."""
    # Check if user has access to the shopping list
    shopping_list = (
        db.query(models.ShoppingList).filter(models.ShoppingList.id == list_id).first()
    )

    if not shopping_list:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Shopping list not found"
        )

    # Check if user is member of the household
    if not any(h.id == shopping_list.household_id for h in current_user.households):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to add items to this list",
        )

    # Create the item
    db_item = models.ShoppingItem(
        **item_in.dict(), shopping_list_id=list_id, added_by_id=current_user.id
    )

    db.add(db_item)
    db.commit()
    db.refresh(db_item)

    return db_item


@router.get("/{list_id}", response_model=List[schemas.ShoppingItemInDB])
def get_shopping_items(
    list_id: int,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
):
    # Verify access to shopping list
    shopping_list = db.query(ShoppingList).filter(ShoppingList.id == list_id).first()
    if not shopping_list:
        raise HTTPException(status_code=404, detail="Shopping list not found")

    # Check household access
    if not any(h.id == shopping_list.household_id for h in current_user.households):
        raise HTTPException(status_code=403, detail="Access denied")

    # Create aliases for user joins
    added_by_user = aliased(User)
    purchased_by_user = aliased(User)

    # Query items with username joins
    items_query = (
        db.query(ShoppingItem)
        .outerjoin(added_by_user, ShoppingItem.added_by_id == added_by_user.id)
        .outerjoin(
            purchased_by_user, ShoppingItem.purchased_by_id == purchased_by_user.id
        )
        .filter(ShoppingItem.shopping_list_id == list_id)
        .offset(skip)
        .limit(limit)
        .all()
    )

    # Convert to response with usernames
    result = []
    for item in items_query:
        # Get usernames through relationships
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

        item_dict = {
            **{
                column.key: getattr(item, column.key)
                for column in item.__table__.columns
            },
            "added_by_username": added_by_username,
            "purchased_by_username": purchased_by_username,
        }
        result.append(schemas.ShoppingItemInDB(**item_dict))

    return result


@router.put("/{list_id}/{item_id}", response_model=schemas.ShoppingItemInDB)
def update_shopping_item(
    list_id: int,
    item_id: int,
    item_in: schemas.ShoppingItemUpdate,
    db: Session = Depends(deps.get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Update a shopping item."""
    # Get the item
    item = (
        db.query(models.ShoppingItem)
        .filter(
            models.ShoppingItem.id == item_id,
            models.ShoppingItem.shopping_list_id == list_id,
        )
        .first()
    )

    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Item not found"
        )

    # Check if user has access via household membership
    shopping_list = item.shopping_list
    if not any(h.id == shopping_list.household_id for h in current_user.households):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this item",
        )

    # Update the item
    update_data = item_in.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(item, field, value)

    db.commit()
    db.refresh(item)

    return item


@router.delete("/{list_id}/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_shopping_item(
    list_id: int,
    item_id: int,
    db: Session = Depends(deps.get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Delete a shopping item."""
    # Get the item
    item = (
        db.query(models.ShoppingItem)
        .filter(
            models.ShoppingItem.id == item_id,
            models.ShoppingItem.shopping_list_id == list_id,
        )
        .first()
    )

    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Item not found"
        )

    # Check if user has access via household membership
    shopping_list = item.shopping_list
    if not any(h.id == shopping_list.household_id for h in current_user.households):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete this item",
        )

    db.delete(item)
    db.commit()

    return None


@router.patch("/{list_id}/{item_id}/toggle", response_model=schemas.ShoppingItemInDB)
def toggle_item_purchased(
    list_id: int,
    item_id: int,
    toggle_data: dict,
    db: Session = Depends(deps.get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Toggle the purchased status of an item."""
    # Get the item
    item = (
        db.query(models.ShoppingItem)
        .filter(
            models.ShoppingItem.id == item_id,
            models.ShoppingItem.shopping_list_id == list_id,
        )
        .first()
    )

    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Item not found"
        )

    # Check if user has access via household membership
    shopping_list = item.shopping_list
    if not any(h.id == shopping_list.household_id for h in current_user.households):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this item",
        )

    # Toggle the status
    item.is_purchased = toggle_data.get("is_purchased", not item.is_purchased)

    if item.is_purchased:
        item.purchased_by_id = current_user.id
        item.purchased_at = func.current_timestamp()
    else:
        item.purchased_by_id = None
        item.purchased_at = None

    db.commit()
    db.refresh(item)

    return item


@router.post("/{list_id}/batch", response_model=List[schemas.ShoppingItemInDB])
def create_shopping_items_batch(
    list_id: int,
    items_in: List[schemas.ShoppingItemCreate],
    db: Session = Depends(deps.get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Create multiple shopping items at once."""
    # Check if user has access to the shopping list
    shopping_list = (
        db.query(models.ShoppingList).filter(models.ShoppingList.id == list_id).first()
    )

    if not shopping_list:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Shopping list not found"
        )

    # Check if user is member of the household
    if not any(h.id == shopping_list.household_id for h in current_user.households):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to add items to this list",
        )

    # Create all items
    db_items = []
    for item_in in items_in:
        db_item = models.ShoppingItem(
            **item_in.dict(), shopping_list_id=list_id, added_by_id=current_user.id
        )
        db.add(db_item)
        db_items.append(db_item)

    db.commit()

    # Refresh all items
    for item in db_items:
        db.refresh(item)

    return db_items
