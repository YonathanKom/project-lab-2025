# Import all models to make them available through the package
from .user import User, user_households
from .household import Household, HouseholdInvitation
from .shopping import ShoppingList, ShoppingItem, ShoppingListHistory
from .catalog import Chain, Store, Item, ItemPrice
from .purchase import PurchaseHistory
from .association_rules import AssociationRule

# Make all models available when importing from models
__all__ = [
    "User",
    "user_households",
    "Household",
    "HouseholdInvitation",
    "ShoppingList",
    "ShoppingItem",
    "ShoppingListHistory",
    "Chain",
    "Store",
    "Item",
    "ItemPrice",
    "PurchaseHistory",
    "AssociationRule",
]
