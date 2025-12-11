from collections.abc import AsyncGenerator
import ssl

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config.settings import settings

# Create SSL context for asyncpg (Supabase requires SSL)
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

# Build URL without query params; pass SSL via connect_args
_db_url = str(settings.DATABASE_URL).split("?")[0]

engine = create_async_engine(
    _db_url,
    echo=False,
    future=True,
    connect_args={"ssl": ssl_context},
)
SessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with SessionLocal() as session:
        yield session
