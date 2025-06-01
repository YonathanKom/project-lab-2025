from typing import List, Optional, Dict, Any
from pydantic import BaseModel
from datetime import datetime

# User schemas
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
    households: List['HouseholdSummary'] = []

class UserInDB(UserInDBBase):
    hashed_password: str

# Household schemas
class HouseholdBase(BaseModel):
    name: str

class HouseholdCreate(HouseholdBase):
    pass

class HouseholdUpdate(HouseholdBase):
    pass

class HouseholdSummary(HouseholdBase):
    id: int
    created_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class HouseholdInDBBase(HouseholdBase):
    id: int
    created_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class Household(HouseholdInDBBase):
    members: List['UserSummary'] = []

class UserSummary(BaseModel):
    id: int
    username: str
    email: str
    role: Optional[str] = None
    joined_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# UserHousehold relationship schema
class UserHouseholdCreate(BaseModel):
    household_id: int
    role: str = "member"

class UserHouseholdUpdate(BaseModel):
    role: Optional[str] = None

class InvitationCreate(BaseModel):
    email: str

class HouseholdInvitationBase(BaseModel):
    household_id: int
    invited_by_id: int
    invited_user_id: int
    status: str

class HouseholdInvitationInDBBase(HouseholdInvitationBase):
    id: int
    created_at: datetime
    responded_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class HouseholdInvitation(HouseholdInvitationInDBBase):
    household: HouseholdSummary
    invited_by: UserSummary
    invited_user: UserSummary

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

# Update forward references
User.model_rebuild()
Household.model_rebuild()