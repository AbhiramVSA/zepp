from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User


async def get_by_id(session: AsyncSession, user_id: str) -> User | None:
    result = await session.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()


async def create_if_not_exists(session: AsyncSession, user_id: str, email: str | None) -> User:
    user = await get_by_id(session, user_id)
    if user:
        return user
    user = User(id=user_id, email=email)
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user
