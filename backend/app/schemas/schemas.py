from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
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

class ChainBase(BaseModel):
    chain_id: str = Field(..., description="Government chain identifier")
    name: str
    sub_chain_id: Optional[str] = None

class ChainCreate(ChainBase):
    pass

class Chain(ChainBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class StoreBase(BaseModel):
    store_id: str = Field(..., description="Government store identifier")
    chain_id: str
    name: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    bikoret_no: Optional[str] = None

class StoreCreate(StoreBase):
    pass

class Store(StoreBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class StoreWithChain(Store):
    chain: Chain

class ItemBase(BaseModel):
    item_code: str = Field(..., description="Government item code")
    item_type: int
    name: str
    manufacturer_name: Optional[str] = None
    manufacture_country: Optional[str] = None
    manufacturer_description: Optional[str] = None
    unit_qty: Optional[str] = None
    quantity: Optional[float] = None
    unit_of_measure: Optional[str] = None
    is_weighted: bool = False
    qty_in_package: Optional[float] = None
    allow_discount: bool = True

class ItemCreate(ItemBase):
    pass

class Item(ItemBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class ItemPriceBase(BaseModel):
    item_code: str
    price: float
    unit_price: Optional[float] = None
    item_status: int = 1
    price_update_date: datetime

class ItemPriceCreate(ItemPriceBase):
    store_id: int

class ItemPrice(ItemPriceBase):
    id: int
    store_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class ItemWithPrice(Item):
    current_price: Optional[float] = None
    store_name: Optional[str] = None
    chain_name: Optional[str] = None
    price_update_date: Optional[datetime] = None

class ItemSearchParams(BaseModel):
    query: Optional[str] = None
    chain_id: Optional[str] = None
    store_id: Optional[str] = None
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    limit: int = Field(default=50, le=100)
    offset: int = Field(default=0, ge=0)

class PriceComparisonResponse(BaseModel):
    item: Item
    prices: List[ItemPrice]
    stores: List[Store]

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