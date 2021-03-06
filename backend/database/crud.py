from enum import Enum
from sqlalchemy.orm import Session
from . import models, schemas, database
from typing import Optional
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from fastapi import HTTPException, status
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


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)


def authenticate_user(username: str, password: str, db: Session) -> Optional[models.User]:
    user = db.query(models.User).filter(models.User.username == username).one_or_none()

    if user is None:
        return None

    if not verify_password(password, user.hash_password):
        return None

    return user


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
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
    def __init__(self, db: Session, token: Optional[str] = None):
        self.db: Session = db
        if token is not None:
            self.user: models.User = self.get_user_by_token(token)

    def get_user_by_token(self, token: str) -> models.User:
        credentials_exception = HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])  # ?????????? JWTError ???????? ?????????? ???????????? ??????????????
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

            elif entity == Entity.USER:
                new_user = kwargs.get("new_user")
                return self.__register_user(new_user)

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
                self.__change_subject(old_subject, new_subject)

            elif entity == Entity.CONTROL_POINT:
                old_control_point = kwargs.get("old_control_point")
                new_control_point = kwargs.get("new_control_point")
                self.__change_control_point(old_control_point, new_control_point)

            elif entity == Entity.CELL:
                subject = kwargs.get("subject")
                control_point = kwargs.get("control_point")
                new_cell = kwargs.get("new_cell")
                self.__change_cell(subject, control_point, new_cell)

        elif action == Action.DELETE:
            if entity == Entity.SUBJECT:
                subject = kwargs.get("subject")
                self.__delete_subject(subject)
                self.__reindex_subject()

            elif entity == Entity.CONTROL_POINT:
                control_point = kwargs.get("control_point")
                self.__delete_control_point(control_point)
                self.__reindex_control_points()

    def __register_user(self, user: schemas.CreateUser) -> str:
        db_user = self.db.query(models.User).filter(
            models.User.username == user.username,
        ).first()
        if db_user is not None:
            raise ValueError(f"user with {user.username} username already exists")
        db_user = models.User(
            username=user.username,
            hash_password=get_password_hash(user.password),
        )
        self.db.add(db_user)
        self.db.commit()
        self.db.refresh(db_user)

        data = {"user_id": db_user.id}
        return create_access_token(data)

    def __change_cell(self, subject: schemas.TableHeader, control_point: schemas.TableHeader,
                      new_cell: schemas.Cell) -> None:
        subject_db = self.db.query(models.Subject).filter(
            models.Subject.full_name == subject.full_name,
            models.Subject.short_name == subject.short_name,
        ).first()
        if subject_db is None:
            raise ValueError(f"<{subject.full_name}> subject not in db")

        if subject_db not in self.user.subjects:
            raise ValueError(f"user <{self.user.username}> hasn't got <{subject.full_name}> subject")

        user_subjects = self.__get_user_subjects()
        control_point_db = self.db.query(models.ControlPoint).filter(
            models.ControlPoint.short_name == control_point.short_name,
            models.ControlPoint.full_name == control_point.full_name,
        ).first()
        if control_point_db is None:
            raise ValueError(f"<{control_point.full_name}> control point not in db")
        if control_point_db not in user_subjects[0].control_points:
            raise ValueError(f"user <{self.user.username}> hasn't got <{control_point.full_name}> control point")

        user_subject = self.db.query(models.UserSubject).filter(
            models.UserSubject.subject_id == subject_db.id,
            models.UserSubject.user_id == self.user.id,
        ).first()

        cell = self.db.query(models.UserSubjectControlPoint).filter(
            models.UserSubjectControlPoint.user_subject_id == user_subject.id,
            models.UserSubjectControlPoint.control_point_id == control_point_db.id,
        ).first()

        cell.deadline = new_cell.deadline
        cell.complete = new_cell.complete
        cell.description = new_cell.description

        self.db.commit()

    def __reindex_subject(self) -> None:
        user_subjects = self.__get_user_subjects()
        for index, user_subject in enumerate(user_subjects):
            user_subject.row_number = index
        self.db.commit()

    def __reindex_control_points(self) -> None:
        control_points = self.__get_user_subject_control_points()
        user_subjects = self.__get_user_subjects()
        count = len(control_points) // len(user_subjects)

        for index, control_point in enumerate(control_points):
            control_point.column_number = index // count
        self.db.commit()

    def __delete_control_point(self, control_point: schemas.TableHeader) -> None:
        # 1. ??????????????????, ?????? ?????????????????????? ?????????? ???????? ?? ????????
        control_point_db = self.db.query(models.ControlPoint).filter(
            models.ControlPoint.short_name == control_point.short_name,
            models.ControlPoint.full_name == control_point.full_name,
        ).first()
        if control_point_db is None:
            raise ValueError(f"<{control_point.full_name}> control point not in database")

        # 2. ??????????????????, ?????? ?????????????????????? ?????????? ???????? ?? ????????????????????????
        user_subjects = self.__get_user_subjects()
        if not len(user_subjects):
            raise ValueError(f"can't delete control point for user who haven't got subjects")
        if control_point_db not in user_subjects[0].control_points:
            raise ValueError(f"user <{self.user.username}> hasn't got <{control_point.full_name}> control point")

        # 3. ???????????????????? ???? ???????? ?????????????? ?? ?????????????? ????, ?? ???????? id == control_point.id
        control_points = self.__get_user_subject_control_points()
        for control_point in control_points:
            if control_point.control_point_id == control_point_db.id:
                self.db.delete(control_point)
        self.db.commit()

    def __change_subject(self, old_subject: schemas.TableHeader, new_subject: schemas.TableHeader) -> None:
        # 1. ?????????????????? ???????????????????? ???? ???????????? ?????????????? ?? ????????.
        subject = self.db.query(models.Subject).filter(
            models.Subject.short_name == old_subject.short_name,
            models.Subject.full_name == old_subject.full_name,
        ).first()

        # 2. ???????? ?????? ?????? - ???????????? ????????????
        if subject is None:
            raise ValueError(f"<{old_subject.full_name}> subject not in database")

        if subject not in self.user.subjects:
            raise ValueError(f"user <{self.user.username}> hasn't got <{subject.full_name}> subject")

        # 3. ?????????????????? ???????????????????? ???? ?????????? ?????????????? ?? ????????
        new_subject_db = self.db.query(models.Subject).filter(
            models.Subject.short_name == new_subject.short_name,
            models.Subject.full_name == new_subject.full_name,
        ).first()

        # 4. ???????? ?????? ?????? ?? ???????? ?????????????? ?????????? ??????????????
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

        # 4. ???????????? subject_id ?? user_subject
        user_subject.subject_id = new_subject_db.id
        self.db.commit()

    def __delete_subject(self, subject: schemas.TableHeader) -> None:
        # 1. ?????????????????? ???????? ???? ?????????? ?????????????? ?? ????????
        db_subject = self.db.query(models.Subject).filter(
            models.Subject.short_name == subject.short_name,
            models.Subject.full_name == subject.full_name,
        ).first()
        if db_subject is None:
            raise ValueError(f"<{subject.full_name}> subject not in database")
        # 2. ?????????????????? ???????? ???? ?????????? ???????????????? ?? ????????????????????????
        if db_subject not in self.user.subjects:
            raise ValueError(f"user <{self.user.username}> hasn't got <{subject.full_name}> subject")
        # ?????? ???????????????????? ???? ?????????????? ??????????????, ?? ?????????????????? ?????????? ?????????? m2m ??????????????????
        # 3. ?????????????? ?????????? ???????????????????????? ?? ?????????????? ????????????????
        user_subject = self.db.query(models.UserSubject).filter(
            models.UserSubject.user_id == self.user.id,
            models.UserSubject.subject_id == db_subject.id,
        ).first()

        control_points = self.__get_user_subject_control_points()
        # 4. ?????????????????? ?????????? ?????????? user_subject ?? control_point
        for control_point in control_points:
            if control_point.user_subject_id == user_subject.id:
                self.db.delete(control_point)
        self.db.commit()

        # 5. ?????????????????? ?????????? ?????????? ?????????????????????????? ?? ??????????????????
        self.db.delete(user_subject)
        self.db.commit()

    def __change_control_point(self, old_control_point: schemas.TableHeader,
                               new_control_point: schemas.TableHeader) -> None:
        # 1. ?????????????????? ???????????????????? ???? ???????????? ?????????????? ?? ????????
        old_control_point_db = self.db.query(models.ControlPoint).filter(
            models.ControlPoint.short_name == old_control_point.short_name,
            models.ControlPoint.full_name == old_control_point.full_name,
        ).first()

        # 2. ???????? ?????? - ???????????? ????????????
        if old_control_point_db is None:
            raise ValueError(f"<{old_control_point.full_name}> control point not in database")

        user_subjects = self.__get_user_subjects()
        if len(user_subjects):
            # 3. ???????? ?? ???????????????????????? ?????? ?????????? ?????????????????????? ??????????, ?????????????? ???? ?????????? ????????????????
            if old_control_point_db not in user_subjects[0].control_points:
                raise ValueError(f"user <{self.user.username}> hasn't got <{old_control_point.full_name}> control point")

        # 4. ?????????????????? ???????????????????? ???? ?????????? ?????????????????????? ?????????? ?? ????????
        new_control_point_db = self.db.query(models.ControlPoint).filter(
            models.ControlPoint.short_name == new_control_point.short_name,
            models.ControlPoint.full_name == new_control_point.full_name,
        ).first()

        # 5. ???????? ???? ?????? - ??????????????
        if new_control_point_db is None:
            new_control_point_db = models.ControlPoint(
                short_name=new_control_point.short_name,
                full_name=new_control_point.full_name,
            )
            self.db.add(new_control_point_db)
            self.db.commit()
            self.db.refresh(new_control_point_db)

        control_points = self.__get_user_subject_control_points()
        # 6. ?????? ?????????????? ???????????????? ???????????? ?????????????????????? ?????????? ???????????? control_point_id
        for control_point in control_points:
            if control_point.control_point_id == old_control_point_db.id:
                control_point.control_point_id = new_control_point_db.id
        self.db.commit()

    def __create_subject(self, subject: schemas.TableHeader) -> None:
        # 1. ???????????? ???????????????????? ???? ?????????? ?????????????? ?? ?????????????? Subject.
        subject_id = self.db.query(models.Subject).filter(
            models.Subject.short_name == subject.short_name,
            models.Subject.full_name == subject.full_name,
        ).first()

        if subject_id is None:
            # 2. ???????? ?????? - ?????????????? ??????
            subject_id = models.Subject(**subject.dict())
            self.db.add(subject_id)
            self.db.commit()
            self.db.refresh(subject_id)

        # 3. ??????????????????, ?????? ???? ?? ???????????? ???????????????????????? ?????? ???????????? ????????????????.
        if subject_id in self.user.subjects:
            raise ValueError(f"user <{self.user.username}> already has <{subject_id.full_name}> subject")
        else:
            # 4. ???????? ??????, ???? ?????????????? ???????????? ?? ???????????????? user_subject.
            user_subject = models.UserSubject(
                user_id=self.user.id,
                subject_id=subject_id.id,
                row_number=len(self.user.subjects),
            )
            self.db.add(user_subject)
            self.db.commit()
            self.db.refresh(user_subject)

            # 4. ?? ?????????????????????? ?? ???????????? ?????????????????????? ?????????? ???????????????????????? ?????????? user_subject.
            control_points = self.__get_control_points()
            for column_number, control_point in control_points.items():
                new_user_subject_control_point = models.UserSubjectControlPoint(
                    user_subject_id=user_subject.id,
                    control_point_id=control_point["id"],
                    column_number=column_number,
                )
                self.db.add(new_user_subject_control_point)
                self.db.commit()
                self.db.refresh(new_user_subject_control_point)

    def __create_control_point(self, control_point: schemas.TableHeader) -> None:
        # 1. ?????????????? ???????? ???? ?????????? ???? ?? ?????????????? control_points
        control_point_db = self.db.query(models.ControlPoint).filter(
            models.ControlPoint.full_name == control_point.full_name,
            models.ControlPoint.short_name == control_point.short_name,
        ).first()

        # 2. ???????? ?????? - ?????????????? ????
        if control_point_db is None:
            control_point_db = models.ControlPoint(
                full_name=control_point.full_name,
                short_name=control_point.short_name,
            )
            self.db.add(control_point_db)
            self.db.commit()
            self.db.refresh(control_point_db)

        # 3. ?????????????????? ?????? ???? ?? ???????????? ???????????????????????? ?????? ?????????? ?????????????????????? ??????????
        user_subjects = self.__get_user_subjects()
        if len(user_subjects):
            # 4. ???????? ???????? - ???????????? ????????????
            if control_point_db in user_subjects[0].control_points:
                raise ValueError(f"user <{self.user.username}> already has <{control_point_db.full_name}> control point")

        # 5. ???????? ?????? - ?????????????? ?? user_subject_control_point ?????????? ?????? ???????????? user subject ????????????????????????
        for user_subject in user_subjects:
            new_user_subject_control_point = models.UserSubjectControlPoint(
                user_subject_id=user_subject.id,
                control_point_id=control_point_db.id,
                column_number=len(user_subject.control_points)
            )
            self.db.add(new_user_subject_control_point)
            self.db.commit()
            self.db.refresh(new_user_subject_control_point)

    def __get_cells(self) -> dict:
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

    def __get_user_subjects(self) -> list[models.UserSubject]:
        return self.db.query(models.UserSubject) \
            .join(models.Subject, models.UserSubject.subject_id == models.Subject.id) \
            .filter(models.UserSubject.user_id == self.user.id) \
            .order_by(models.UserSubject.row_number) \
            .all()

    def __get_subjects(self) -> dict:
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

    def __get_control_points(self) -> dict:
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

    def __get_user_subject_control_points(self) -> list[models.UserSubjectControlPoint]:
        return self.db.query(models.UserSubjectControlPoint) \
            .join(models.UserSubject, models.UserSubjectControlPoint.user_subject_id == models.UserSubject.id) \
            .filter(models.UserSubject.user_id == self.user.id) \
            .order_by(models.UserSubjectControlPoint.column_number) \
            .all()
