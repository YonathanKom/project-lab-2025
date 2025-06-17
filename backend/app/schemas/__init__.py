# Auth schemas
from .auth import Token, TokenPayload

# User schemas
from .user import (
    UserBase,
    UserCreate,
    UserUpdate,
    UserInDBBase,
    User,
    UserInDB,
    UserSummary,
)

# Household schemas
from .household import (
    HouseholdBase,
    HouseholdCreate,
    HouseholdUpdate,
    HouseholdSummary,
    HouseholdInDBBase,
    Household,
    UserHouseholdCreate,
    UserHouseholdUpdate,
    InvitationCreate,
    HouseholdInvitationBase,
    HouseholdInvitationInDBBase,
    HouseholdInvitation,
)

# Shopping schemas
from .shopping import (
    ShoppingItemBase,
    ShoppingItemCreate,
    ShoppingItemUpdate,
    ShoppingItemInDBBase,
    ShoppingItemInDB,
    ShoppingItem,
    ShoppingListBase,
    ShoppingListCreate,
    ShoppingListUpdate,
    ShoppingListInDBBase,
    ShoppingList,
)

# Catalog schemas
from .catalog import (
    ChainBase,
    ChainCreate,
    Chain,
    StoreBase,
    StoreCreate,
    Store,
    StoreWithChain,
    ItemBase,
    ItemCreate,
    Item,
    ItemPriceBase,
    ItemPriceCreate,
    ItemPrice,
    ItemWithPrice,
    ItemSearchParams,
    PriceComparisonResponse,
    ShoppingListPriceComparison,
    StoreComparison,
    ItemPriceBreakdown,
)

# History schemas
from .history import HistoryItem, HistoryStats

# Prediction schemas
from .predictions import (
    PredictionReason,
    ItemPrediction,
    PredictionsResponse,
)

# Common schemas
from .common import (
    ResponseMessage,
    ErrorResponse,
    PaginationParams,
    PaginatedResponse,
    BulkOperationResult,
)

# Resolve forward references
User.model_rebuild()
Household.model_rebuild()
HouseholdInvitation.model_rebuild()

# Make all schemas available when importing from schemas
__all__ = [
    # Auth
    "Token",
    "TokenPayload",
    # User
    "UserBase",
    "UserCreate",
    "UserUpdate",
    "UserInDBBase",
    "User",
    "UserInDB",
    "UserSummary",
    # Household
    "HouseholdBase",
    "HouseholdCreate",
    "HouseholdUpdate",
    "HouseholdSummary",
    "HouseholdInDBBase",
    "Household",
    "UserHouseholdCreate",
    "UserHouseholdUpdate",
    "InvitationCreate",
    "HouseholdInvitationBase",
    "HouseholdInvitationInDBBase",
    "HouseholdInvitation",
    # Shopping
    "ShoppingItemBase",
    "ShoppingItemCreate",
    "ShoppingItemUpdate",
    "ShoppingItemInDBBase",
    "ShoppingItemInDB",
    "ShoppingItem",
    "ShoppingListBase",
    "ShoppingListCreate",
    "ShoppingListUpdate",
    "ShoppingListInDBBase",
    "ShoppingList",
    # Catalog
    "ChainBase",
    "ChainCreate",
    "Chain",
    "StoreBase",
    "StoreCreate",
    "Store",
    "StoreWithChain",
    "ItemBase",
    "ItemCreate",
    "Item",
    "ItemPriceBase",
    "ItemPriceCreate",
    "ItemPrice",
    "ItemWithPrice",
    "ItemSearchParams",
    "PriceComparisonResponse",
    "ShoppingListPriceComparison",
    "StoreComparison",
    "ItemPriceBreakdown",
    # History
    "HistoryItem",
    "HistoryStats",
    # Predictions
    "PredictionReason",
    "ItemPrediction",
    "PredictionsResponse",
    # Common
    "ResponseMessage",
    "ErrorResponse",
    "PaginationParams",
    "PaginatedResponse",
    "BulkOperationResult",
]
