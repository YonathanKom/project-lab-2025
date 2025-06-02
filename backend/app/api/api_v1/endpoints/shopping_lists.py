from typing import Optional, Any, List

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.models import User, ShoppingList
from app.schemas.schemas import ShoppingList as ShoppingListSchema, ShoppingListCreate, ShoppingListUpdate

router = APIRouter()

@router.post("/", response_model=ShoppingListSchema)
def create_shopping_list(
    shopping_list_in: ShoppingListCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Create new shopping list
    """
    if shopping_list_in.household_id not in [household.id for household in current_user.households]:
        raise HTTPException(status_code=403, detail="Not authorized to create list for this household")
    
    db_shopping_list = ShoppingList(
        name=shopping_list_in.name,
        owner_id=current_user.id,
        household_id=shopping_list_in.household_id
    )
    db.add(db_shopping_list)
    db.commit()
    db.refresh(db_shopping_list)
    return db_shopping_list

@router.get("/", response_model=List[ShoppingListSchema])
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
            raise HTTPException(status_code=403, detail="Access denied to this household")
        return db.query(ShoppingList).filter(ShoppingList.household_id == household_id).all()
    else:
        return db.query(ShoppingList).filter(ShoppingList.household_id.in_([h.id for h in current_user.households])).all()

@router.get("/{list_id}", response_model=ShoppingListSchema)
def get_shopping_list(
    list_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Get shopping list by ID
    """
    shopping_list = db.query(ShoppingList).filter(ShoppingList.id == list_id).first()
    if not shopping_list:
        raise HTTPException(status_code=404, detail="Shopping list not found")
    if shopping_list_in.household_id not in [household.id for household in current_user.households]:
        raise HTTPException(status_code=403, detail="Not authorized to access this shopping list")
    return shopping_list

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
    if shopping_list_in.household_id not in [household.id for household in current_user.households]:
        raise HTTPException(status_code=403, detail="Not authorized to modify this shopping list")
    
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
    if shopping_list_in.household_id not in [household.id for household in current_user.households]:
        raise HTTPException(status_code=403, detail="Not authorized to delete this shopping list")
    
    db.delete(db_shopping_list)
    db.commit()