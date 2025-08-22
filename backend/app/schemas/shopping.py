from pydantic import BaseModel, validator
from typing import List, Optional
from datetime import datetime


class ShoppingItemBase(BaseModel):
    name: str
    description: Optional[str] = None
    quantity: float = 1
    item_code: Optional[str] = None
    price: Optional[float] = None

    @validator("name")
    def name_not_empty(cls, v):
        if not v or not v.strip():
            raise ValueError("Item name cannot be empty")
        return v.strip()

    @validator("quantity")
    def quantity_positive(cls, v):
        if v <= 0:
            raise ValueError("Quantity must be greater than 0")
        return v

    @validator("price")
    def price_non_negative(cls, v):
        if v is not None and v < 0:
            raise ValueError("Price cannot be negative")
        return v


class ShoppingItemCreate(ShoppingItemBase):
    pass


class ShoppingItemUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    quantity: Optional[float] = None
    is_purchased: Optional[bool] = None
    item_code: Optional[str] = None
    price: Optional[float] = None

    @validator("name")
    def name_not_empty(cls, v):
        if v is not None and (not v or not v.strip()):
            raise ValueError("Item name cannot be empty")
        return v.strip() if v else v

    @validator("quantity")
    def quantity_positive(cls, v):
        if v is not None and v <= 0:
            raise ValueError("Quantity must be greater than 0")
        return v

    @validator("price")
    def price_non_negative(cls, v):
        if v is not None and v < 0:
            raise ValueError("Price cannot be negative")
        return v


class ShoppingItemInDBBase(ShoppingItemBase):
    id: int
    shopping_list_id: int
    is_purchased: bool = False
    added_by_id: int
    purchased_by_id: Optional[int] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    purchased_at: Optional[datetime] = None
    added_by_username: Optional[str] = None
    purchased_by_username: Optional[str] = None

    class Config:
        from_attributes = True


class ShoppingItemInDB(ShoppingItemInDBBase):
    pass


class ShoppingItem(ShoppingItemInDBBase):
    pass


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
