from fastapi import APIRouter

from app.api.endpoints import (
    users,
    auth,
    households,
    shopping_lists,
    items,
    history,
    predictions,
    prices,
    data_import,
)

api_router = APIRouter()
api_router.include_router(auth.router, tags=["authentication"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(households.router, prefix="/households", tags=["households"])
api_router.include_router(
    shopping_lists.router, prefix="/shopping-lists", tags=["shopping lists"]
)
api_router.include_router(items.router, prefix="/items", tags=["items"])
api_router.include_router(history.router, prefix="/history", tags=["history"])
api_router.include_router(
    predictions.router, prefix="/predictions", tags=["predictions"]
)
api_router.include_router(prices.router, prefix="/prices", tags=["prices"])
api_router.include_router(
    data_import.router, prefix="/data-import", tags=["data import"]
)
