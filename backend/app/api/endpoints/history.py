from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.api import deps
from app.models import User, ShoppingItem, ShoppingList, ItemPrice, Store, Chain
from app.schemas import HistoryItem

router = APIRouter()


@router.get("", response_model=List[HistoryItem])
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
    """Get purchase history for the user's households"""

    # Base query
    query = (
        db.query(
            ShoppingItem.id,
            ShoppingItem.name.label("item_name"),
            ShoppingItem.item_code,
            ShoppingItem.quantity,
            ShoppingItem.price,
            ShoppingItem.purchased_at,
            User.username.label("purchased_by"),
            ShoppingList.name.label("shopping_list_name"),
            ShoppingList.id.label("shopping_list_id"),
        )
        .join(ShoppingList, ShoppingItem.shopping_list_id == ShoppingList.id)
        .join(User, ShoppingItem.purchased_by_id == User.id)
        .filter(ShoppingItem.is_purchased, ShoppingItem.purchased_at.isnot(None))
    )

    # Filter by user's households
    user_household_ids = [h.id for h in current_user.households]
    if household_id and household_id in user_household_ids:
        query = query.filter(ShoppingList.household_id == household_id)
    else:
        query = query.filter(ShoppingList.household_id.in_(user_household_ids))

    # Date filters
    if start_date:
        query = query.filter(ShoppingItem.purchased_at >= start_date)
    if end_date:
        query = query.filter(ShoppingItem.purchased_at <= end_date)

    # Search filter
    if search:
        query = query.filter(
            or_(
                ShoppingItem.name.ilike(f"%{search}%"),
                ShoppingList.name.ilike(f"%{search}%"),
            )
        )

    # Order by purchase date descending
    query = query.order_by(ShoppingItem.purchased_at.desc())

    # Execute query
    items = query.offset(skip).limit(limit).all()

    # Convert to response model and add store info if available
    result = []
    for item in items:
        history_item = {
            "id": item.id,
            "item_name": item.item_name,
            "item_code": item.item_code,
            "quantity": item.quantity,
            "price": item.price,
            "purchased_at": item.purchased_at,
            "purchased_by": item.purchased_by,
            "shopping_list_name": item.shopping_list_name,
            "shopping_list_id": item.shopping_list_id,
            "store_name": None,
            "chain_name": None,
        }

        # Try to get store info from price data if item has code
        if item.item_code and item.price:
            price_info = (
                db.query(Store.name.label("store_name"), Chain.name.label("chain_name"))
                .join(ItemPrice, Store.id == ItemPrice.store_id)
                .join(Chain, Store.chain_id == Chain.chain_id)
                .filter(
                    ItemPrice.item_code == item.item_code, ItemPrice.price == item.price
                )
                .first()
            )

            if price_info:
                history_item["store_name"] = price_info.store_name
                history_item["chain_name"] = price_info.chain_name

        result.append(HistoryItem(**history_item))

    return result
