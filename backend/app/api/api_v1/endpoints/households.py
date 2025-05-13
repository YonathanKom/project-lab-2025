from typing import Any, List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.models import User, Household
from app.schemas.schemas import Household as HouseholdSchema, HouseholdCreate, HouseholdUpdate

router = APIRouter()

@router.post("/", response_model=HouseholdSchema)
def create_household(
    household_in: HouseholdCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Create new household
    """
    db_household = Household(name=household_in.name)
    db.add(db_household)
    db.commit()
    db.refresh(db_household)
    
    # Update the current user's household
    current_user.household_id = db_household.id
    db.commit()
    
    return db_household

@router.get("/{household_id}", response_model=HouseholdSchema)
def get_household(
    household_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Get household by ID
    """
    household = db.query(Household).filter(Household.id == household_id).first()
    if not household:
        raise HTTPException(status_code=404, detail="Household not found")
    if current_user.household_id != household_id:
        raise HTTPException(status_code=403, detail="Not authorized to access this household")
    return household

@router.put("/{household_id}", response_model=HouseholdSchema)
def update_household(
    household_id: int,
    household_in: HouseholdUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Update household
    """
    household = db.query(Household).filter(Household.id == household_id).first()
    if not household:
        raise HTTPException(status_code=404, detail="Household not found")
    if current_user.household_id != household_id:
        raise HTTPException(status_code=403, detail="Not authorized to update this household")
    
    for key, value in household_in.dict(exclude_unset=True).items():
        setattr(household, key, value)
    
    db.commit()
    db.refresh(household)
    return household