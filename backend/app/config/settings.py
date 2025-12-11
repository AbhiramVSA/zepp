from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    DATABASE_URL: str = Field(default="Not Found")
    SUPABASE_URL: str = Field(default="Not Found")
    SUPABASE_KEY: str = Field(default="Not Found")
    SUPABASE_JWT_SECRET: str = Field(default="Not Found")
    JWT_AUDIENCE: str = Field(default="Not Found")
    GROQ_API_KEY: str = Field(default="Not Found")
    

settings = Settings()



