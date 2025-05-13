from typing import List, Optional, Dict, Any
from pydantic import BaseModel
from datetime import datetime

# User schemas
class UserBase(BaseModel):
    username: str
    email: str

class UserCreate(UserBase):
    password: str
    household_id: Optional[int] = None

class UserUpdate(UserBase):
    password: Optional[str] = None
    household_id: Optional[int] = None

class UserInDBBase(UserBase):
    id: int
    household_id: Optional[int] = None

    class Config:
        from_attributes = True

class User(UserInDBBase):
    pass

class UserInDB(UserInDBBase):
    hashed_password: str

# Household schemas
class HouseholdBase(BaseModel):
    name: str

class HouseholdCreate(HouseholdBase):
    pass

class HouseholdUpdate(HouseholdBase):
    pass

class HouseholdInDBBase(HouseholdBase):
    id: int

    class Config:
        from_attributes = True

class Household(HouseholdInDBBase):
    pass

# Shopping item schemas
class ShoppingItemBase(BaseModel):
    name: str
    quantity: float
    unit: str

class ShoppingItemCreate(ShoppingItemBase):
    pass

class ShoppingItemUpdate(ShoppingItemBase):
    is_purchased: Optional[bool] = None

class ShoppingItemInDBBase(ShoppingItemBase):
    id: int
    is_purchased: bool
    shopping_list_id: int

    class Config:
        from_attributes = True

class ShoppingItem(ShoppingItemInDBBase):
    pass

# Shopping list schemas
class ShoppingListBase(BaseModel):
    name: str
    household_id: int

class ShoppingListCreate(ShoppingListBase):
    pass

class ShoppingListUpdate(BaseModel):
    name: Optional[str] = None

class ShoppingListInDBBase(ShoppingListBase):
    id: int
    created_at: datetime
    owner_id: int

    class Config:
        from_attributes = True

class ShoppingList(ShoppingListInDBBase):
    items: List[ShoppingItem] = []

# History schemas
class HistoryEntry(BaseModel):
    id: int
    action: str
    data: Dict[str, Any]
    user: str
    timestamp: datetime

    class Config:
        from_attributes = True

# Price comparison schemas
class ItemPrice(BaseModel):
    store_name: str
    price: float
    last_updated: datetime

    class Config:
        from_attributes = True

# Prediction schemas
class ItemPrediction(BaseModel):
    name: str
    confidence: float
    last_purchased: datetime

    class Config:
        from_attributes = True

# Token schemas
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenPayload(BaseModel):
    sub: Optional[str] = None