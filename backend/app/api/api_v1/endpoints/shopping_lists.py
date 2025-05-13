from typing import Any, List

from fastapi import APIRouter, Depends, HTTPException, status
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
    if current_user.household_id != shopping_list_in.household_id:
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
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Get all shopping lists for current user's household
    """
    return db.query(ShoppingList).filter(ShoppingList.household_id == current_user.household_id).all()

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
    if shopping_list.household_id != current_user.household_id:
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
    if db_shopping_list.household_id != current_user.household_id:
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
    if db_shopping_list.household_id != current_user.household_id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this shopping list")
    
    db.delete(db_shopping_list)
    db.commit()