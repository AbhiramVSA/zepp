from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import AnyUrl, Field


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file="./backend/.env", env_file_encoding="utf-8", extra="ignore")

    DATABASE_URL: AnyUrl = Field(..., description="Async Postgres URL, e.g. postgresql+asyncpg://...")
    SUPABASE_URL: str = Field(...)
    SUPABASE_KEY: str | None = Field(default=None)
    SUPABASE_JWT_SECRET: str = Field(...)
    JWT_AUDIENCE: str | None = Field(default=None)


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
