from enum import Enum
from sqlalchemy.orm import Session
from . import models, schemas, database
from typing import Optional
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from fastapi import Depends, HTTPException, status
from os import getenv
from collections import defaultdict


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

    if not await verify_password(password, user.hash_password):
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


class Action(Enum):
    CREATE = 1
    CHANGE = 2
    DELETE = 3
    GET = 4


class Entity(Enum):
    USER = 1
    SUBJECT = 2
    CONTROL_POINT = 3
    CELL = 4


class Slave:
    def __init__(self, token: str, db: Session):
        self.db: Session = db
        self.user: models.User = self.get_user_by_token(token)

    def get_user_by_token(self, token: str) -> models.User:
        credentials_exception = HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])  # кинет JWTError если время токена истекло
            user_id = payload.get("user_id")
            if user_id is None:
                raise credentials_exception
        except JWTError:
            raise credentials_exception

        user = self.db.query(models.User).get(user_id)
        if user is None:
            raise credentials_exception

        return user

    def action(self, action: Action, entity: Entity, **kwargs):
        if action == Action.CREATE:
            if entity == Entity.SUBJECT:
                subject_info = kwargs.get("subject")
                self.__create_subject(subject_info)
            elif entity == Entity.CONTROL_POINT:
                control_point_info = kwargs.get("control_point")
                self.__create_control_point(control_point_info)
        elif action == Action.GET:
            if entity == Entity.CELL:
                return self.__get_cells()
            elif entity == Entity.CONTROL_POINT:
                return self.__get_control_points()
            elif entity == Entity.SUBJECT:
                return self.__get_subjects()
        elif action == Action.CHANGE:
            if entity == Entity.SUBJECT:
                old_subject = kwargs.get("old_subject")
                new_subject = kwargs.get("new_subject")
                return self.__change_subject(old_subject, new_subject)

    def __change_subject(self, old_subject: schemas.Subject, new_subject: schemas.Subject):
        # 1. Проверяем существует ли старый предмет в базе.
        subject = self.db.query(models.Subject).filter(
            models.Subject.short_name == old_subject.short_name,
            models.Subject.full_name == old_subject.full_name,
        ).first()

        # 2. Если его нет - кидаем ошибку
        if subject is None:
            raise ValueError(f"<{subject.full_name}> subject not in database")

        if subject not in self.user.subjects:
            raise ValueError(f"user <{user.username}> hasn't got <{subject.full_name}> subject")

        # 3. Проверяем существует ли новый предмет в базе
        new_subject_db = self.db.query(models.Subject).filter(
            models.Subject.short_name == new_subject.short_name,
            models.Subject.full_name == new_subject.full_name,
        ).first()

        # 4. Если его нет в базе создаём новый предмет
        if new_subject_db is None:
            new_subject_db = models.Subject(
                short_name=new_subject.short_name,
                full_name=new_subject.full_name,
            )
            self.db.add(new_subject_db)
            self.db.commit()
            self.db.refresh(new_subject_db)

        user_subject = self.db.query(models.UserSubject).filter(
            models.UserSubject.user_id == self.user.id,
            models.UserSubject.subject_id == subject.id,
        ).first()

        # 4. Меняем subject_id в user_subject
        user_subject.subject_id = new_subject_db.id
        self.db.commit()

    def __create_subject(self, subject_info):
        # 1. Узнаём существует ли такой предмет в таблице Subject.
        subject = self.db.query(models.Subject).filter(
            models.Subject.short_name == subject_info.short_name,
            models.Subject.full_name == subject_info.full_name,
        ).first()

        if subject is None:
            # 2. Если нет - создаём его
            subject = models.Subject(**subject_info.dict())
            self.db.add(subject)
            self.db.commit()
            self.db.refresh(subject)

        # 3. Проверяем, нет ли у нашего пользователя уже такого предмета.
        if subject in self.user.subjects:
            raise ValueError(f"user <{self.user.username}> already has <{subject.full_name}> subject")
        else:
            # 4. Если нет, то создаём запись в табличке user_subject.
            user_subject = models.UserSubject(
                user_id=self.user.id,
                subject_id=subject.id,
                row_number=len(self.user.subjects),
            )
            self.db.add(user_subject)
            self.db.commit()
            self.db.refresh(user_subject)

            # 4. И привязываем к каждой контрольной точке пользователя новый user_subject.
            control_points = self.__get_control_points()
            for column_number, control_point in control_points.items():
                new_user_subject_control_point = models.UserSubjectControlPoint(
                    user_subject_id=user_subject.id,
                    control_point_id=control_point["id"],
                    deadline=datetime.now()+timedelta(days=3),
                    column_number=column_number,
                )
                self.db.add(new_user_subject_control_point)
                self.db.commit()
                self.db.refresh(new_user_subject_control_point)

    def __create_control_point(self, control_point_info):
        # 1. Смотрим есть ли такая КТ в таблице control_points
        control_point = self.db.query(models.ControlPoint).filter(
            models.ControlPoint.full_name == control_point_info.full_name,
            models.ControlPoint.short_name == control_point_info.short_name,
        ).first()
        # 2. Если нет - создаём её
        if control_point is None:
            control_point = models.ControlPoint(
                full_name=control_point_info.full_name,
                short_name=control_point_info.short_name,
            )
            self.db.add(control_point)
            self.db.commit()
            self.db.refresh(control_point)
        # 3. Проверяем нет ли у нашего пользователя уже такой контрольной точки
        user_subjects = self.__get_user_subjects()
        if len(user_subjects):
            # 4. Если есть - кидаем ошибку
            if control_point in user_subjects[0].control_points:
                raise ValueError(f"user <{self.user.username}> already has <{control_point.full_name}> control point")

        # 5. Если нет - создаём в user_subject_control_point связь для каждой user subject пользователя
        for user_subject in user_subjects:
            new_user_subject_control_point = models.UserSubjectControlPoint(
                user_subject_id=user_subject.id,
                control_point_id=control_point.id,
                deadline=datetime.now()+timedelta(days=3),
                column_number=len(user_subject.control_points)
            )
            self.db.add(new_user_subject_control_point)
            self.db.commit()
            self.db.refresh(new_user_subject_control_point)

    def __get_cells(self):
        cells = defaultdict(dict)
        control_points = self.__get_user_subject_control_points()

        for cell in control_points:
            row_number = self.db.query(models.UserSubject).get(cell.user_subject_id).row_number
            cells[row_number][cell.column_number] = {
                "status": cell.complete,
                "description": cell.description,
                "deadline": cell.deadline,
            }

        return cells

    def __get_user_subjects(self):
        return self.db.query(models.UserSubject) \
            .join(models.Subject, models.UserSubject.subject_id == models.Subject.id) \
            .order_by(models.UserSubject.row_number) \
            .all()

    def __get_subjects(self):
        subjects = dict()
        user_subjects = self.__get_user_subjects()
        for user_subject in user_subjects:
            subject = self.db.query(models.Subject).get(user_subject.subject_id)
            subjects[user_subject.row_number] = {
                "id": subject.id,
                "full_name": subject.full_name,
                "short_name": subject.short_name,
            }
        return subjects

    def __get_control_points(self):
        control_points = dict()
        user_subject_control_points = self.__get_user_subject_control_points()
        for user_subject_control_point in user_subject_control_points:
            column_number = user_subject_control_point.column_number
            if column_number not in control_points:
                control_point = self.db.query(models.ControlPoint).get(user_subject_control_point.control_point_id)
                control_points[column_number] = {
                    "id": control_point.id,
                    "full_name": control_point.full_name,
                    "short_name": control_point.short_name,
                }
        return control_points

    def __get_user_subject_control_points(self):
        return self.db.query(models.UserSubjectControlPoint) \
            .join(models.UserSubject, models.UserSubjectControlPoint.user_subject_id == models.UserSubject.id) \
            .order_by(models.UserSubjectControlPoint.column_number) \
            .all()
