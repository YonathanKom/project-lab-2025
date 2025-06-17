from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .household import HouseholdSummary


class UserBase(BaseModel):
    username: str
    email: str


class UserCreate(UserBase):
    password: str


class UserUpdate(UserBase):
    password: Optional[str] = None


class UserInDBBase(UserBase):
    id: int

    class Config:
        from_attributes = True


class User(UserInDBBase):
    households: List["HouseholdSummary"] = []


class UserInDB(UserInDBBase):
    hashed_password: str


class UserSummary(BaseModel):
    id: int
    username: str
    email: str
    role: Optional[str] = None
    joined_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# Forward reference resolution will be done in __init__.py
