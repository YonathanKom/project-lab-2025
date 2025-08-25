import secrets
from typing import List, Union
from pydantic import AnyHttpUrl, validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    API_STR: str = "/api"
    SECRET_KEY: str = secrets.token_urlsafe(32)
    # 60 minutes * 24 hours * 8 days = 8 days
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8

    BACKEND_CORS_ORIGINS: List[AnyHttpUrl] = []

    APRIORI_GENERATION_INTERVAL_HOURS: int = 24
    APRIORI_STARTUP_DELAY_MINUTES: int = 60 * 24
    APRIORI_ERROR_RETRY_MINUTES: int = 60

    @validator("BACKEND_CORS_ORIGINS", pre=True)
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> Union[List[str], str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)

    # Database configurations
    SQLALCHEMY_DATABASE_URL: str = (
        "postgresql://postgres:postgres@postgres:5432/shopping_list_db"
    )

    # JWT token generation algorithm
    ALGORITHM: str = "HS256"

    class Config:
        case_sensitive = True
        env_file = ".env"


settings = Settings()
