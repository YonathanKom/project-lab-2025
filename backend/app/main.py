from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.api.api import api_router
from app.core.config import settings
from app.services.background_tasks import background_tasks


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await background_tasks.start_periodic_tasks()
    yield
    # Shutdown
    await background_tasks.stop_periodic_tasks()


app = FastAPI(
    title="Household Shopping List API",
    description="API for managing household shopping lists with smart predictions and price comparisons",
    version="1.0.0",
    openapi_url=f"{settings.API_STR}/openapi.json",
    lifespan=lifespan,
)

app.include_router(api_router, prefix=settings.API_STR)

if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
