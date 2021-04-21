from sqlalchemy.orm import Session
from . import models, schemas, database
from typing import Optional
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from fastapi.security import OAuth2PasswordBearer
from fastapi import Depends, HTTPException, status
from os import getenv


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
ALGORITHM = "HS256"
SECRET_KEY = getenv("SECRET_KEY")

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


async def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()


async def get_user(db: Session, user_id: int) -> Optional[models.User]:
    return db.query(models.User).filter(models.User.id == user_id).one_or_none()


async def get_user_by_username(db: Session, username: str) -> Optional[models.User]:
    return db.query(models.User).filter(models.User.username == username).one_or_none()


async def get_schema_user(db: Session, username: str) -> Optional[schemas.User]:
    db_user = await get_user_by_username(db, username)
    if db_user is not None:
        schema_user = schemas.User(id=db_user.id, username=db_user.username, subjects=db_user.subjects)
        return schema_user
    else:
        return None


async def get_schema_db_user(db: Session, username: str) -> Optional[schemas.DBUser]:
    db_user = await get_user_by_username(db, username)
    if db_user is not None:
        schema_db_user = schemas.DBUser(username=username, hash_password=db_user.hash_password)
        return schema_db_user
    else:
        return None


async def create_user(db: Session, user: schemas.CreateUser) -> models.User:
    hashed_password = await get_password_hash(user.password)
    db_user = models.User(username=user.username, hash_password=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


async def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


async def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)


async def authenticate_user(username: str, password: str, db: Session) -> Optional[schemas.DBUser]:
    schema_user = await get_schema_db_user(db, username)

    if schema_user is None:
        return None

    if not verify_password(password, schema_user.hash_password):
        return None

    return schema_user


async def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


async def get_user_by_token(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) \
        -> Optional[schemas.User]:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])  # кинет JWTError если время токена истекло
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    db_user = await get_user_by_username(db, username)
    if db_user is None:
        raise credentials_exception

    schema_user = schemas.User(id=db_user.id, username=db_user.username, subjects=db_user.subjects)
    return schema_user
