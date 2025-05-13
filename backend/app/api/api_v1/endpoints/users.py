from typing import Any, List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.core.security import get_password_hash
from app.crud.crud_user import create_user, get_user_by_username
from app.models.models import User
from app.schemas.schemas import User as UserSchema, UserCreate, UserUpdate

router = APIRouter()

@router.post("/", response_model=UserSchema)
def create_new_user(
    user_in: UserCreate, db: Session = Depends(get_db)
) -> Any:
    """
    Create new user
    """
    user = get_user_by_username(db, username=user_in.username)
    if user:
        raise HTTPException(
            status_code=400,
            detail="The user with this username already exists",
        )
    user = create_user(db, obj_in=user_in)
    return user

@router.get("/me", response_model=UserSchema)
def read_user_me(
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Get current user
    """
    return current_user

@router.put("/me", response_model=UserSchema)
def update_user_me(
    user_in: UserUpdate, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """
    Update own user
    """
    if user_in.password:
        user_in.hashed_password = get_password_hash(user_in.password)
    
    for key, value in user_in.dict(exclude={"password"}, exclude_unset=True).items():
        setattr(current_user, key, value)
    
    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    return current_user