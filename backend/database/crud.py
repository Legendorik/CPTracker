from sqlalchemy.orm import Session
from . import models, schemas, database
from typing import Optional
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from fastapi import Depends, HTTPException, status
from os import getenv

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
ALGORITHM = "HS256"
SECRET_KEY = getenv("SECRET_KEY")


async def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()


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


async def authenticate_user(username: str, password: str, db: Session) -> Optional[models.User]:
    user = db.query(models.User).filter(models.User.username == username).one_or_none()

    if user is None:
        return None

    if not verify_password(password, user.hash_password):
        return None

    return user


async def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


async def get_control_points(db: Session, user: models.User):
    subjects = user.subjects
    if len(subjects):
        subject_id = subjects[0].id
        user_subject = db.query(models.UserSubject).filter(models.UserSubject.subject_id == subject_id).first()
        if user_subject is not None:
            return user_subject.control_points
    return None


async def get_user_subject_control_point(db: Session, user_subject_id: int, control_point_id: int):
    info = db.query(models.UserSubjectControlPoint).filter(
        models.UserSubjectControlPoint.control_point_id == control_point_id,
        models.UserSubjectControlPoint.user_subject_id == user_subject_id,
    ).first()
    return info


async def get_user_subjects(user_id: int, db: Session):
    return db.query(models.UserSubject).filter(models.UserSubject.user_id==user_id).all()


async def get_user_by_token(token: str, db: Session) -> models.User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])  # кинет JWTError если время токена истекло
        user_id: str = payload.get("user_id")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = db.query(models.User).get(user_id)
    if user is None:
        raise credentials_exception

    return user


async def get_or_create(subject: schemas.Subject, db: Session) -> models.Subject:
    new_subject = db.query(models.Subject).filter(
        models.Subject.full_name == subject.full_name,
        models.Subject.short_name == subject.short_name,
    ).first()
    if new_subject is not None:
        return new_subject
    else:
        new_subject = models.Subject(short_name=subject.short_name, full_name=subject.full_name)
        db.add(new_subject)
        db.commit()
        db.refresh(new_subject)
        return new_subject


async def add_subject_to_user(subject: models.Subject, user: models.User, db: Session) -> models.UserSubject:
    if subject in user.subjects:
        raise ValueError(f"user <{user.username}> already has <{subject.full_name}> subject")
    user.subjects.append(subject)
    db.add(user)
    db.commit()

    return db.query(models.UserSubject).filter(
        models.UserSubject.subject_id == subject.id,
        models.UserSubject.user_id == user.id,
    ).first()


async def add_control_points_to_user_subject(user: models.User, user_subject: models.UserSubject, db: Session):
    existing_control_points = await get_control_points(db, user)
    if existing_control_points is not None:
        for control_point in existing_control_points:
            db.add(models.UserSubjectControlPoint(
                user_subject_id=user_subject.id,
                control_point_id=control_point.id,
                deadline=datetime.now()+timedelta(days=5),
            ))
        db.commit()

