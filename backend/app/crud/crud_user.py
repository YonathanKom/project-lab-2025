from typing import Optional

from sqlalchemy.orm import Session

from app.core.security import get_password_hash
from app.models.models import User
from app.schemas.schemas import UserCreate

def get_user(db: Session, user_id: int) -> Optional[User]:
    return db.query(User).filter(User.id == user_id).first()

def get_user_by_email(db: Session, email: str) -> Optional[User]:
    return db.query(User).filter(User.email == email).first()

def get_user_by_username(db: Session, username: str) -> Optional[User]:
    return db.query(User).filter(User.username == username).first()

def create_user(db: Session, obj_in: UserCreate) -> User:
    db_user = User(
        username=obj_in.username,
        email=obj_in.email,
        hashed_password=get_password_hash(obj_in.password),
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user