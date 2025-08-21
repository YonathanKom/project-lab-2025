from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime


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


class ShoppingListPriceComparison(BaseModel):
    shopping_list_id: int
    shopping_list_name: str
    total_items: int
    compared_items: int
    store_comparisons: List["StoreComparison"]

    class Config:
        from_attributes = True


class StoreComparison(BaseModel):
    store_id: int
    store_name: str
    chain_name: str
    city: Optional[str]
    total_price: float
    available_items: int
    missing_items: List[str]
    items_breakdown: List["ItemPriceBreakdown"]
    distance_km: Optional[float] = None


class ItemPriceBreakdown(BaseModel):
    item_name: str
    quantity: int
    unit_price: Optional[float]
    total_price: Optional[float]
    is_available: bool
